// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'extracted_tenant.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ExtractedField {

 String? get value; double? get confidence;
/// Create a copy of ExtractedField
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExtractedFieldCopyWith<ExtractedField> get copyWith => _$ExtractedFieldCopyWithImpl<ExtractedField>(this as ExtractedField, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExtractedField&&(identical(other.value, value) || other.value == value)&&(identical(other.confidence, confidence) || other.confidence == confidence));
}


@override
int get hashCode => Object.hash(runtimeType,value,confidence);

@override
String toString() {
  return 'ExtractedField(value: $value, confidence: $confidence)';
}


}

/// @nodoc
abstract mixin class $ExtractedFieldCopyWith<$Res>  {
  factory $ExtractedFieldCopyWith(ExtractedField value, $Res Function(ExtractedField) _then) = _$ExtractedFieldCopyWithImpl;
@useResult
$Res call({
 String? value, double? confidence
});




}
/// @nodoc
class _$ExtractedFieldCopyWithImpl<$Res>
    implements $ExtractedFieldCopyWith<$Res> {
  _$ExtractedFieldCopyWithImpl(this._self, this._then);

  final ExtractedField _self;
  final $Res Function(ExtractedField) _then;

/// Create a copy of ExtractedField
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? value = freezed,Object? confidence = freezed,}) {
  return _then(_self.copyWith(
value: freezed == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String?,confidence: freezed == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

}


/// Adds pattern-matching-related methods to [ExtractedField].
extension ExtractedFieldPatterns on ExtractedField {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ExtractedField value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ExtractedField() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ExtractedField value)  $default,){
final _that = this;
switch (_that) {
case _ExtractedField():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ExtractedField value)?  $default,){
final _that = this;
switch (_that) {
case _ExtractedField() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String? value,  double? confidence)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ExtractedField() when $default != null:
return $default(_that.value,_that.confidence);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String? value,  double? confidence)  $default,) {final _that = this;
switch (_that) {
case _ExtractedField():
return $default(_that.value,_that.confidence);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String? value,  double? confidence)?  $default,) {final _that = this;
switch (_that) {
case _ExtractedField() when $default != null:
return $default(_that.value,_that.confidence);case _:
  return null;

}
}

}

/// @nodoc


class _ExtractedField implements ExtractedField {
  const _ExtractedField({this.value, this.confidence});
  

@override final  String? value;
@override final  double? confidence;

/// Create a copy of ExtractedField
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ExtractedFieldCopyWith<_ExtractedField> get copyWith => __$ExtractedFieldCopyWithImpl<_ExtractedField>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ExtractedField&&(identical(other.value, value) || other.value == value)&&(identical(other.confidence, confidence) || other.confidence == confidence));
}


@override
int get hashCode => Object.hash(runtimeType,value,confidence);

@override
String toString() {
  return 'ExtractedField(value: $value, confidence: $confidence)';
}


}

/// @nodoc
abstract mixin class _$ExtractedFieldCopyWith<$Res> implements $ExtractedFieldCopyWith<$Res> {
  factory _$ExtractedFieldCopyWith(_ExtractedField value, $Res Function(_ExtractedField) _then) = __$ExtractedFieldCopyWithImpl;
@override @useResult
$Res call({
 String? value, double? confidence
});




}
/// @nodoc
class __$ExtractedFieldCopyWithImpl<$Res>
    implements _$ExtractedFieldCopyWith<$Res> {
  __$ExtractedFieldCopyWithImpl(this._self, this._then);

  final _ExtractedField _self;
  final $Res Function(_ExtractedField) _then;

/// Create a copy of ExtractedField
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? value = freezed,Object? confidence = freezed,}) {
  return _then(_ExtractedField(
value: freezed == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String?,confidence: freezed == confidence ? _self.confidence : confidence // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}

/// @nodoc
mixin _$ExtractedTenant {

 ExtractedField get name; ExtractedField get nidNumber; ExtractedField get dob; ExtractedField get address; String get photoRef;
/// Create a copy of ExtractedTenant
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExtractedTenantCopyWith<ExtractedTenant> get copyWith => _$ExtractedTenantCopyWithImpl<ExtractedTenant>(this as ExtractedTenant, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExtractedTenant&&(identical(other.name, name) || other.name == name)&&(identical(other.nidNumber, nidNumber) || other.nidNumber == nidNumber)&&(identical(other.dob, dob) || other.dob == dob)&&(identical(other.address, address) || other.address == address)&&(identical(other.photoRef, photoRef) || other.photoRef == photoRef));
}


@override
int get hashCode => Object.hash(runtimeType,name,nidNumber,dob,address,photoRef);

@override
String toString() {
  return 'ExtractedTenant(name: $name, nidNumber: $nidNumber, dob: $dob, address: $address, photoRef: $photoRef)';
}


}

/// @nodoc
abstract mixin class $ExtractedTenantCopyWith<$Res>  {
  factory $ExtractedTenantCopyWith(ExtractedTenant value, $Res Function(ExtractedTenant) _then) = _$ExtractedTenantCopyWithImpl;
@useResult
$Res call({
 ExtractedField name, ExtractedField nidNumber, ExtractedField dob, ExtractedField address, String photoRef
});


$ExtractedFieldCopyWith<$Res> get name;$ExtractedFieldCopyWith<$Res> get nidNumber;$ExtractedFieldCopyWith<$Res> get dob;$ExtractedFieldCopyWith<$Res> get address;

}
/// @nodoc
class _$ExtractedTenantCopyWithImpl<$Res>
    implements $ExtractedTenantCopyWith<$Res> {
  _$ExtractedTenantCopyWithImpl(this._self, this._then);

  final ExtractedTenant _self;
  final $Res Function(ExtractedTenant) _then;

/// Create a copy of ExtractedTenant
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? nidNumber = null,Object? dob = null,Object? address = null,Object? photoRef = null,}) {
  return _then(_self.copyWith(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as ExtractedField,nidNumber: null == nidNumber ? _self.nidNumber : nidNumber // ignore: cast_nullable_to_non_nullable
as ExtractedField,dob: null == dob ? _self.dob : dob // ignore: cast_nullable_to_non_nullable
as ExtractedField,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as ExtractedField,photoRef: null == photoRef ? _self.photoRef : photoRef // ignore: cast_nullable_to_non_nullable
as String,
  ));
}
/// Create a copy of ExtractedTenant
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ExtractedFieldCopyWith<$Res> get name {
  
  return $ExtractedFieldCopyWith<$Res>(_self.name, (value) {
    return _then(_self.copyWith(name: value));
  });
}/// Create a copy of ExtractedTenant
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ExtractedFieldCopyWith<$Res> get nidNumber {
  
  return $ExtractedFieldCopyWith<$Res>(_self.nidNumber, (value) {
    return _then(_self.copyWith(nidNumber: value));
  });
}/// Create a copy of ExtractedTenant
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ExtractedFieldCopyWith<$Res> get dob {
  
  return $ExtractedFieldCopyWith<$Res>(_self.dob, (value) {
    return _then(_self.copyWith(dob: value));
  });
}/// Create a copy of ExtractedTenant
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ExtractedFieldCopyWith<$Res> get address {
  
  return $ExtractedFieldCopyWith<$Res>(_self.address, (value) {
    return _then(_self.copyWith(address: value));
  });
}
}


/// Adds pattern-matching-related methods to [ExtractedTenant].
extension ExtractedTenantPatterns on ExtractedTenant {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ExtractedTenant value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ExtractedTenant() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ExtractedTenant value)  $default,){
final _that = this;
switch (_that) {
case _ExtractedTenant():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ExtractedTenant value)?  $default,){
final _that = this;
switch (_that) {
case _ExtractedTenant() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ExtractedField name,  ExtractedField nidNumber,  ExtractedField dob,  ExtractedField address,  String photoRef)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ExtractedTenant() when $default != null:
return $default(_that.name,_that.nidNumber,_that.dob,_that.address,_that.photoRef);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ExtractedField name,  ExtractedField nidNumber,  ExtractedField dob,  ExtractedField address,  String photoRef)  $default,) {final _that = this;
switch (_that) {
case _ExtractedTenant():
return $default(_that.name,_that.nidNumber,_that.dob,_that.address,_that.photoRef);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ExtractedField name,  ExtractedField nidNumber,  ExtractedField dob,  ExtractedField address,  String photoRef)?  $default,) {final _that = this;
switch (_that) {
case _ExtractedTenant() when $default != null:
return $default(_that.name,_that.nidNumber,_that.dob,_that.address,_that.photoRef);case _:
  return null;

}
}

}

/// @nodoc


class _ExtractedTenant implements ExtractedTenant {
  const _ExtractedTenant({required this.name, required this.nidNumber, required this.dob, required this.address, required this.photoRef});
  

@override final  ExtractedField name;
@override final  ExtractedField nidNumber;
@override final  ExtractedField dob;
@override final  ExtractedField address;
@override final  String photoRef;

/// Create a copy of ExtractedTenant
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ExtractedTenantCopyWith<_ExtractedTenant> get copyWith => __$ExtractedTenantCopyWithImpl<_ExtractedTenant>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ExtractedTenant&&(identical(other.name, name) || other.name == name)&&(identical(other.nidNumber, nidNumber) || other.nidNumber == nidNumber)&&(identical(other.dob, dob) || other.dob == dob)&&(identical(other.address, address) || other.address == address)&&(identical(other.photoRef, photoRef) || other.photoRef == photoRef));
}


@override
int get hashCode => Object.hash(runtimeType,name,nidNumber,dob,address,photoRef);

@override
String toString() {
  return 'ExtractedTenant(name: $name, nidNumber: $nidNumber, dob: $dob, address: $address, photoRef: $photoRef)';
}


}

/// @nodoc
abstract mixin class _$ExtractedTenantCopyWith<$Res> implements $ExtractedTenantCopyWith<$Res> {
  factory _$ExtractedTenantCopyWith(_ExtractedTenant value, $Res Function(_ExtractedTenant) _then) = __$ExtractedTenantCopyWithImpl;
@override @useResult
$Res call({
 ExtractedField name, ExtractedField nidNumber, ExtractedField dob, ExtractedField address, String photoRef
});


@override $ExtractedFieldCopyWith<$Res> get name;@override $ExtractedFieldCopyWith<$Res> get nidNumber;@override $ExtractedFieldCopyWith<$Res> get dob;@override $ExtractedFieldCopyWith<$Res> get address;

}
/// @nodoc
class __$ExtractedTenantCopyWithImpl<$Res>
    implements _$ExtractedTenantCopyWith<$Res> {
  __$ExtractedTenantCopyWithImpl(this._self, this._then);

  final _ExtractedTenant _self;
  final $Res Function(_ExtractedTenant) _then;

/// Create a copy of ExtractedTenant
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? nidNumber = null,Object? dob = null,Object? address = null,Object? photoRef = null,}) {
  return _then(_ExtractedTenant(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as ExtractedField,nidNumber: null == nidNumber ? _self.nidNumber : nidNumber // ignore: cast_nullable_to_non_nullable
as ExtractedField,dob: null == dob ? _self.dob : dob // ignore: cast_nullable_to_non_nullable
as ExtractedField,address: null == address ? _self.address : address // ignore: cast_nullable_to_non_nullable
as ExtractedField,photoRef: null == photoRef ? _self.photoRef : photoRef // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

/// Create a copy of ExtractedTenant
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ExtractedFieldCopyWith<$Res> get name {
  
  return $ExtractedFieldCopyWith<$Res>(_self.name, (value) {
    return _then(_self.copyWith(name: value));
  });
}/// Create a copy of ExtractedTenant
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ExtractedFieldCopyWith<$Res> get nidNumber {
  
  return $ExtractedFieldCopyWith<$Res>(_self.nidNumber, (value) {
    return _then(_self.copyWith(nidNumber: value));
  });
}/// Create a copy of ExtractedTenant
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ExtractedFieldCopyWith<$Res> get dob {
  
  return $ExtractedFieldCopyWith<$Res>(_self.dob, (value) {
    return _then(_self.copyWith(dob: value));
  });
}/// Create a copy of ExtractedTenant
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ExtractedFieldCopyWith<$Res> get address {
  
  return $ExtractedFieldCopyWith<$Res>(_self.address, (value) {
    return _then(_self.copyWith(address: value));
  });
}
}

// dart format on
