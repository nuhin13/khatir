import 'package:freezed_annotation/freezed_annotation.dart';

part 'verify_otp_request.freezed.dart';
part 'verify_otp_request.g.dart';

/// Request body for `POST /api/v1/auth/verify-otp`.
///
/// [phone] is the E.164-normalised number (e.g. `+8801711000111`); [code] is
/// the OTP the user typed.
@freezed
abstract class VerifyOtpRequest with _$VerifyOtpRequest {
  const factory VerifyOtpRequest({
    required String phone,
    required String code,
  }) = _VerifyOtpRequest;

  factory VerifyOtpRequest.fromJson(Map<String, dynamic> json) =>
      _$VerifyOtpRequestFromJson(json);
}
