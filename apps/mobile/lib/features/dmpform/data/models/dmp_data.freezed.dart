// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'dmp_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DmpData {

 String get tenantName; String get nidNumber; String get dob; String get permanentAddress; String get presentAddress; String get buildingAddress; String get buildingArea; String get landlordName; String get landlordPhone; List<DmpFamilyMemberData> get familyMembers;
/// Create a copy of DmpData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DmpDataCopyWith<DmpData> get copyWith => _$DmpDataCopyWithImpl<DmpData>(this as DmpData, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DmpData&&(identical(other.tenantName, tenantName) || other.tenantName == tenantName)&&(identical(other.nidNumber, nidNumber) || other.nidNumber == nidNumber)&&(identical(other.dob, dob) || other.dob == dob)&&(identical(other.permanentAddress, permanentAddress) || other.permanentAddress == permanentAddress)&&(identical(other.presentAddress, presentAddress) || other.presentAddress == presentAddress)&&(identical(other.buildingAddress, buildingAddress) || other.buildingAddress == buildingAddress)&&(identical(other.buildingArea, buildingArea) || other.buildingArea == buildingArea)&&(identical(other.landlordName, landlordName) || other.landlordName == landlordName)&&(identical(other.landlordPhone, landlordPhone) || other.landlordPhone == landlordPhone)&&const DeepCollectionEquality().equals(other.familyMembers, familyMembers));
}


@override
int get hashCode => Object.hash(runtimeType,tenantName,nidNumber,dob,permanentAddress,presentAddress,buildingAddress,buildingArea,landlordName,landlordPhone,const DeepCollectionEquality().hash(familyMembers));

@override
String toString() {
  return 'DmpData(tenantName: $tenantName, nidNumber: $nidNumber, dob: $dob, permanentAddress: $permanentAddress, presentAddress: $presentAddress, buildingAddress: $buildingAddress, buildingArea: $buildingArea, landlordName: $landlordName, landlordPhone: $landlordPhone, familyMembers: $familyMembers)';
}


}

/// @nodoc
abstract mixin class $DmpDataCopyWith<$Res>  {
  factory $DmpDataCopyWith(DmpData value, $Res Function(DmpData) _then) = _$DmpDataCopyWithImpl;
@useResult
$Res call({
 String tenantName, String nidNumber, String dob, String permanentAddress, String presentAddress, String buildingAddress, String buildingArea, String landlordName, String landlordPhone, List<DmpFamilyMemberData> familyMembers
});




}
/// @nodoc
class _$DmpDataCopyWithImpl<$Res>
    implements $DmpDataCopyWith<$Res> {
  _$DmpDataCopyWithImpl(this._self, this._then);

  final DmpData _self;
  final $Res Function(DmpData) _then;

/// Create a copy of DmpData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? tenantName = null,Object? nidNumber = null,Object? dob = null,Object? permanentAddress = null,Object? presentAddress = null,Object? buildingAddress = null,Object? buildingArea = null,Object? landlordName = null,Object? landlordPhone = null,Object? familyMembers = null,}) {
  return _then(_self.copyWith(
tenantName: null == tenantName ? _self.tenantName : tenantName // ignore: cast_nullable_to_non_nullable
as String,nidNumber: null == nidNumber ? _self.nidNumber : nidNumber // ignore: cast_nullable_to_non_nullable
as String,dob: null == dob ? _self.dob : dob // ignore: cast_nullable_to_non_nullable
as String,permanentAddress: null == permanentAddress ? _self.permanentAddress : permanentAddress // ignore: cast_nullable_to_non_nullable
as String,presentAddress: null == presentAddress ? _self.presentAddress : presentAddress // ignore: cast_nullable_to_non_nullable
as String,buildingAddress: null == buildingAddress ? _self.buildingAddress : buildingAddress // ignore: cast_nullable_to_non_nullable
as String,buildingArea: null == buildingArea ? _self.buildingArea : buildingArea // ignore: cast_nullable_to_non_nullable
as String,landlordName: null == landlordName ? _self.landlordName : landlordName // ignore: cast_nullable_to_non_nullable
as String,landlordPhone: null == landlordPhone ? _self.landlordPhone : landlordPhone // ignore: cast_nullable_to_non_nullable
as String,familyMembers: null == familyMembers ? _self.familyMembers : familyMembers // ignore: cast_nullable_to_non_nullable
as List<DmpFamilyMemberData>,
  ));
}

}


/// Adds pattern-matching-related methods to [DmpData].
extension DmpDataPatterns on DmpData {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DmpData value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DmpData() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DmpData value)  $default,){
final _that = this;
switch (_that) {
case _DmpData():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DmpData value)?  $default,){
final _that = this;
switch (_that) {
case _DmpData() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String tenantName,  String nidNumber,  String dob,  String permanentAddress,  String presentAddress,  String buildingAddress,  String buildingArea,  String landlordName,  String landlordPhone,  List<DmpFamilyMemberData> familyMembers)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DmpData() when $default != null:
return $default(_that.tenantName,_that.nidNumber,_that.dob,_that.permanentAddress,_that.presentAddress,_that.buildingAddress,_that.buildingArea,_that.landlordName,_that.landlordPhone,_that.familyMembers);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String tenantName,  String nidNumber,  String dob,  String permanentAddress,  String presentAddress,  String buildingAddress,  String buildingArea,  String landlordName,  String landlordPhone,  List<DmpFamilyMemberData> familyMembers)  $default,) {final _that = this;
switch (_that) {
case _DmpData():
return $default(_that.tenantName,_that.nidNumber,_that.dob,_that.permanentAddress,_that.presentAddress,_that.buildingAddress,_that.buildingArea,_that.landlordName,_that.landlordPhone,_that.familyMembers);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String tenantName,  String nidNumber,  String dob,  String permanentAddress,  String presentAddress,  String buildingAddress,  String buildingArea,  String landlordName,  String landlordPhone,  List<DmpFamilyMemberData> familyMembers)?  $default,) {final _that = this;
switch (_that) {
case _DmpData() when $default != null:
return $default(_that.tenantName,_that.nidNumber,_that.dob,_that.permanentAddress,_that.presentAddress,_that.buildingAddress,_that.buildingArea,_that.landlordName,_that.landlordPhone,_that.familyMembers);case _:
  return null;

}
}

}

/// @nodoc


class _DmpData implements DmpData {
  const _DmpData({this.tenantName = '', this.nidNumber = '', this.dob = '', this.permanentAddress = '', this.presentAddress = '', this.buildingAddress = '', this.buildingArea = '', this.landlordName = '', this.landlordPhone = '', final  List<DmpFamilyMemberData> familyMembers = const <DmpFamilyMemberData>[]}): _familyMembers = familyMembers;
  

@override@JsonKey() final  String tenantName;
@override@JsonKey() final  String nidNumber;
@override@JsonKey() final  String dob;
@override@JsonKey() final  String permanentAddress;
@override@JsonKey() final  String presentAddress;
@override@JsonKey() final  String buildingAddress;
@override@JsonKey() final  String buildingArea;
@override@JsonKey() final  String landlordName;
@override@JsonKey() final  String landlordPhone;
 final  List<DmpFamilyMemberData> _familyMembers;
@override@JsonKey() List<DmpFamilyMemberData> get familyMembers {
  if (_familyMembers is EqualUnmodifiableListView) return _familyMembers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_familyMembers);
}


/// Create a copy of DmpData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DmpDataCopyWith<_DmpData> get copyWith => __$DmpDataCopyWithImpl<_DmpData>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DmpData&&(identical(other.tenantName, tenantName) || other.tenantName == tenantName)&&(identical(other.nidNumber, nidNumber) || other.nidNumber == nidNumber)&&(identical(other.dob, dob) || other.dob == dob)&&(identical(other.permanentAddress, permanentAddress) || other.permanentAddress == permanentAddress)&&(identical(other.presentAddress, presentAddress) || other.presentAddress == presentAddress)&&(identical(other.buildingAddress, buildingAddress) || other.buildingAddress == buildingAddress)&&(identical(other.buildingArea, buildingArea) || other.buildingArea == buildingArea)&&(identical(other.landlordName, landlordName) || other.landlordName == landlordName)&&(identical(other.landlordPhone, landlordPhone) || other.landlordPhone == landlordPhone)&&const DeepCollectionEquality().equals(other._familyMembers, _familyMembers));
}


@override
int get hashCode => Object.hash(runtimeType,tenantName,nidNumber,dob,permanentAddress,presentAddress,buildingAddress,buildingArea,landlordName,landlordPhone,const DeepCollectionEquality().hash(_familyMembers));

@override
String toString() {
  return 'DmpData(tenantName: $tenantName, nidNumber: $nidNumber, dob: $dob, permanentAddress: $permanentAddress, presentAddress: $presentAddress, buildingAddress: $buildingAddress, buildingArea: $buildingArea, landlordName: $landlordName, landlordPhone: $landlordPhone, familyMembers: $familyMembers)';
}


}

/// @nodoc
abstract mixin class _$DmpDataCopyWith<$Res> implements $DmpDataCopyWith<$Res> {
  factory _$DmpDataCopyWith(_DmpData value, $Res Function(_DmpData) _then) = __$DmpDataCopyWithImpl;
@override @useResult
$Res call({
 String tenantName, String nidNumber, String dob, String permanentAddress, String presentAddress, String buildingAddress, String buildingArea, String landlordName, String landlordPhone, List<DmpFamilyMemberData> familyMembers
});




}
/// @nodoc
class __$DmpDataCopyWithImpl<$Res>
    implements _$DmpDataCopyWith<$Res> {
  __$DmpDataCopyWithImpl(this._self, this._then);

  final _DmpData _self;
  final $Res Function(_DmpData) _then;

/// Create a copy of DmpData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? tenantName = null,Object? nidNumber = null,Object? dob = null,Object? permanentAddress = null,Object? presentAddress = null,Object? buildingAddress = null,Object? buildingArea = null,Object? landlordName = null,Object? landlordPhone = null,Object? familyMembers = null,}) {
  return _then(_DmpData(
tenantName: null == tenantName ? _self.tenantName : tenantName // ignore: cast_nullable_to_non_nullable
as String,nidNumber: null == nidNumber ? _self.nidNumber : nidNumber // ignore: cast_nullable_to_non_nullable
as String,dob: null == dob ? _self.dob : dob // ignore: cast_nullable_to_non_nullable
as String,permanentAddress: null == permanentAddress ? _self.permanentAddress : permanentAddress // ignore: cast_nullable_to_non_nullable
as String,presentAddress: null == presentAddress ? _self.presentAddress : presentAddress // ignore: cast_nullable_to_non_nullable
as String,buildingAddress: null == buildingAddress ? _self.buildingAddress : buildingAddress // ignore: cast_nullable_to_non_nullable
as String,buildingArea: null == buildingArea ? _self.buildingArea : buildingArea // ignore: cast_nullable_to_non_nullable
as String,landlordName: null == landlordName ? _self.landlordName : landlordName // ignore: cast_nullable_to_non_nullable
as String,landlordPhone: null == landlordPhone ? _self.landlordPhone : landlordPhone // ignore: cast_nullable_to_non_nullable
as String,familyMembers: null == familyMembers ? _self._familyMembers : familyMembers // ignore: cast_nullable_to_non_nullable
as List<DmpFamilyMemberData>,
  ));
}


}

/// @nodoc
mixin _$DmpFamilyMemberData {

 String get name; String get relation;
/// Create a copy of DmpFamilyMemberData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DmpFamilyMemberDataCopyWith<DmpFamilyMemberData> get copyWith => _$DmpFamilyMemberDataCopyWithImpl<DmpFamilyMemberData>(this as DmpFamilyMemberData, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DmpFamilyMemberData&&(identical(other.name, name) || other.name == name)&&(identical(other.relation, relation) || other.relation == relation));
}


@override
int get hashCode => Object.hash(runtimeType,name,relation);

@override
String toString() {
  return 'DmpFamilyMemberData(name: $name, relation: $relation)';
}


}

/// @nodoc
abstract mixin class $DmpFamilyMemberDataCopyWith<$Res>  {
  factory $DmpFamilyMemberDataCopyWith(DmpFamilyMemberData value, $Res Function(DmpFamilyMemberData) _then) = _$DmpFamilyMemberDataCopyWithImpl;
@useResult
$Res call({
 String name, String relation
});




}
/// @nodoc
class _$DmpFamilyMemberDataCopyWithImpl<$Res>
    implements $DmpFamilyMemberDataCopyWith<$Res> {
  _$DmpFamilyMemberDataCopyWithImpl(this._self, this._then);

  final DmpFamilyMemberData _self;
  final $Res Function(DmpFamilyMemberData) _then;

/// Create a copy of DmpFamilyMemberData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? relation = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,relation: null == relation ? _self.relation : relation // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [DmpFamilyMemberData].
extension DmpFamilyMemberDataPatterns on DmpFamilyMemberData {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DmpFamilyMemberData value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DmpFamilyMemberData() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DmpFamilyMemberData value)  $default,){
final _that = this;
switch (_that) {
case _DmpFamilyMemberData():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DmpFamilyMemberData value)?  $default,){
final _that = this;
switch (_that) {
case _DmpFamilyMemberData() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  String relation)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DmpFamilyMemberData() when $default != null:
return $default(_that.name,_that.relation);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  String relation)  $default,) {final _that = this;
switch (_that) {
case _DmpFamilyMemberData():
return $default(_that.name,_that.relation);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  String relation)?  $default,) {final _that = this;
switch (_that) {
case _DmpFamilyMemberData() when $default != null:
return $default(_that.name,_that.relation);case _:
  return null;

}
}

}

/// @nodoc


class _DmpFamilyMemberData implements DmpFamilyMemberData {
  const _DmpFamilyMemberData({this.name = '', this.relation = ''});
  

@override@JsonKey() final  String name;
@override@JsonKey() final  String relation;

/// Create a copy of DmpFamilyMemberData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DmpFamilyMemberDataCopyWith<_DmpFamilyMemberData> get copyWith => __$DmpFamilyMemberDataCopyWithImpl<_DmpFamilyMemberData>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DmpFamilyMemberData&&(identical(other.name, name) || other.name == name)&&(identical(other.relation, relation) || other.relation == relation));
}


@override
int get hashCode => Object.hash(runtimeType,name,relation);

@override
String toString() {
  return 'DmpFamilyMemberData(name: $name, relation: $relation)';
}


}

/// @nodoc
abstract mixin class _$DmpFamilyMemberDataCopyWith<$Res> implements $DmpFamilyMemberDataCopyWith<$Res> {
  factory _$DmpFamilyMemberDataCopyWith(_DmpFamilyMemberData value, $Res Function(_DmpFamilyMemberData) _then) = __$DmpFamilyMemberDataCopyWithImpl;
@override @useResult
$Res call({
 String name, String relation
});




}
/// @nodoc
class __$DmpFamilyMemberDataCopyWithImpl<$Res>
    implements _$DmpFamilyMemberDataCopyWith<$Res> {
  __$DmpFamilyMemberDataCopyWithImpl(this._self, this._then);

  final _DmpFamilyMemberData _self;
  final $Res Function(_DmpFamilyMemberData) _then;

/// Create a copy of DmpFamilyMemberData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? relation = null,}) {
  return _then(_DmpFamilyMemberData(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,relation: null == relation ? _self.relation : relation // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
