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
mixin _$RentRequest {

 String get id; String get leaseId; String get rentScheduleId; double get amount; String get period; String get linkToken; Channel get sentVia; DateTime? get sentAt; RentRequestStatus get status; DateTime? get createdAt; DateTime? get updatedAt;
/// Create a copy of RentRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RentRequestCopyWith<RentRequest> get copyWith => _$RentRequestCopyWithImpl<RentRequest>(this as RentRequest, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RentRequest&&(identical(other.id, id) || other.id == id)&&(identical(other.leaseId, leaseId) || other.leaseId == leaseId)&&(identical(other.rentScheduleId, rentScheduleId) || other.rentScheduleId == rentScheduleId)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.period, period) || other.period == period)&&(identical(other.linkToken, linkToken) || other.linkToken == linkToken)&&(identical(other.sentVia, sentVia) || other.sentVia == sentVia)&&(identical(other.sentAt, sentAt) || other.sentAt == sentAt)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,leaseId,rentScheduleId,amount,period,linkToken,sentVia,sentAt,status,createdAt,updatedAt);

@override
String toString() {
  return 'RentRequest(id: $id, leaseId: $leaseId, rentScheduleId: $rentScheduleId, amount: $amount, period: $period, linkToken: $linkToken, sentVia: $sentVia, sentAt: $sentAt, status: $status, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $RentRequestCopyWith<$Res>  {
  factory $RentRequestCopyWith(RentRequest value, $Res Function(RentRequest) _then) = _$RentRequestCopyWithImpl;
@useResult
$Res call({
 String id, String leaseId, String rentScheduleId, double amount, String period, String linkToken, Channel sentVia, DateTime? sentAt, RentRequestStatus status, DateTime? createdAt, DateTime? updatedAt
});




}
/// @nodoc
class _$RentRequestCopyWithImpl<$Res>
    implements $RentRequestCopyWith<$Res> {
  _$RentRequestCopyWithImpl(this._self, this._then);

  final RentRequest _self;
  final $Res Function(RentRequest) _then;

/// Create a copy of RentRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? leaseId = null,Object? rentScheduleId = null,Object? amount = null,Object? period = null,Object? linkToken = null,Object? sentVia = null,Object? sentAt = freezed,Object? status = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,leaseId: null == leaseId ? _self.leaseId : leaseId // ignore: cast_nullable_to_non_nullable
as String,rentScheduleId: null == rentScheduleId ? _self.rentScheduleId : rentScheduleId // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,period: null == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as String,linkToken: null == linkToken ? _self.linkToken : linkToken // ignore: cast_nullable_to_non_nullable
as String,sentVia: null == sentVia ? _self.sentVia : sentVia // ignore: cast_nullable_to_non_nullable
as Channel,sentAt: freezed == sentAt ? _self.sentAt : sentAt // ignore: cast_nullable_to_non_nullable
as DateTime?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as RentRequestStatus,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [RentRequest].
extension RentRequestPatterns on RentRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RentRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RentRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RentRequest value)  $default,){
final _that = this;
switch (_that) {
case _RentRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RentRequest value)?  $default,){
final _that = this;
switch (_that) {
case _RentRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String leaseId,  String rentScheduleId,  double amount,  String period,  String linkToken,  Channel sentVia,  DateTime? sentAt,  RentRequestStatus status,  DateTime? createdAt,  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RentRequest() when $default != null:
return $default(_that.id,_that.leaseId,_that.rentScheduleId,_that.amount,_that.period,_that.linkToken,_that.sentVia,_that.sentAt,_that.status,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String leaseId,  String rentScheduleId,  double amount,  String period,  String linkToken,  Channel sentVia,  DateTime? sentAt,  RentRequestStatus status,  DateTime? createdAt,  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _RentRequest():
return $default(_that.id,_that.leaseId,_that.rentScheduleId,_that.amount,_that.period,_that.linkToken,_that.sentVia,_that.sentAt,_that.status,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String leaseId,  String rentScheduleId,  double amount,  String period,  String linkToken,  Channel sentVia,  DateTime? sentAt,  RentRequestStatus status,  DateTime? createdAt,  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _RentRequest() when $default != null:
return $default(_that.id,_that.leaseId,_that.rentScheduleId,_that.amount,_that.period,_that.linkToken,_that.sentVia,_that.sentAt,_that.status,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc


class _RentRequest implements RentRequest {
  const _RentRequest({required this.id, this.leaseId = '', this.rentScheduleId = '', this.amount = 0, this.period = '', this.linkToken = '', this.sentVia = Channel.whatsapp, this.sentAt, this.status = RentRequestStatus.sent, this.createdAt, this.updatedAt});
  

@override final  String id;
@override@JsonKey() final  String leaseId;
@override@JsonKey() final  String rentScheduleId;
@override@JsonKey() final  double amount;
@override@JsonKey() final  String period;
@override@JsonKey() final  String linkToken;
@override@JsonKey() final  Channel sentVia;
@override final  DateTime? sentAt;
@override@JsonKey() final  RentRequestStatus status;
@override final  DateTime? createdAt;
@override final  DateTime? updatedAt;

/// Create a copy of RentRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RentRequestCopyWith<_RentRequest> get copyWith => __$RentRequestCopyWithImpl<_RentRequest>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RentRequest&&(identical(other.id, id) || other.id == id)&&(identical(other.leaseId, leaseId) || other.leaseId == leaseId)&&(identical(other.rentScheduleId, rentScheduleId) || other.rentScheduleId == rentScheduleId)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.period, period) || other.period == period)&&(identical(other.linkToken, linkToken) || other.linkToken == linkToken)&&(identical(other.sentVia, sentVia) || other.sentVia == sentVia)&&(identical(other.sentAt, sentAt) || other.sentAt == sentAt)&&(identical(other.status, status) || other.status == status)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,leaseId,rentScheduleId,amount,period,linkToken,sentVia,sentAt,status,createdAt,updatedAt);

@override
String toString() {
  return 'RentRequest(id: $id, leaseId: $leaseId, rentScheduleId: $rentScheduleId, amount: $amount, period: $period, linkToken: $linkToken, sentVia: $sentVia, sentAt: $sentAt, status: $status, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$RentRequestCopyWith<$Res> implements $RentRequestCopyWith<$Res> {
  factory _$RentRequestCopyWith(_RentRequest value, $Res Function(_RentRequest) _then) = __$RentRequestCopyWithImpl;
@override @useResult
$Res call({
 String id, String leaseId, String rentScheduleId, double amount, String period, String linkToken, Channel sentVia, DateTime? sentAt, RentRequestStatus status, DateTime? createdAt, DateTime? updatedAt
});




}
/// @nodoc
class __$RentRequestCopyWithImpl<$Res>
    implements _$RentRequestCopyWith<$Res> {
  __$RentRequestCopyWithImpl(this._self, this._then);

  final _RentRequest _self;
  final $Res Function(_RentRequest) _then;

/// Create a copy of RentRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? leaseId = null,Object? rentScheduleId = null,Object? amount = null,Object? period = null,Object? linkToken = null,Object? sentVia = null,Object? sentAt = freezed,Object? status = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_RentRequest(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,leaseId: null == leaseId ? _self.leaseId : leaseId // ignore: cast_nullable_to_non_nullable
as String,rentScheduleId: null == rentScheduleId ? _self.rentScheduleId : rentScheduleId // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,period: null == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as String,linkToken: null == linkToken ? _self.linkToken : linkToken // ignore: cast_nullable_to_non_nullable
as String,sentVia: null == sentVia ? _self.sentVia : sentVia // ignore: cast_nullable_to_non_nullable
as Channel,sentAt: freezed == sentAt ? _self.sentAt : sentAt // ignore: cast_nullable_to_non_nullable
as DateTime?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as RentRequestStatus,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

/// @nodoc
mixin _$PaymentProof {

 String get id; String get rentRequestId; PaymentProofType get type; String get value; String get photoRef; DateTime? get submittedAt; DateTime? get createdAt; DateTime? get updatedAt;
/// Create a copy of PaymentProof
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PaymentProofCopyWith<PaymentProof> get copyWith => _$PaymentProofCopyWithImpl<PaymentProof>(this as PaymentProof, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PaymentProof&&(identical(other.id, id) || other.id == id)&&(identical(other.rentRequestId, rentRequestId) || other.rentRequestId == rentRequestId)&&(identical(other.type, type) || other.type == type)&&(identical(other.value, value) || other.value == value)&&(identical(other.photoRef, photoRef) || other.photoRef == photoRef)&&(identical(other.submittedAt, submittedAt) || other.submittedAt == submittedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,rentRequestId,type,value,photoRef,submittedAt,createdAt,updatedAt);

@override
String toString() {
  return 'PaymentProof(id: $id, rentRequestId: $rentRequestId, type: $type, value: $value, photoRef: $photoRef, submittedAt: $submittedAt, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $PaymentProofCopyWith<$Res>  {
  factory $PaymentProofCopyWith(PaymentProof value, $Res Function(PaymentProof) _then) = _$PaymentProofCopyWithImpl;
@useResult
$Res call({
 String id, String rentRequestId, PaymentProofType type, String value, String photoRef, DateTime? submittedAt, DateTime? createdAt, DateTime? updatedAt
});




}
/// @nodoc
class _$PaymentProofCopyWithImpl<$Res>
    implements $PaymentProofCopyWith<$Res> {
  _$PaymentProofCopyWithImpl(this._self, this._then);

  final PaymentProof _self;
  final $Res Function(PaymentProof) _then;

/// Create a copy of PaymentProof
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? rentRequestId = null,Object? type = null,Object? value = null,Object? photoRef = null,Object? submittedAt = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,rentRequestId: null == rentRequestId ? _self.rentRequestId : rentRequestId // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as PaymentProofType,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String,photoRef: null == photoRef ? _self.photoRef : photoRef // ignore: cast_nullable_to_non_nullable
as String,submittedAt: freezed == submittedAt ? _self.submittedAt : submittedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [PaymentProof].
extension PaymentProofPatterns on PaymentProof {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PaymentProof value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PaymentProof() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PaymentProof value)  $default,){
final _that = this;
switch (_that) {
case _PaymentProof():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PaymentProof value)?  $default,){
final _that = this;
switch (_that) {
case _PaymentProof() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String rentRequestId,  PaymentProofType type,  String value,  String photoRef,  DateTime? submittedAt,  DateTime? createdAt,  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PaymentProof() when $default != null:
return $default(_that.id,_that.rentRequestId,_that.type,_that.value,_that.photoRef,_that.submittedAt,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String rentRequestId,  PaymentProofType type,  String value,  String photoRef,  DateTime? submittedAt,  DateTime? createdAt,  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _PaymentProof():
return $default(_that.id,_that.rentRequestId,_that.type,_that.value,_that.photoRef,_that.submittedAt,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String rentRequestId,  PaymentProofType type,  String value,  String photoRef,  DateTime? submittedAt,  DateTime? createdAt,  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _PaymentProof() when $default != null:
return $default(_that.id,_that.rentRequestId,_that.type,_that.value,_that.photoRef,_that.submittedAt,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc


class _PaymentProof implements PaymentProof {
  const _PaymentProof({required this.id, this.rentRequestId = '', this.type = PaymentProofType.note, this.value = '', this.photoRef = '', this.submittedAt, this.createdAt, this.updatedAt});
  

@override final  String id;
@override@JsonKey() final  String rentRequestId;
@override@JsonKey() final  PaymentProofType type;
@override@JsonKey() final  String value;
@override@JsonKey() final  String photoRef;
@override final  DateTime? submittedAt;
@override final  DateTime? createdAt;
@override final  DateTime? updatedAt;

/// Create a copy of PaymentProof
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PaymentProofCopyWith<_PaymentProof> get copyWith => __$PaymentProofCopyWithImpl<_PaymentProof>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PaymentProof&&(identical(other.id, id) || other.id == id)&&(identical(other.rentRequestId, rentRequestId) || other.rentRequestId == rentRequestId)&&(identical(other.type, type) || other.type == type)&&(identical(other.value, value) || other.value == value)&&(identical(other.photoRef, photoRef) || other.photoRef == photoRef)&&(identical(other.submittedAt, submittedAt) || other.submittedAt == submittedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,rentRequestId,type,value,photoRef,submittedAt,createdAt,updatedAt);

@override
String toString() {
  return 'PaymentProof(id: $id, rentRequestId: $rentRequestId, type: $type, value: $value, photoRef: $photoRef, submittedAt: $submittedAt, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$PaymentProofCopyWith<$Res> implements $PaymentProofCopyWith<$Res> {
  factory _$PaymentProofCopyWith(_PaymentProof value, $Res Function(_PaymentProof) _then) = __$PaymentProofCopyWithImpl;
@override @useResult
$Res call({
 String id, String rentRequestId, PaymentProofType type, String value, String photoRef, DateTime? submittedAt, DateTime? createdAt, DateTime? updatedAt
});




}
/// @nodoc
class __$PaymentProofCopyWithImpl<$Res>
    implements _$PaymentProofCopyWith<$Res> {
  __$PaymentProofCopyWithImpl(this._self, this._then);

  final _PaymentProof _self;
  final $Res Function(_PaymentProof) _then;

/// Create a copy of PaymentProof
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? rentRequestId = null,Object? type = null,Object? value = null,Object? photoRef = null,Object? submittedAt = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_PaymentProof(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,rentRequestId: null == rentRequestId ? _self.rentRequestId : rentRequestId // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as PaymentProofType,value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as String,photoRef: null == photoRef ? _self.photoRef : photoRef // ignore: cast_nullable_to_non_nullable
as String,submittedAt: freezed == submittedAt ? _self.submittedAt : submittedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

/// @nodoc
mixin _$Payment {

 String get id; String get rentRequestId; DateTime? get verifiedAt; String get verifiedBy; String get receiptRef; DateTime? get createdAt; DateTime? get updatedAt;
/// Create a copy of Payment
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PaymentCopyWith<Payment> get copyWith => _$PaymentCopyWithImpl<Payment>(this as Payment, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Payment&&(identical(other.id, id) || other.id == id)&&(identical(other.rentRequestId, rentRequestId) || other.rentRequestId == rentRequestId)&&(identical(other.verifiedAt, verifiedAt) || other.verifiedAt == verifiedAt)&&(identical(other.verifiedBy, verifiedBy) || other.verifiedBy == verifiedBy)&&(identical(other.receiptRef, receiptRef) || other.receiptRef == receiptRef)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,rentRequestId,verifiedAt,verifiedBy,receiptRef,createdAt,updatedAt);

@override
String toString() {
  return 'Payment(id: $id, rentRequestId: $rentRequestId, verifiedAt: $verifiedAt, verifiedBy: $verifiedBy, receiptRef: $receiptRef, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $PaymentCopyWith<$Res>  {
  factory $PaymentCopyWith(Payment value, $Res Function(Payment) _then) = _$PaymentCopyWithImpl;
@useResult
$Res call({
 String id, String rentRequestId, DateTime? verifiedAt, String verifiedBy, String receiptRef, DateTime? createdAt, DateTime? updatedAt
});




}
/// @nodoc
class _$PaymentCopyWithImpl<$Res>
    implements $PaymentCopyWith<$Res> {
  _$PaymentCopyWithImpl(this._self, this._then);

  final Payment _self;
  final $Res Function(Payment) _then;

/// Create a copy of Payment
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? rentRequestId = null,Object? verifiedAt = freezed,Object? verifiedBy = null,Object? receiptRef = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,rentRequestId: null == rentRequestId ? _self.rentRequestId : rentRequestId // ignore: cast_nullable_to_non_nullable
as String,verifiedAt: freezed == verifiedAt ? _self.verifiedAt : verifiedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,verifiedBy: null == verifiedBy ? _self.verifiedBy : verifiedBy // ignore: cast_nullable_to_non_nullable
as String,receiptRef: null == receiptRef ? _self.receiptRef : receiptRef // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [Payment].
extension PaymentPatterns on Payment {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Payment value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Payment() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Payment value)  $default,){
final _that = this;
switch (_that) {
case _Payment():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Payment value)?  $default,){
final _that = this;
switch (_that) {
case _Payment() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String rentRequestId,  DateTime? verifiedAt,  String verifiedBy,  String receiptRef,  DateTime? createdAt,  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Payment() when $default != null:
return $default(_that.id,_that.rentRequestId,_that.verifiedAt,_that.verifiedBy,_that.receiptRef,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String rentRequestId,  DateTime? verifiedAt,  String verifiedBy,  String receiptRef,  DateTime? createdAt,  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _Payment():
return $default(_that.id,_that.rentRequestId,_that.verifiedAt,_that.verifiedBy,_that.receiptRef,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String rentRequestId,  DateTime? verifiedAt,  String verifiedBy,  String receiptRef,  DateTime? createdAt,  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _Payment() when $default != null:
return $default(_that.id,_that.rentRequestId,_that.verifiedAt,_that.verifiedBy,_that.receiptRef,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc


class _Payment implements Payment {
  const _Payment({required this.id, this.rentRequestId = '', this.verifiedAt, this.verifiedBy = '', this.receiptRef = '', this.createdAt, this.updatedAt});
  

@override final  String id;
@override@JsonKey() final  String rentRequestId;
@override final  DateTime? verifiedAt;
@override@JsonKey() final  String verifiedBy;
@override@JsonKey() final  String receiptRef;
@override final  DateTime? createdAt;
@override final  DateTime? updatedAt;

/// Create a copy of Payment
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PaymentCopyWith<_Payment> get copyWith => __$PaymentCopyWithImpl<_Payment>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Payment&&(identical(other.id, id) || other.id == id)&&(identical(other.rentRequestId, rentRequestId) || other.rentRequestId == rentRequestId)&&(identical(other.verifiedAt, verifiedAt) || other.verifiedAt == verifiedAt)&&(identical(other.verifiedBy, verifiedBy) || other.verifiedBy == verifiedBy)&&(identical(other.receiptRef, receiptRef) || other.receiptRef == receiptRef)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,rentRequestId,verifiedAt,verifiedBy,receiptRef,createdAt,updatedAt);

@override
String toString() {
  return 'Payment(id: $id, rentRequestId: $rentRequestId, verifiedAt: $verifiedAt, verifiedBy: $verifiedBy, receiptRef: $receiptRef, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$PaymentCopyWith<$Res> implements $PaymentCopyWith<$Res> {
  factory _$PaymentCopyWith(_Payment value, $Res Function(_Payment) _then) = __$PaymentCopyWithImpl;
@override @useResult
$Res call({
 String id, String rentRequestId, DateTime? verifiedAt, String verifiedBy, String receiptRef, DateTime? createdAt, DateTime? updatedAt
});




}
/// @nodoc
class __$PaymentCopyWithImpl<$Res>
    implements _$PaymentCopyWith<$Res> {
  __$PaymentCopyWithImpl(this._self, this._then);

  final _Payment _self;
  final $Res Function(_Payment) _then;

/// Create a copy of Payment
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? rentRequestId = null,Object? verifiedAt = freezed,Object? verifiedBy = null,Object? receiptRef = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_Payment(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,rentRequestId: null == rentRequestId ? _self.rentRequestId : rentRequestId // ignore: cast_nullable_to_non_nullable
as String,verifiedAt: freezed == verifiedAt ? _self.verifiedAt : verifiedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,verifiedBy: null == verifiedBy ? _self.verifiedBy : verifiedBy // ignore: cast_nullable_to_non_nullable
as String,receiptRef: null == receiptRef ? _self.receiptRef : receiptRef // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
