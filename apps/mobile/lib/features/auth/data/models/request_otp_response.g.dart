// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'request_otp_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RequestOtpResponse _$RequestOtpResponseFromJson(Map<String, dynamic> json) =>
    _RequestOtpResponse(
      retryAfterSeconds: (json['retry_after_seconds'] as num?)?.toInt(),
    );

Map<String, dynamic> _$RequestOtpResponseToJson(_RequestOtpResponse instance) =>
    <String, dynamic>{'retry_after_seconds': instance.retryAfterSeconds};
