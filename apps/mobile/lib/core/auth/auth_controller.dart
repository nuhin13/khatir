import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../enums/role.dart';
import '../network/api_endpoints.dart';
import '../network/api_exception.dart';
import '../network/dio_client.dart';
import 'auth_state.dart';
import 'token_storage.dart';

/// Owns the app's authentication state: persists tokens, exposes
/// [AuthStatus] (unknown/authenticated/unauthenticated) + the current user,
/// and is the single source of truth the router (T-012) and shells consume.
///
/// State is `AsyncValue<AuthState>` so the splash can show a spinner while
/// [build] resolves the persisted session.
class AuthController extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() => _bootstrap();

  TokenStorage get _tokens => ref.read(tokenStorageProvider);
  Dio get _dio => ref.read(dioClientProvider);

  /// Loads any persisted tokens and confirms them via `GET /auth/me`.
  ///
  /// No tokens → unauthenticated. Tokens that `/auth/me` rejects (after the
  /// refresh interceptor has had its single attempt) → cleared + unauthenticated.
  Future<AuthState> _bootstrap() async {
    final stored = await _tokens.read();
    if (stored == null) return AuthState.unauthenticated;

    try {
      final res = await _dio.get<Map<String, dynamic>>(ApiEndpoints.me);
      final data = res.data ?? const <String, dynamic>{};
      return AuthState(
        status: AuthStatus.authenticated,
        user: SessionUser.fromJson(data),
      );
    } on ApiException {
      await _tokens.clear();
      return AuthState.unauthenticated;
    } on DioException {
      await _tokens.clear();
      return AuthState.unauthenticated;
    }
  }

  /// Persists [access]/[refresh] and marks the session authenticated, seeding
  /// the user from the verify-otp payload (T-010). No `/auth/me` round-trip is
  /// made here — verify-otp already returns the user; `/auth/me` is reserved for
  /// [build]/bootstrap on app restart.
  Future<void> setSession({
    required String access,
    required String refresh,
    SessionUser? user,
  }) async {
    await _tokens.write(AuthTokens(access: access, refresh: refresh));
    state = AsyncValue.data(
      AuthState(status: AuthStatus.authenticated, user: user),
    );
  }

  /// Clears persisted tokens and sets the session unauthenticated. Best-effort
  /// calls `/auth/logout` to blacklist the refresh token.
  Future<void> logout() async {
    final refresh = await _tokens.readRefreshToken();
    if (refresh != null && refresh.isNotEmpty) {
      try {
        await _dio.post<void>(
          ApiEndpoints.logout,
          data: <String, dynamic>{'refresh': refresh},
        );
      } on DioException {
        // Best-effort: clearing local tokens is what ends the session.
      } on ApiException {
        // ignore
      }
    }
    await _tokens.clear();
    state = const AsyncValue.data(AuthState.unauthenticated);
  }

  /// Merges updated profile fields into the authenticated user's state so a
  /// profile change (name/role/language) propagates app-wide without a network
  /// round-trip. No-op unless the session is authenticated.
  ///
  /// Used by the profile controller (T-003) after a successful `PATCH /profile`
  /// for an optimistic local update; [refreshMe] then reconciles with the DB.
  void applyProfile({String? name, Role? role, String? language}) {
    final current = state.valueOrNull;
    if (current == null || !current.isAuthenticated) return;
    final user = current.user ?? const SessionUser(id: '');
    state = AsyncValue.data(
      current.copyWith(
        user: user.copyWith(
          name: name ?? user.name,
          role: role ?? user.role,
          language: language ?? user.language,
        ),
      ),
    );
  }

  /// Re-fetches `GET /auth/me` and refreshes the cached [SessionUser] so the
  /// role/language in auth state match the DB (the documented source of truth).
  /// Called after a role change so a stale token's role cannot win.
  ///
  /// On failure the existing state is left untouched (the caller already has a
  /// best-effort optimistic update via [applyProfile]).
  Future<void> refreshMe() async {
    final current = state.valueOrNull;
    if (current == null || !current.isAuthenticated) return;
    try {
      final res = await _dio.get<Map<String, dynamic>>(ApiEndpoints.me);
      final data = res.data ?? const <String, dynamic>{};
      state = AsyncValue.data(
        current.copyWith(user: SessionUser.fromJson(data)),
      );
    } on ApiException {
      // Keep the optimistic state; a later bootstrap will reconcile.
    } on DioException {
      // ignore
    }
  }

  /// Marks the session unauthenticated *without* a network round-trip. Called
  /// by the refresh interceptor after it has cleared tokens on a failed
  /// refresh (avoids re-entering the dio client during error handling).
  void markLoggedOut() {
    state = const AsyncValue.data(AuthState.unauthenticated);
  }
}

final authControllerProvider =
    AsyncNotifierProvider<AuthController, AuthState>(AuthController.new);
