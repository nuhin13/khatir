import 'package:freezed_annotation/freezed_annotation.dart';

part 'request_otp_response.freezed.dart';
part 'request_otp_response.g.dart';

/// Response from `POST /api/v1/auth/request-otp`.
///
/// Only the fields the client needs are modelled; unknown keys are ignored.
/// [retryAfterSeconds] is surfaced when the backend signals a cooldown.
@freezed
abstract class RequestOtpResponse with _$RequestOtpResponse {
  const factory RequestOtpResponse({
    @JsonKey(name: 'retry_after_seconds') int? retryAfterSeconds,
  }) = _RequestOtpResponse;

  factory RequestOtpResponse.fromJson(Map<String, dynamic> json) =>
      _$RequestOtpResponseFromJson(json);
}
