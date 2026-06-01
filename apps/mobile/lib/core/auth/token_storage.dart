import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../storage/secure_storage.dart';

/// A persisted access/refresh token pair.
class AuthTokens {
  const AuthTokens({required this.access, required this.refresh});

  final String access;
  final String refresh;
}

/// Auth-feature view over [SecureStorage]: read/write/clear the token pair.
///
/// Finalises the EPIC-00 secure-storage stub for T-011. Tokens live *only*
/// here (and inside the platform secure store); they are never logged or held
/// in plain Riverpod state. The auth controller is the single writer.
class TokenStorage {
  const TokenStorage(this._secureStorage);

  final SecureStorage _secureStorage;

  /// Reads the persisted pair, or `null` if either token is absent.
  Future<AuthTokens?> read() async {
    final access = await _secureStorage.readAccessToken();
    final refresh = await _secureStorage.readRefreshToken();
    if (access == null || access.isEmpty) return null;
    if (refresh == null || refresh.isEmpty) return null;
    return AuthTokens(access: access, refresh: refresh);
  }

  Future<String?> readAccessToken() => _secureStorage.readAccessToken();

  Future<String?> readRefreshToken() => _secureStorage.readRefreshToken();

  /// Persists [tokens] to secure storage.
  Future<void> write(AuthTokens tokens) => _secureStorage.writeTokens(
        accessToken: tokens.access,
        refreshToken: tokens.refresh,
      );

  /// Clears both tokens (logout / refresh failure).
  Future<void> clear() => _secureStorage.clear();
}

/// App-wide [TokenStorage], backed by the shared [SecureStorage].
final tokenStorageProvider = Provider<TokenStorage>(
  (ref) => TokenStorage(ref.watch(secureStorageProvider)),
);
