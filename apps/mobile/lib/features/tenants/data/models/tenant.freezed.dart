// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tenant.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Tenant {

 String get id; String get name; String get nidNumberMasked; DateTime? get dob; String get address; String get photoRef; VerificationStatus get verificationStatus; DateTime? get verifiedAt; bool get isAppUser; List<FamilyMember> get familyMembers; DateTime? get createdAt; DateTime? get updatedAt;
/// Create a copy of Tenant
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TenantCopyWith<Tenant> get copyWith => _$TenantCopyWithImpl<Tenant>(this as Tenant, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Tenant&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.nidNumberMasked, nidNumberMasked) || other.nidNumberMasked == nidNumberMasked)&&(identical(other.dob, dob) || other.dob == dob)&&(identical(other.address, address) || other.address == address)&&(identical(other.photoRef, photoRef) || other.photoRef == photoRef)&&(identical(other.verificationStatus, verificationStatus) || other.verificationStatus == verificationStatus)&&(identical(other.verifiedAt, verifiedAt) || other.verifiedAt == verifiedAt)&&(identical(other.isAppUser, isAppUser) || other.isAppUser == isAppUser)&&const DeepCollectionEquality().equals(other.familyMembers, familyMembers)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,nidNumberMasked,dob,address,photoRef,verificationStatus,verifiedAt,isAppUser,const DeepCollectionEquality().hash(familyMembers),createdAt,updatedAt);

@override
String toString() {
  return 'Tenant(id: $id, name: $name, nidNumberMasked: $nidNumberMasked, dob: $dob, address: $address, photoRef: $photoRef, verificationStatus: $verificationStatus, verifiedAt: $verifiedAt, isAppUser: $isAppUser, familyMembers: $familyMembers, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $TenantCopyWith<$Res>  {
  factory $TenantCopyWith(Tenant value, $Res Function(Tenant) _then) = _$TenantCopyWithImpl;
@useResult
$Res call({
 String id, String name, String nidNumberMasked, DateTime? dob, String address, String photoRef, VerificationStatus verificationStatus, DateTime? verifiedAt, bool isAppUser, List<FamilyMember> familyMembers, DateTime? createdAt, DateTime? updatedAt
});




}
/// @nodoc
class _$TenantCopyWithImpl<$Res>
    implements $TenantCopyWith<$Res> {
  _$TenantCopyWithImpl(this._self, this._then);

  final Tenant _self;
  final $Res Function(Tenant) _then;

/// Create a copy of Tenant
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? nidNumberMasked = null,Object? dob = freezed,Object? address = null,Object? photoRef = null,Object? verificationStatus = null,Object? verifiedAt = freezed,Object? isAppUser = null,Object? familyMembers = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,nidNumberMasked: null == nidNumberMasked ? _self.nidNumberMasked : nidNumberMasked // ignore: cast_nullable_to_non_nullable
as String,dob: freezed == dob ? _self.dob : dob // ignore: cast_nullable_to_non_nullable
as DateTime?,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,photoRef: null == photoRef ? _self.photoRef : photoRef // ignore: cast_nullable_to_non_nullable
as String,verificationStatus: null == verificationStatus ? _self.verificationStatus : verificationStatus // ignore: cast_nullable_to_non_nullable
as VerificationStatus,verifiedAt: freezed == verifiedAt ? _self.verifiedAt : verifiedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,isAppUser: null == isAppUser ? _self.isAppUser : isAppUser // ignore: cast_nullable_to_non_nullable
as bool,familyMembers: null == familyMembers ? _self.familyMembers : familyMembers // ignore: cast_nullable_to_non_nullable
as List<FamilyMember>,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [Tenant].
extension TenantPatterns on Tenant {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Tenant value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Tenant() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Tenant value)  $default,){
final _that = this;
switch (_that) {
case _Tenant():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Tenant value)?  $default,){
final _that = this;
switch (_that) {
case _Tenant() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String nidNumberMasked,  DateTime? dob,  String address,  String photoRef,  VerificationStatus verificationStatus,  DateTime? verifiedAt,  bool isAppUser,  List<FamilyMember> familyMembers,  DateTime? createdAt,  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Tenant() when $default != null:
return $default(_that.id,_that.name,_that.nidNumberMasked,_that.dob,_that.address,_that.photoRef,_that.verificationStatus,_that.verifiedAt,_that.isAppUser,_that.familyMembers,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String nidNumberMasked,  DateTime? dob,  String address,  String photoRef,  VerificationStatus verificationStatus,  DateTime? verifiedAt,  bool isAppUser,  List<FamilyMember> familyMembers,  DateTime? createdAt,  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _Tenant():
return $default(_that.id,_that.name,_that.nidNumberMasked,_that.dob,_that.address,_that.photoRef,_that.verificationStatus,_that.verifiedAt,_that.isAppUser,_that.familyMembers,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String nidNumberMasked,  DateTime? dob,  String address,  String photoRef,  VerificationStatus verificationStatus,  DateTime? verifiedAt,  bool isAppUser,  List<FamilyMember> familyMembers,  DateTime? createdAt,  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _Tenant() when $default != null:
return $default(_that.id,_that.name,_that.nidNumberMasked,_that.dob,_that.address,_that.photoRef,_that.verificationStatus,_that.verifiedAt,_that.isAppUser,_that.familyMembers,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc


class _Tenant implements Tenant {
  const _Tenant({required this.id, required this.name, this.nidNumberMasked = '', this.dob, this.address = '', this.photoRef = '', this.verificationStatus = VerificationStatus.unverified, this.verifiedAt, this.isAppUser = false, final  List<FamilyMember> familyMembers = const <FamilyMember>[], this.createdAt, this.updatedAt}): _familyMembers = familyMembers;
  

@override final  String id;
@override final  String name;
@override@JsonKey() final  String nidNumberMasked;
@override final  DateTime? dob;
@override@JsonKey() final  String address;
@override@JsonKey() final  String photoRef;
@override@JsonKey() final  VerificationStatus verificationStatus;
@override final  DateTime? verifiedAt;
@override@JsonKey() final  bool isAppUser;
 final  List<FamilyMember> _familyMembers;
@override@JsonKey() List<FamilyMember> get familyMembers {
  if (_familyMembers is EqualUnmodifiableListView) return _familyMembers;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_familyMembers);
}

@override final  DateTime? createdAt;
@override final  DateTime? updatedAt;

/// Create a copy of Tenant
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TenantCopyWith<_Tenant> get copyWith => __$TenantCopyWithImpl<_Tenant>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Tenant&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.nidNumberMasked, nidNumberMasked) || other.nidNumberMasked == nidNumberMasked)&&(identical(other.dob, dob) || other.dob == dob)&&(identical(other.address, address) || other.address == address)&&(identical(other.photoRef, photoRef) || other.photoRef == photoRef)&&(identical(other.verificationStatus, verificationStatus) || other.verificationStatus == verificationStatus)&&(identical(other.verifiedAt, verifiedAt) || other.verifiedAt == verifiedAt)&&(identical(other.isAppUser, isAppUser) || other.isAppUser == isAppUser)&&const DeepCollectionEquality().equals(other._familyMembers, _familyMembers)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,nidNumberMasked,dob,address,photoRef,verificationStatus,verifiedAt,isAppUser,const DeepCollectionEquality().hash(_familyMembers),createdAt,updatedAt);

@override
String toString() {
  return 'Tenant(id: $id, name: $name, nidNumberMasked: $nidNumberMasked, dob: $dob, address: $address, photoRef: $photoRef, verificationStatus: $verificationStatus, verifiedAt: $verifiedAt, isAppUser: $isAppUser, familyMembers: $familyMembers, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$TenantCopyWith<$Res> implements $TenantCopyWith<$Res> {
  factory _$TenantCopyWith(_Tenant value, $Res Function(_Tenant) _then) = __$TenantCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String nidNumberMasked, DateTime? dob, String address, String photoRef, VerificationStatus verificationStatus, DateTime? verifiedAt, bool isAppUser, List<FamilyMember> familyMembers, DateTime? createdAt, DateTime? updatedAt
});




}
/// @nodoc
class __$TenantCopyWithImpl<$Res>
    implements _$TenantCopyWith<$Res> {
  __$TenantCopyWithImpl(this._self, this._then);

  final _Tenant _self;
  final $Res Function(_Tenant) _then;

/// Create a copy of Tenant
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? nidNumberMasked = null,Object? dob = freezed,Object? address = null,Object? photoRef = null,Object? verificationStatus = null,Object? verifiedAt = freezed,Object? isAppUser = null,Object? familyMembers = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_Tenant(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,nidNumberMasked: null == nidNumberMasked ? _self.nidNumberMasked : nidNumberMasked // ignore: cast_nullable_to_non_nullable
as String,dob: freezed == dob ? _self.dob : dob // ignore: cast_nullable_to_non_nullable
as DateTime?,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as String,photoRef: null == photoRef ? _self.photoRef : photoRef // ignore: cast_nullable_to_non_nullable
as String,verificationStatus: null == verificationStatus ? _self.verificationStatus : verificationStatus // ignore: cast_nullable_to_non_nullable
as VerificationStatus,verifiedAt: freezed == verifiedAt ? _self.verifiedAt : verifiedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,isAppUser: null == isAppUser ? _self.isAppUser : isAppUser // ignore: cast_nullable_to_non_nullable
as bool,familyMembers: null == familyMembers ? _self._familyMembers : familyMembers // ignore: cast_nullable_to_non_nullable
as List<FamilyMember>,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
