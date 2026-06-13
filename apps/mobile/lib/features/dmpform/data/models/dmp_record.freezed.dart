// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'dmp_record.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DmpRecord {

 String get id; String get tenantId; String get templateVersion; String get pdfRef; String get generatedBy; DateTime? get generatedAt; DateTime? get createdAt; String get signedUrl;
/// Create a copy of DmpRecord
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DmpRecordCopyWith<DmpRecord> get copyWith => _$DmpRecordCopyWithImpl<DmpRecord>(this as DmpRecord, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DmpRecord&&(identical(other.id, id) || other.id == id)&&(identical(other.tenantId, tenantId) || other.tenantId == tenantId)&&(identical(other.templateVersion, templateVersion) || other.templateVersion == templateVersion)&&(identical(other.pdfRef, pdfRef) || other.pdfRef == pdfRef)&&(identical(other.generatedBy, generatedBy) || other.generatedBy == generatedBy)&&(identical(other.generatedAt, generatedAt) || other.generatedAt == generatedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.signedUrl, signedUrl) || other.signedUrl == signedUrl));
}


@override
int get hashCode => Object.hash(runtimeType,id,tenantId,templateVersion,pdfRef,generatedBy,generatedAt,createdAt,signedUrl);

@override
String toString() {
  return 'DmpRecord(id: $id, tenantId: $tenantId, templateVersion: $templateVersion, pdfRef: $pdfRef, generatedBy: $generatedBy, generatedAt: $generatedAt, createdAt: $createdAt, signedUrl: $signedUrl)';
}


}

/// @nodoc
abstract mixin class $DmpRecordCopyWith<$Res>  {
  factory $DmpRecordCopyWith(DmpRecord value, $Res Function(DmpRecord) _then) = _$DmpRecordCopyWithImpl;
@useResult
$Res call({
 String id, String tenantId, String templateVersion, String pdfRef, String generatedBy, DateTime? generatedAt, DateTime? createdAt, String signedUrl
});




}
/// @nodoc
class _$DmpRecordCopyWithImpl<$Res>
    implements $DmpRecordCopyWith<$Res> {
  _$DmpRecordCopyWithImpl(this._self, this._then);

  final DmpRecord _self;
  final $Res Function(DmpRecord) _then;

/// Create a copy of DmpRecord
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? tenantId = null,Object? templateVersion = null,Object? pdfRef = null,Object? generatedBy = null,Object? generatedAt = freezed,Object? createdAt = freezed,Object? signedUrl = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,tenantId: null == tenantId ? _self.tenantId : tenantId // ignore: cast_nullable_to_non_nullable
as String,templateVersion: null == templateVersion ? _self.templateVersion : templateVersion // ignore: cast_nullable_to_non_nullable
as String,pdfRef: null == pdfRef ? _self.pdfRef : pdfRef // ignore: cast_nullable_to_non_nullable
as String,generatedBy: null == generatedBy ? _self.generatedBy : generatedBy // ignore: cast_nullable_to_non_nullable
as String,generatedAt: freezed == generatedAt ? _self.generatedAt : generatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,signedUrl: null == signedUrl ? _self.signedUrl : signedUrl // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [DmpRecord].
extension DmpRecordPatterns on DmpRecord {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DmpRecord value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DmpRecord() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DmpRecord value)  $default,){
final _that = this;
switch (_that) {
case _DmpRecord():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DmpRecord value)?  $default,){
final _that = this;
switch (_that) {
case _DmpRecord() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String tenantId,  String templateVersion,  String pdfRef,  String generatedBy,  DateTime? generatedAt,  DateTime? createdAt,  String signedUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DmpRecord() when $default != null:
return $default(_that.id,_that.tenantId,_that.templateVersion,_that.pdfRef,_that.generatedBy,_that.generatedAt,_that.createdAt,_that.signedUrl);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String tenantId,  String templateVersion,  String pdfRef,  String generatedBy,  DateTime? generatedAt,  DateTime? createdAt,  String signedUrl)  $default,) {final _that = this;
switch (_that) {
case _DmpRecord():
return $default(_that.id,_that.tenantId,_that.templateVersion,_that.pdfRef,_that.generatedBy,_that.generatedAt,_that.createdAt,_that.signedUrl);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String tenantId,  String templateVersion,  String pdfRef,  String generatedBy,  DateTime? generatedAt,  DateTime? createdAt,  String signedUrl)?  $default,) {final _that = this;
switch (_that) {
case _DmpRecord() when $default != null:
return $default(_that.id,_that.tenantId,_that.templateVersion,_that.pdfRef,_that.generatedBy,_that.generatedAt,_that.createdAt,_that.signedUrl);case _:
  return null;

}
}

}

/// @nodoc


class _DmpRecord implements DmpRecord {
  const _DmpRecord({this.id = '', this.tenantId = '', this.templateVersion = '', this.pdfRef = '', this.generatedBy = '', this.generatedAt, this.createdAt, this.signedUrl = ''});
  

@override@JsonKey() final  String id;
@override@JsonKey() final  String tenantId;
@override@JsonKey() final  String templateVersion;
@override@JsonKey() final  String pdfRef;
@override@JsonKey() final  String generatedBy;
@override final  DateTime? generatedAt;
@override final  DateTime? createdAt;
@override@JsonKey() final  String signedUrl;

/// Create a copy of DmpRecord
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DmpRecordCopyWith<_DmpRecord> get copyWith => __$DmpRecordCopyWithImpl<_DmpRecord>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DmpRecord&&(identical(other.id, id) || other.id == id)&&(identical(other.tenantId, tenantId) || other.tenantId == tenantId)&&(identical(other.templateVersion, templateVersion) || other.templateVersion == templateVersion)&&(identical(other.pdfRef, pdfRef) || other.pdfRef == pdfRef)&&(identical(other.generatedBy, generatedBy) || other.generatedBy == generatedBy)&&(identical(other.generatedAt, generatedAt) || other.generatedAt == generatedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.signedUrl, signedUrl) || other.signedUrl == signedUrl));
}


@override
int get hashCode => Object.hash(runtimeType,id,tenantId,templateVersion,pdfRef,generatedBy,generatedAt,createdAt,signedUrl);

@override
String toString() {
  return 'DmpRecord(id: $id, tenantId: $tenantId, templateVersion: $templateVersion, pdfRef: $pdfRef, generatedBy: $generatedBy, generatedAt: $generatedAt, createdAt: $createdAt, signedUrl: $signedUrl)';
}


}

/// @nodoc
abstract mixin class _$DmpRecordCopyWith<$Res> implements $DmpRecordCopyWith<$Res> {
  factory _$DmpRecordCopyWith(_DmpRecord value, $Res Function(_DmpRecord) _then) = __$DmpRecordCopyWithImpl;
@override @useResult
$Res call({
 String id, String tenantId, String templateVersion, String pdfRef, String generatedBy, DateTime? generatedAt, DateTime? createdAt, String signedUrl
});




}
/// @nodoc
class __$DmpRecordCopyWithImpl<$Res>
    implements _$DmpRecordCopyWith<$Res> {
  __$DmpRecordCopyWithImpl(this._self, this._then);

  final _DmpRecord _self;
  final $Res Function(_DmpRecord) _then;

/// Create a copy of DmpRecord
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? tenantId = null,Object? templateVersion = null,Object? pdfRef = null,Object? generatedBy = null,Object? generatedAt = freezed,Object? createdAt = freezed,Object? signedUrl = null,}) {
  return _then(_DmpRecord(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,tenantId: null == tenantId ? _self.tenantId : tenantId // ignore: cast_nullable_to_non_nullable
as String,templateVersion: null == templateVersion ? _self.templateVersion : templateVersion // ignore: cast_nullable_to_non_nullable
as String,pdfRef: null == pdfRef ? _self.pdfRef : pdfRef // ignore: cast_nullable_to_non_nullable
as String,generatedBy: null == generatedBy ? _self.generatedBy : generatedBy // ignore: cast_nullable_to_non_nullable
as String,generatedAt: freezed == generatedAt ? _self.generatedAt : generatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,signedUrl: null == signedUrl ? _self.signedUrl : signedUrl // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
