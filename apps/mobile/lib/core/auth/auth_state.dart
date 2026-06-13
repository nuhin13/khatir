import 'package:freezed_annotation/freezed_annotation.dart';

import '../enums/role.dart';

part 'auth_state.freezed.dart';

/// Resolution status of the app's authentication.
///
/// * [unknown] — before [bootstrap] completes; the router shows splash.
/// * [authenticated] — tokens valid, [AuthState.user] populated.
/// * [unauthenticated] — no/invalid session; the router redirects to phone.
enum AuthStatus { unknown, authenticated, unauthenticated }

/// The authenticated user. Mirrors `GET /api/v1/auth/me`
/// (`{id, phone, role, name, language}`); only fields the client reads.
@freezed
abstract class SessionUser with _$SessionUser {
  const factory SessionUser({
    required String id,
    String? phone,
    Role? role,
    String? name,
    String? language,
  }) = _SessionUser;

  /// Parses the `/auth/me` (or verify-otp `user`) payload. Defined as a static
  /// method (not a `fromJson` factory) so freezed does not require json codegen
  /// for the enum-typed [role] field.
  static SessionUser fromJson(Map<String, dynamic> json) => SessionUser(
        id: json['id']?.toString() ?? '',
        phone: json['phone'] as String?,
        role: Role.fromWire(json['role'] as String?),
        name: json['name'] as String?,
        language: json['language'] as String?,
      );
}

/// The single source of truth for auth across the app (consumed by the router
/// in T-012 and the role shells in EPIC-02).
@freezed
abstract class AuthState with _$AuthState {
  const AuthState._();

  const factory AuthState({
    @Default(AuthStatus.unknown) AuthStatus status,
    SessionUser? user,
  }) = _AuthState;

  static const AuthState unknown = AuthState();
  static const AuthState unauthenticated =
      AuthState(status: AuthStatus.unauthenticated);

  bool get isAuthenticated => status == AuthStatus.authenticated;

  /// The authenticated user's role, or `null` when unknown/unauthenticated.
  /// The router and role shells (EPIC-02) branch on this.
  Role? get role => user?.role;
}
