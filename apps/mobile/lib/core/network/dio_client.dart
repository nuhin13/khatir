import 'dart:async';

import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../auth/auth_controller.dart';
import '../auth/token_storage.dart';
import '../config/app_config.dart';
import '../observability/dio_sentry_interceptor.dart';
import 'api_endpoints.dart';
import 'api_exception.dart';

/// Single, shared [Dio] instance exposed via Riverpod.
///
/// Interceptor order: attach token → Sentry report → normalise errors. The
/// auth interceptor (T-011) attaches the bearer token and, on 401, transparently
/// refreshes via `/auth/refresh` once — queuing concurrent requests behind a
/// single in-flight refresh, retrying the original request on success, and
/// logging out on refresh failure.
final dioClientProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      contentType: Headers.jsonContentType,
    ),
  );

  dio.interceptors.add(AuthInterceptor(ref, dio));
  // Report non-2xx responses / transport errors to Sentry (PII-safe; no-op
  // without a DSN), then normalise the error for the rest of the app.
  dio.interceptors.add(const DioSentryInterceptor());
  dio.interceptors.add(_ErrorInterceptor());

  return dio;
});

/// Attaches `Authorization: Bearer <access>` and refreshes on 401.
///
/// Guarantees:
/// * A single in-flight refresh (mutex) — concurrent 401s await the same
///   refresh future rather than each firing their own.
/// * No refresh loops — the refresh request itself runs on a bare [Dio] with no
///   interceptors, and a request that was already retried is not refreshed again.
/// * On refresh failure: tokens cleared, auth state set to unauthenticated, and
///   the original error propagated.
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._ref, this._dio);

  final Ref _ref;
  final Dio _dio;

  /// Header marker on a request that has already been retried post-refresh, so
  /// a second 401 on the retry does not trigger another refresh.
  static const _retriedHeader = 'x-token-retried';

  /// The single in-flight refresh, or `null` when no refresh is running.
  Future<String?>? _refreshFuture;

  TokenStorage get _tokens => _ref.read(tokenStorageProvider);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // Never attach a token to the refresh call itself.
    if (options.path == ApiEndpoints.refresh) {
      handler.next(options);
      return;
    }
    final token = await _tokens.readAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final response = err.response;
    final isUnauthorized = response?.statusCode == 401;
    final alreadyRetried =
        err.requestOptions.headers.containsKey(_retriedHeader);
    final isRefreshCall = err.requestOptions.path == ApiEndpoints.refresh;

    if (!isUnauthorized || alreadyRetried || isRefreshCall) {
      handler.next(err);
      return;
    }

    final newAccess = await _refreshOnce();
    if (newAccess == null) {
      // Refresh failed → session is gone. Tokens already cleared in _refresh.
      _ref.read(authControllerProvider.notifier).markLoggedOut();
      handler.next(err);
      return;
    }

    // Retry the original request with the fresh token, marked so a second 401
    // does not loop back into refresh.
    final options = err.requestOptions
      ..headers['Authorization'] = 'Bearer $newAccess'
      ..headers[_retriedHeader] = 'true';
    try {
      final retried = await _dio.fetch<dynamic>(options);
      handler.resolve(retried);
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  /// Runs at most one refresh at a time. Concurrent callers share the same
  /// future. Returns the new access token, or `null` on failure (tokens cleared).
  Future<String?> _refreshOnce() {
    return _refreshFuture ??= _refresh().whenComplete(() {
      _refreshFuture = null;
    });
  }

  Future<String?> _refresh() async {
    final refreshToken = await _tokens.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      await _tokens.clear();
      return null;
    }

    try {
      // Reuse the shared client (so it shares the configured adapter), but the
      // refresh path is exempted in [onRequest] (no token attached) and
      // [onError] (no refresh-on-refresh), so this cannot recurse.
      final res = await _dio.post<Map<String, dynamic>>(
        ApiEndpoints.refresh,
        data: <String, dynamic>{'refresh': refreshToken},
      );
      final data = res.data ?? const <String, dynamic>{};
      final access = data['access'] as String?;
      if (access == null || access.isEmpty) {
        await _tokens.clear();
        return null;
      }
      // Rotation: the server hands back a new refresh token too. Persist both
      // (fall back to the existing refresh token if none was returned).
      final newRefresh = (data['refresh'] as String?) ?? refreshToken;
      await _tokens.write(AuthTokens(access: access, refresh: newRefresh));
      return access;
    } on DioException {
      await _tokens.clear();
      return null;
    }
  }
}

/// Normalises [DioException]s into [ApiException]s for the rest of the app.
class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        error: ApiException.fromDio(err),
        response: err.response,
        type: err.type,
      ),
    );
  }
}
