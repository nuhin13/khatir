import 'package:freezed_annotation/freezed_annotation.dart';

part 'request_otp_request.freezed.dart';
part 'request_otp_request.g.dart';

/// Request body for `POST /api/v1/auth/request-otp`.
///
/// [phone] is the E.164-normalised number (e.g. `+8801711000111`).
@freezed
abstract class RequestOtpRequest with _$RequestOtpRequest {
  const factory RequestOtpRequest({
    required String phone,
  }) = _RequestOtpRequest;

  factory RequestOtpRequest.fromJson(Map<String, dynamic> json) =>
      _$RequestOtpRequestFromJson(json);
}
