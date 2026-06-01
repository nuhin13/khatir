// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'verify_otp_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_VerifyOtpRequest _$VerifyOtpRequestFromJson(Map<String, dynamic> json) =>
    _VerifyOtpRequest(
      phone: json['phone'] as String,
      code: json['code'] as String,
    );

Map<String, dynamic> _$VerifyOtpRequestToJson(_VerifyOtpRequest instance) =>
    <String, dynamic>{'phone': instance.phone, 'code': instance.code};
