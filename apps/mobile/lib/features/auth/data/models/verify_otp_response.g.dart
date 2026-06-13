// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'verify_otp_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_VerifyOtpResponse _$VerifyOtpResponseFromJson(Map<String, dynamic> json) =>
    _VerifyOtpResponse(
      access: json['access'] as String,
      refresh: json['refresh'] as String,
      user: json['user'] == null
          ? null
          : AuthUser.fromJson(json['user'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$VerifyOtpResponseToJson(_VerifyOtpResponse instance) =>
    <String, dynamic>{
      'access': instance.access,
      'refresh': instance.refresh,
      'user': instance.user,
    };

_AuthUser _$AuthUserFromJson(Map<String, dynamic> json) =>
    _AuthUser(id: json['id'] as String?, phone: json['phone'] as String?);

Map<String, dynamic> _$AuthUserToJson(_AuthUser instance) => <String, dynamic>{
  'id': instance.id,
  'phone': instance.phone,
};
