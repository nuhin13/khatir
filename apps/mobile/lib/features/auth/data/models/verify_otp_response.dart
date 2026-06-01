import 'package:freezed_annotation/freezed_annotation.dart';

part 'verify_otp_response.freezed.dart';
part 'verify_otp_response.g.dart';

/// Response from `POST /api/v1/auth/verify-otp`.
///
/// Carries the issued token pair and the authenticated user. Token persistence
/// and the auth state layer are owned by T-011 — this task only models the
/// payload and hands it onward. Unknown keys are ignored.
@freezed
abstract class VerifyOtpResponse with _$VerifyOtpResponse {
  const factory VerifyOtpResponse({
    @JsonKey(name: 'access') required String access,
    @JsonKey(name: 'refresh') required String refresh,
    @JsonKey(name: 'user') AuthUser? user,
  }) = _VerifyOtpResponse;

  factory VerifyOtpResponse.fromJson(Map<String, dynamic> json) =>
      _$VerifyOtpResponseFromJson(json);
}

/// Minimal authenticated-user shape returned alongside the tokens. Only the
/// fields the client currently reads are modelled; T-011 owns the full session.
@freezed
abstract class AuthUser with _$AuthUser {
  const factory AuthUser({
    @JsonKey(name: 'id') String? id,
    @JsonKey(name: 'phone') String? phone,
  }) = _AuthUser;

  factory AuthUser.fromJson(Map<String, dynamic> json) =>
      _$AuthUserFromJson(json);
}
