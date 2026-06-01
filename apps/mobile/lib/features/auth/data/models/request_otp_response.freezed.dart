// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'request_otp_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RequestOtpResponse {

@JsonKey(name: 'retry_after_seconds') int? get retryAfterSeconds;
/// Create a copy of RequestOtpResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RequestOtpResponseCopyWith<RequestOtpResponse> get copyWith => _$RequestOtpResponseCopyWithImpl<RequestOtpResponse>(this as RequestOtpResponse, _$identity);

  /// Serializes this RequestOtpResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RequestOtpResponse&&(identical(other.retryAfterSeconds, retryAfterSeconds) || other.retryAfterSeconds == retryAfterSeconds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,retryAfterSeconds);

@override
String toString() {
  return 'RequestOtpResponse(retryAfterSeconds: $retryAfterSeconds)';
}


}

/// @nodoc
abstract mixin class $RequestOtpResponseCopyWith<$Res>  {
  factory $RequestOtpResponseCopyWith(RequestOtpResponse value, $Res Function(RequestOtpResponse) _then) = _$RequestOtpResponseCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'retry_after_seconds') int? retryAfterSeconds
});




}
/// @nodoc
class _$RequestOtpResponseCopyWithImpl<$Res>
    implements $RequestOtpResponseCopyWith<$Res> {
  _$RequestOtpResponseCopyWithImpl(this._self, this._then);

  final RequestOtpResponse _self;
  final $Res Function(RequestOtpResponse) _then;

/// Create a copy of RequestOtpResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? retryAfterSeconds = freezed,}) {
  return _then(_self.copyWith(
retryAfterSeconds: freezed == retryAfterSeconds ? _self.retryAfterSeconds : retryAfterSeconds // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [RequestOtpResponse].
extension RequestOtpResponsePatterns on RequestOtpResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RequestOtpResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RequestOtpResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RequestOtpResponse value)  $default,){
final _that = this;
switch (_that) {
case _RequestOtpResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RequestOtpResponse value)?  $default,){
final _that = this;
switch (_that) {
case _RequestOtpResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'retry_after_seconds')  int? retryAfterSeconds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RequestOtpResponse() when $default != null:
return $default(_that.retryAfterSeconds);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'retry_after_seconds')  int? retryAfterSeconds)  $default,) {final _that = this;
switch (_that) {
case _RequestOtpResponse():
return $default(_that.retryAfterSeconds);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'retry_after_seconds')  int? retryAfterSeconds)?  $default,) {final _that = this;
switch (_that) {
case _RequestOtpResponse() when $default != null:
return $default(_that.retryAfterSeconds);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RequestOtpResponse implements RequestOtpResponse {
  const _RequestOtpResponse({@JsonKey(name: 'retry_after_seconds') this.retryAfterSeconds});
  factory _RequestOtpResponse.fromJson(Map<String, dynamic> json) => _$RequestOtpResponseFromJson(json);

@override@JsonKey(name: 'retry_after_seconds') final  int? retryAfterSeconds;

/// Create a copy of RequestOtpResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RequestOtpResponseCopyWith<_RequestOtpResponse> get copyWith => __$RequestOtpResponseCopyWithImpl<_RequestOtpResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RequestOtpResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RequestOtpResponse&&(identical(other.retryAfterSeconds, retryAfterSeconds) || other.retryAfterSeconds == retryAfterSeconds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,retryAfterSeconds);

@override
String toString() {
  return 'RequestOtpResponse(retryAfterSeconds: $retryAfterSeconds)';
}


}

/// @nodoc
abstract mixin class _$RequestOtpResponseCopyWith<$Res> implements $RequestOtpResponseCopyWith<$Res> {
  factory _$RequestOtpResponseCopyWith(_RequestOtpResponse value, $Res Function(_RequestOtpResponse) _then) = __$RequestOtpResponseCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'retry_after_seconds') int? retryAfterSeconds
});




}
/// @nodoc
class __$RequestOtpResponseCopyWithImpl<$Res>
    implements _$RequestOtpResponseCopyWith<$Res> {
  __$RequestOtpResponseCopyWithImpl(this._self, this._then);

  final _RequestOtpResponse _self;
  final $Res Function(_RequestOtpResponse) _then;

/// Create a copy of RequestOtpResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? retryAfterSeconds = freezed,}) {
  return _then(_RequestOtpResponse(
retryAfterSeconds: freezed == retryAfterSeconds ? _self.retryAfterSeconds : retryAfterSeconds // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
