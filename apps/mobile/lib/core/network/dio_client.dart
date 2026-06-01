import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../config/app_config.dart';
import '../storage/secure_storage.dart';
import 'api_exception.dart';

/// Single, shared [Dio] instance exposed via Riverpod. Auth and error
/// interceptors are wired here as stubs — real attach/refresh lands in EPIC-01.
final dioClientProvider = Provider<Dio>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      contentType: Headers.jsonContentType,
    ),
  );

  dio.interceptors.add(
    _AuthInterceptor(secureStorage),
  );
  dio.interceptors.add(
    _ErrorInterceptor(),
  );

  return dio;
});

/// Attaches the bearer token when present. Refresh-on-401 is intentionally
/// left for EPIC-01; this stub only adds the header.
class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this._secureStorage);

  final SecureStorage _secureStorage;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _secureStorage.readAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
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
