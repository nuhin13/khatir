// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'request_otp_request.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RequestOtpRequest {

 String get phone;
/// Create a copy of RequestOtpRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RequestOtpRequestCopyWith<RequestOtpRequest> get copyWith => _$RequestOtpRequestCopyWithImpl<RequestOtpRequest>(this as RequestOtpRequest, _$identity);

  /// Serializes this RequestOtpRequest to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RequestOtpRequest&&(identical(other.phone, phone) || other.phone == phone));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,phone);

@override
String toString() {
  return 'RequestOtpRequest(phone: $phone)';
}


}

/// @nodoc
abstract mixin class $RequestOtpRequestCopyWith<$Res>  {
  factory $RequestOtpRequestCopyWith(RequestOtpRequest value, $Res Function(RequestOtpRequest) _then) = _$RequestOtpRequestCopyWithImpl;
@useResult
$Res call({
 String phone
});




}
/// @nodoc
class _$RequestOtpRequestCopyWithImpl<$Res>
    implements $RequestOtpRequestCopyWith<$Res> {
  _$RequestOtpRequestCopyWithImpl(this._self, this._then);

  final RequestOtpRequest _self;
  final $Res Function(RequestOtpRequest) _then;

/// Create a copy of RequestOtpRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? phone = null,}) {
  return _then(_self.copyWith(
phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [RequestOtpRequest].
extension RequestOtpRequestPatterns on RequestOtpRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RequestOtpRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RequestOtpRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RequestOtpRequest value)  $default,){
final _that = this;
switch (_that) {
case _RequestOtpRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RequestOtpRequest value)?  $default,){
final _that = this;
switch (_that) {
case _RequestOtpRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String phone)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RequestOtpRequest() when $default != null:
return $default(_that.phone);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String phone)  $default,) {final _that = this;
switch (_that) {
case _RequestOtpRequest():
return $default(_that.phone);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String phone)?  $default,) {final _that = this;
switch (_that) {
case _RequestOtpRequest() when $default != null:
return $default(_that.phone);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RequestOtpRequest implements RequestOtpRequest {
  const _RequestOtpRequest({required this.phone});
  factory _RequestOtpRequest.fromJson(Map<String, dynamic> json) => _$RequestOtpRequestFromJson(json);

@override final  String phone;

/// Create a copy of RequestOtpRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RequestOtpRequestCopyWith<_RequestOtpRequest> get copyWith => __$RequestOtpRequestCopyWithImpl<_RequestOtpRequest>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RequestOtpRequestToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RequestOtpRequest&&(identical(other.phone, phone) || other.phone == phone));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,phone);

@override
String toString() {
  return 'RequestOtpRequest(phone: $phone)';
}


}

/// @nodoc
abstract mixin class _$RequestOtpRequestCopyWith<$Res> implements $RequestOtpRequestCopyWith<$Res> {
  factory _$RequestOtpRequestCopyWith(_RequestOtpRequest value, $Res Function(_RequestOtpRequest) _then) = __$RequestOtpRequestCopyWithImpl;
@override @useResult
$Res call({
 String phone
});




}
/// @nodoc
class __$RequestOtpRequestCopyWithImpl<$Res>
    implements _$RequestOtpRequestCopyWith<$Res> {
  __$RequestOtpRequestCopyWithImpl(this._self, this._then);

  final _RequestOtpRequest _self;
  final $Res Function(_RequestOtpRequest) _then;

/// Create a copy of RequestOtpRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? phone = null,}) {
  return _then(_RequestOtpRequest(
phone: null == phone ? _self.phone : phone // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
