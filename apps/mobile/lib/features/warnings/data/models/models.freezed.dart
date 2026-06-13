// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Warning {

 String get id; String get leaseId; String get tenantId; String get landlordId; WarningType get warningType; String get reason; DateTime? get issuedAt; String get noticeRef; DateTime? get acknowledgedAt;
/// Create a copy of Warning
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WarningCopyWith<Warning> get copyWith => _$WarningCopyWithImpl<Warning>(this as Warning, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Warning&&(identical(other.id, id) || other.id == id)&&(identical(other.leaseId, leaseId) || other.leaseId == leaseId)&&(identical(other.tenantId, tenantId) || other.tenantId == tenantId)&&(identical(other.landlordId, landlordId) || other.landlordId == landlordId)&&(identical(other.warningType, warningType) || other.warningType == warningType)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.issuedAt, issuedAt) || other.issuedAt == issuedAt)&&(identical(other.noticeRef, noticeRef) || other.noticeRef == noticeRef)&&(identical(other.acknowledgedAt, acknowledgedAt) || other.acknowledgedAt == acknowledgedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,leaseId,tenantId,landlordId,warningType,reason,issuedAt,noticeRef,acknowledgedAt);

@override
String toString() {
  return 'Warning(id: $id, leaseId: $leaseId, tenantId: $tenantId, landlordId: $landlordId, warningType: $warningType, reason: $reason, issuedAt: $issuedAt, noticeRef: $noticeRef, acknowledgedAt: $acknowledgedAt)';
}


}

/// @nodoc
abstract mixin class $WarningCopyWith<$Res>  {
  factory $WarningCopyWith(Warning value, $Res Function(Warning) _then) = _$WarningCopyWithImpl;
@useResult
$Res call({
 String id, String leaseId, String tenantId, String landlordId, WarningType warningType, String reason, DateTime? issuedAt, String noticeRef, DateTime? acknowledgedAt
});




}
/// @nodoc
class _$WarningCopyWithImpl<$Res>
    implements $WarningCopyWith<$Res> {
  _$WarningCopyWithImpl(this._self, this._then);

  final Warning _self;
  final $Res Function(Warning) _then;

/// Create a copy of Warning
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? leaseId = null,Object? tenantId = null,Object? landlordId = null,Object? warningType = null,Object? reason = null,Object? issuedAt = freezed,Object? noticeRef = null,Object? acknowledgedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,leaseId: null == leaseId ? _self.leaseId : leaseId // ignore: cast_nullable_to_non_nullable
as String,tenantId: null == tenantId ? _self.tenantId : tenantId // ignore: cast_nullable_to_non_nullable
as String,landlordId: null == landlordId ? _self.landlordId : landlordId // ignore: cast_nullable_to_non_nullable
as String,warningType: null == warningType ? _self.warningType : warningType // ignore: cast_nullable_to_non_nullable
as WarningType,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,issuedAt: freezed == issuedAt ? _self.issuedAt : issuedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,noticeRef: null == noticeRef ? _self.noticeRef : noticeRef // ignore: cast_nullable_to_non_nullable
as String,acknowledgedAt: freezed == acknowledgedAt ? _self.acknowledgedAt : acknowledgedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [Warning].
extension WarningPatterns on Warning {
@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Warning value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Warning() when $default != null:
return $default(_that);case _:
  return orElse();

}
}

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Warning value)  $default,){
final _that = this;
switch (_that) {
case _Warning():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Warning value)?  $default,){
final _that = this;
switch (_that) {
case _Warning() when $default != null:
return $default(_that);case _:
  return null;

}
}

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String leaseId,  String tenantId,  String landlordId,  WarningType warningType,  String reason,  DateTime? issuedAt,  String noticeRef,  DateTime? acknowledgedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Warning() when $default != null:
return $default(_that.id,_that.leaseId,_that.tenantId,_that.landlordId,_that.warningType,_that.reason,_that.issuedAt,_that.noticeRef,_that.acknowledgedAt);case _:
  return orElse();

}
}

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String leaseId,  String tenantId,  String landlordId,  WarningType warningType,  String reason,  DateTime? issuedAt,  String noticeRef,  DateTime? acknowledgedAt)  $default,) {final _that = this;
switch (_that) {
case _Warning():
return $default(_that.id,_that.leaseId,_that.tenantId,_that.landlordId,_that.warningType,_that.reason,_that.issuedAt,_that.noticeRef,_that.acknowledgedAt);case _:
  throw StateError('Unexpected subclass');

}
}

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String leaseId,  String tenantId,  String landlordId,  WarningType warningType,  String reason,  DateTime? issuedAt,  String noticeRef,  DateTime? acknowledgedAt)?  $default,) {final _that = this;
switch (_that) {
case _Warning() when $default != null:
return $default(_that.id,_that.leaseId,_that.tenantId,_that.landlordId,_that.warningType,_that.reason,_that.issuedAt,_that.noticeRef,_that.acknowledgedAt);case _:
  return null;

}
}

}

/// @nodoc


class _Warning implements Warning {
  const _Warning({required this.id, this.leaseId = '', this.tenantId = '', this.landlordId = '', this.warningType = WarningType.other, this.reason = '', this.issuedAt, this.noticeRef = '', this.acknowledgedAt});


@override final  String id;
@override@JsonKey() final  String leaseId;
@override@JsonKey() final  String tenantId;
@override@JsonKey() final  String landlordId;
@override@JsonKey() final  WarningType warningType;
@override@JsonKey() final  String reason;
@override final  DateTime? issuedAt;
@override@JsonKey() final  String noticeRef;
@override final  DateTime? acknowledgedAt;

/// Create a copy of Warning
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WarningCopyWith<_Warning> get copyWith => __$WarningCopyWithImpl<_Warning>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Warning&&(identical(other.id, id) || other.id == id)&&(identical(other.leaseId, leaseId) || other.leaseId == leaseId)&&(identical(other.tenantId, tenantId) || other.tenantId == tenantId)&&(identical(other.landlordId, landlordId) || other.landlordId == landlordId)&&(identical(other.warningType, warningType) || other.warningType == warningType)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.issuedAt, issuedAt) || other.issuedAt == issuedAt)&&(identical(other.noticeRef, noticeRef) || other.noticeRef == noticeRef)&&(identical(other.acknowledgedAt, acknowledgedAt) || other.acknowledgedAt == acknowledgedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,leaseId,tenantId,landlordId,warningType,reason,issuedAt,noticeRef,acknowledgedAt);

@override
String toString() {
  return 'Warning(id: $id, leaseId: $leaseId, tenantId: $tenantId, landlordId: $landlordId, warningType: $warningType, reason: $reason, issuedAt: $issuedAt, noticeRef: $noticeRef, acknowledgedAt: $acknowledgedAt)';
}


}

/// @nodoc
abstract mixin class _$WarningCopyWith<$Res> implements $WarningCopyWith<$Res> {
  factory _$WarningCopyWith(_Warning value, $Res Function(_Warning) _then) = __$WarningCopyWithImpl;
@override @useResult
$Res call({
 String id, String leaseId, String tenantId, String landlordId, WarningType warningType, String reason, DateTime? issuedAt, String noticeRef, DateTime? acknowledgedAt
});




}
/// @nodoc
class __$WarningCopyWithImpl<$Res>
    implements _$WarningCopyWith<$Res> {
  __$WarningCopyWithImpl(this._self, this._then);

  final _Warning _self;
  final $Res Function(_Warning) _then;

/// Create a copy of Warning
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? leaseId = null,Object? tenantId = null,Object? landlordId = null,Object? warningType = null,Object? reason = null,Object? issuedAt = freezed,Object? noticeRef = null,Object? acknowledgedAt = freezed,}) {
  return _then(_Warning(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,leaseId: null == leaseId ? _self.leaseId : leaseId // ignore: cast_nullable_to_non_nullable
as String,tenantId: null == tenantId ? _self.tenantId : tenantId // ignore: cast_nullable_to_non_nullable
as String,landlordId: null == landlordId ? _self.landlordId : landlordId // ignore: cast_nullable_to_non_nullable
as String,warningType: null == warningType ? _self.warningType : warningType // ignore: cast_nullable_to_non_nullable
as WarningType,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,issuedAt: freezed == issuedAt ? _self.issuedAt : issuedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,noticeRef: null == noticeRef ? _self.noticeRef : noticeRef // ignore: cast_nullable_to_non_nullable
as String,acknowledgedAt: freezed == acknowledgedAt ? _self.acknowledgedAt : acknowledgedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

/// @nodoc
mixin _$WarningNotice {

 String get warningId; String get noticeRef; String get signedUrl;
/// Create a copy of WarningNotice
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WarningNoticeCopyWith<WarningNotice> get copyWith => _$WarningNoticeCopyWithImpl<WarningNotice>(this as WarningNotice, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WarningNotice&&(identical(other.warningId, warningId) || other.warningId == warningId)&&(identical(other.noticeRef, noticeRef) || other.noticeRef == noticeRef)&&(identical(other.signedUrl, signedUrl) || other.signedUrl == signedUrl));
}


@override
int get hashCode => Object.hash(runtimeType,warningId,noticeRef,signedUrl);

@override
String toString() {
  return 'WarningNotice(warningId: $warningId, noticeRef: $noticeRef, signedUrl: $signedUrl)';
}


}

/// @nodoc
abstract mixin class $WarningNoticeCopyWith<$Res>  {
  factory $WarningNoticeCopyWith(WarningNotice value, $Res Function(WarningNotice) _then) = _$WarningNoticeCopyWithImpl;
@useResult
$Res call({
 String warningId, String noticeRef, String signedUrl
});




}
/// @nodoc
class _$WarningNoticeCopyWithImpl<$Res>
    implements $WarningNoticeCopyWith<$Res> {
  _$WarningNoticeCopyWithImpl(this._self, this._then);

  final WarningNotice _self;
  final $Res Function(WarningNotice) _then;

/// Create a copy of WarningNotice
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? warningId = null,Object? noticeRef = null,Object? signedUrl = null,}) {
  return _then(_self.copyWith(
warningId: null == warningId ? _self.warningId : warningId // ignore: cast_nullable_to_non_nullable
as String,noticeRef: null == noticeRef ? _self.noticeRef : noticeRef // ignore: cast_nullable_to_non_nullable
as String,signedUrl: null == signedUrl ? _self.signedUrl : signedUrl // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [WarningNotice].
extension WarningNoticePatterns on WarningNotice {
@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WarningNotice value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WarningNotice() when $default != null:
return $default(_that);case _:
  return orElse();

}
}

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WarningNotice value)  $default,){
final _that = this;
switch (_that) {
case _WarningNotice():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WarningNotice value)?  $default,){
final _that = this;
switch (_that) {
case _WarningNotice() when $default != null:
return $default(_that);case _:
  return null;

}
}

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String warningId,  String noticeRef,  String signedUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WarningNotice() when $default != null:
return $default(_that.warningId,_that.noticeRef,_that.signedUrl);case _:
  return orElse();

}
}

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String warningId,  String noticeRef,  String signedUrl)  $default,) {final _that = this;
switch (_that) {
case _WarningNotice():
return $default(_that.warningId,_that.noticeRef,_that.signedUrl);case _:
  throw StateError('Unexpected subclass');

}
}

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String warningId,  String noticeRef,  String signedUrl)?  $default,) {final _that = this;
switch (_that) {
case _WarningNotice() when $default != null:
return $default(_that.warningId,_that.noticeRef,_that.signedUrl);case _:
  return null;

}
}

}

/// @nodoc


class _WarningNotice implements WarningNotice {
  const _WarningNotice({required this.warningId, this.noticeRef = '', this.signedUrl = ''});


@override final  String warningId;
@override@JsonKey() final  String noticeRef;
@override@JsonKey() final  String signedUrl;

/// Create a copy of WarningNotice
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WarningNoticeCopyWith<_WarningNotice> get copyWith => __$WarningNoticeCopyWithImpl<_WarningNotice>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WarningNotice&&(identical(other.warningId, warningId) || other.warningId == warningId)&&(identical(other.noticeRef, noticeRef) || other.noticeRef == noticeRef)&&(identical(other.signedUrl, signedUrl) || other.signedUrl == signedUrl));
}


@override
int get hashCode => Object.hash(runtimeType,warningId,noticeRef,signedUrl);

@override
String toString() {
  return 'WarningNotice(warningId: $warningId, noticeRef: $noticeRef, signedUrl: $signedUrl)';
}


}

/// @nodoc
abstract mixin class _$WarningNoticeCopyWith<$Res> implements $WarningNoticeCopyWith<$Res> {
  factory _$WarningNoticeCopyWith(_WarningNotice value, $Res Function(_WarningNotice) _then) = __$WarningNoticeCopyWithImpl;
@override @useResult
$Res call({
 String warningId, String noticeRef, String signedUrl
});




}
/// @nodoc
class __$WarningNoticeCopyWithImpl<$Res>
    implements _$WarningNoticeCopyWith<$Res> {
  __$WarningNoticeCopyWithImpl(this._self, this._then);

  final _WarningNotice _self;
  final $Res Function(_WarningNotice) _then;

/// Create a copy of WarningNotice
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? warningId = null,Object? noticeRef = null,Object? signedUrl = null,}) {
  return _then(_WarningNotice(
warningId: null == warningId ? _self.warningId : warningId // ignore: cast_nullable_to_non_nullable
as String,noticeRef: null == noticeRef ? _self.noticeRef : noticeRef // ignore: cast_nullable_to_non_nullable
as String,signedUrl: null == signedUrl ? _self.signedUrl : signedUrl // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
