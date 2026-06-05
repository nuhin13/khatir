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
mixin _$Lease {

 String get id; String get unitId; String get tenantId; String get landlordId; DateTime? get startDate; DateTime? get endDate; double get rent; double get advance; LeaseStatus get status; String get signedPdfRef; DateTime? get createdAt; DateTime? get updatedAt;
/// Create a copy of Lease
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LeaseCopyWith<Lease> get copyWith => _$LeaseCopyWithImpl<Lease>(this as Lease, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Lease&&(identical(other.id, id) || other.id == id)&&(identical(other.unitId, unitId) || other.unitId == unitId)&&(identical(other.tenantId, tenantId) || other.tenantId == tenantId)&&(identical(other.landlordId, landlordId) || other.landlordId == landlordId)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.rent, rent) || other.rent == rent)&&(identical(other.advance, advance) || other.advance == advance)&&(identical(other.status, status) || other.status == status)&&(identical(other.signedPdfRef, signedPdfRef) || other.signedPdfRef == signedPdfRef)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,unitId,tenantId,landlordId,startDate,endDate,rent,advance,status,signedPdfRef,createdAt,updatedAt);

@override
String toString() {
  return 'Lease(id: $id, unitId: $unitId, tenantId: $tenantId, landlordId: $landlordId, startDate: $startDate, endDate: $endDate, rent: $rent, advance: $advance, status: $status, signedPdfRef: $signedPdfRef, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $LeaseCopyWith<$Res>  {
  factory $LeaseCopyWith(Lease value, $Res Function(Lease) _then) = _$LeaseCopyWithImpl;
@useResult
$Res call({
 String id, String unitId, String tenantId, String landlordId, DateTime? startDate, DateTime? endDate, double rent, double advance, LeaseStatus status, String signedPdfRef, DateTime? createdAt, DateTime? updatedAt
});




}
/// @nodoc
class _$LeaseCopyWithImpl<$Res>
    implements $LeaseCopyWith<$Res> {
  _$LeaseCopyWithImpl(this._self, this._then);

  final Lease _self;
  final $Res Function(Lease) _then;

/// Create a copy of Lease
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? unitId = null,Object? tenantId = null,Object? landlordId = null,Object? startDate = freezed,Object? endDate = freezed,Object? rent = null,Object? advance = null,Object? status = null,Object? signedPdfRef = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,unitId: null == unitId ? _self.unitId : unitId // ignore: cast_nullable_to_non_nullable
as String,tenantId: null == tenantId ? _self.tenantId : tenantId // ignore: cast_nullable_to_non_nullable
as String,landlordId: null == landlordId ? _self.landlordId : landlordId // ignore: cast_nullable_to_non_nullable
as String,startDate: freezed == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime?,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime?,rent: null == rent ? _self.rent : rent // ignore: cast_nullable_to_non_nullable
as double,advance: null == advance ? _self.advance : advance // ignore: cast_nullable_to_non_nullable
as double,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as LeaseStatus,signedPdfRef: null == signedPdfRef ? _self.signedPdfRef : signedPdfRef // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [Lease].
extension LeasePatterns on Lease {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Lease value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Lease() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Lease value)  $default,){
final _that = this;
switch (_that) {
case _Lease():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Lease value)?  $default,){
final _that = this;
switch (_that) {
case _Lease() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String unitId,  String tenantId,  String landlordId,  DateTime? startDate,  DateTime? endDate,  double rent,  double advance,  LeaseStatus status,  String signedPdfRef,  DateTime? createdAt,  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Lease() when $default != null:
return $default(_that.id,_that.unitId,_that.tenantId,_that.landlordId,_that.startDate,_that.endDate,_that.rent,_that.advance,_that.status,_that.signedPdfRef,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String unitId,  String tenantId,  String landlordId,  DateTime? startDate,  DateTime? endDate,  double rent,  double advance,  LeaseStatus status,  String signedPdfRef,  DateTime? createdAt,  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _Lease():
return $default(_that.id,_that.unitId,_that.tenantId,_that.landlordId,_that.startDate,_that.endDate,_that.rent,_that.advance,_that.status,_that.signedPdfRef,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String unitId,  String tenantId,  String landlordId,  DateTime? startDate,  DateTime? endDate,  double rent,  double advance,  LeaseStatus status,  String signedPdfRef,  DateTime? createdAt,  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _Lease() when $default != null:
return $default(_that.id,_that.unitId,_that.tenantId,_that.landlordId,_that.startDate,_that.endDate,_that.rent,_that.advance,_that.status,_that.signedPdfRef,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc


class _Lease implements Lease {
  const _Lease({required this.id, this.unitId = '', this.tenantId = '', this.landlordId = '', this.startDate, this.endDate, this.rent = 0, this.advance = 0, this.status = LeaseStatus.draft, this.signedPdfRef = '', this.createdAt, this.updatedAt});
  

@override final  String id;
@override@JsonKey() final  String unitId;
@override@JsonKey() final  String tenantId;
@override@JsonKey() final  String landlordId;
@override final  DateTime? startDate;
@override final  DateTime? endDate;
@override@JsonKey() final  double rent;
@override@JsonKey() final  double advance;
@override@JsonKey() final  LeaseStatus status;
@override@JsonKey() final  String signedPdfRef;
@override final  DateTime? createdAt;
@override final  DateTime? updatedAt;

/// Create a copy of Lease
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LeaseCopyWith<_Lease> get copyWith => __$LeaseCopyWithImpl<_Lease>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Lease&&(identical(other.id, id) || other.id == id)&&(identical(other.unitId, unitId) || other.unitId == unitId)&&(identical(other.tenantId, tenantId) || other.tenantId == tenantId)&&(identical(other.landlordId, landlordId) || other.landlordId == landlordId)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.rent, rent) || other.rent == rent)&&(identical(other.advance, advance) || other.advance == advance)&&(identical(other.status, status) || other.status == status)&&(identical(other.signedPdfRef, signedPdfRef) || other.signedPdfRef == signedPdfRef)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,unitId,tenantId,landlordId,startDate,endDate,rent,advance,status,signedPdfRef,createdAt,updatedAt);

@override
String toString() {
  return 'Lease(id: $id, unitId: $unitId, tenantId: $tenantId, landlordId: $landlordId, startDate: $startDate, endDate: $endDate, rent: $rent, advance: $advance, status: $status, signedPdfRef: $signedPdfRef, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$LeaseCopyWith<$Res> implements $LeaseCopyWith<$Res> {
  factory _$LeaseCopyWith(_Lease value, $Res Function(_Lease) _then) = __$LeaseCopyWithImpl;
@override @useResult
$Res call({
 String id, String unitId, String tenantId, String landlordId, DateTime? startDate, DateTime? endDate, double rent, double advance, LeaseStatus status, String signedPdfRef, DateTime? createdAt, DateTime? updatedAt
});




}
/// @nodoc
class __$LeaseCopyWithImpl<$Res>
    implements _$LeaseCopyWith<$Res> {
  __$LeaseCopyWithImpl(this._self, this._then);

  final _Lease _self;
  final $Res Function(_Lease) _then;

/// Create a copy of Lease
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? unitId = null,Object? tenantId = null,Object? landlordId = null,Object? startDate = freezed,Object? endDate = freezed,Object? rent = null,Object? advance = null,Object? status = null,Object? signedPdfRef = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_Lease(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,unitId: null == unitId ? _self.unitId : unitId // ignore: cast_nullable_to_non_nullable
as String,tenantId: null == tenantId ? _self.tenantId : tenantId // ignore: cast_nullable_to_non_nullable
as String,landlordId: null == landlordId ? _self.landlordId : landlordId // ignore: cast_nullable_to_non_nullable
as String,startDate: freezed == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime?,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as DateTime?,rent: null == rent ? _self.rent : rent // ignore: cast_nullable_to_non_nullable
as double,advance: null == advance ? _self.advance : advance // ignore: cast_nullable_to_non_nullable
as double,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as LeaseStatus,signedPdfRef: null == signedPdfRef ? _self.signedPdfRef : signedPdfRef // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

/// @nodoc
mixin _$RentSchedule {

 String get id; String get leaseId; String get period; int get dueDay; DateTime? get dueDate; double get amount; RentScheduleStatus get status; DateTime? get sentAt; DateTime? get createdAt; DateTime? get updatedAt;
/// Create a copy of RentSchedule
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RentScheduleCopyWith<RentSchedule> get copyWith => _$RentScheduleCopyWithImpl<RentSchedule>(this as RentSchedule, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RentSchedule&&(identical(other.id, id) || other.id == id)&&(identical(other.leaseId, leaseId) || other.leaseId == leaseId)&&(identical(other.period, period) || other.period == period)&&(identical(other.dueDay, dueDay) || other.dueDay == dueDay)&&(identical(other.dueDate, dueDate) || other.dueDate == dueDate)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.status, status) || other.status == status)&&(identical(other.sentAt, sentAt) || other.sentAt == sentAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,leaseId,period,dueDay,dueDate,amount,status,sentAt,createdAt,updatedAt);

@override
String toString() {
  return 'RentSchedule(id: $id, leaseId: $leaseId, period: $period, dueDay: $dueDay, dueDate: $dueDate, amount: $amount, status: $status, sentAt: $sentAt, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $RentScheduleCopyWith<$Res>  {
  factory $RentScheduleCopyWith(RentSchedule value, $Res Function(RentSchedule) _then) = _$RentScheduleCopyWithImpl;
@useResult
$Res call({
 String id, String leaseId, String period, int dueDay, DateTime? dueDate, double amount, RentScheduleStatus status, DateTime? sentAt, DateTime? createdAt, DateTime? updatedAt
});




}
/// @nodoc
class _$RentScheduleCopyWithImpl<$Res>
    implements $RentScheduleCopyWith<$Res> {
  _$RentScheduleCopyWithImpl(this._self, this._then);

  final RentSchedule _self;
  final $Res Function(RentSchedule) _then;

/// Create a copy of RentSchedule
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? leaseId = null,Object? period = null,Object? dueDay = null,Object? dueDate = freezed,Object? amount = null,Object? status = null,Object? sentAt = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,leaseId: null == leaseId ? _self.leaseId : leaseId // ignore: cast_nullable_to_non_nullable
as String,period: null == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as String,dueDay: null == dueDay ? _self.dueDay : dueDay // ignore: cast_nullable_to_non_nullable
as int,dueDate: freezed == dueDate ? _self.dueDate : dueDate // ignore: cast_nullable_to_non_nullable
as DateTime?,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as RentScheduleStatus,sentAt: freezed == sentAt ? _self.sentAt : sentAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [RentSchedule].
extension RentSchedulePatterns on RentSchedule {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RentSchedule value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RentSchedule() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RentSchedule value)  $default,){
final _that = this;
switch (_that) {
case _RentSchedule():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RentSchedule value)?  $default,){
final _that = this;
switch (_that) {
case _RentSchedule() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String leaseId,  String period,  int dueDay,  DateTime? dueDate,  double amount,  RentScheduleStatus status,  DateTime? sentAt,  DateTime? createdAt,  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RentSchedule() when $default != null:
return $default(_that.id,_that.leaseId,_that.period,_that.dueDay,_that.dueDate,_that.amount,_that.status,_that.sentAt,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String leaseId,  String period,  int dueDay,  DateTime? dueDate,  double amount,  RentScheduleStatus status,  DateTime? sentAt,  DateTime? createdAt,  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _RentSchedule():
return $default(_that.id,_that.leaseId,_that.period,_that.dueDay,_that.dueDate,_that.amount,_that.status,_that.sentAt,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String leaseId,  String period,  int dueDay,  DateTime? dueDate,  double amount,  RentScheduleStatus status,  DateTime? sentAt,  DateTime? createdAt,  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _RentSchedule() when $default != null:
return $default(_that.id,_that.leaseId,_that.period,_that.dueDay,_that.dueDate,_that.amount,_that.status,_that.sentAt,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc


class _RentSchedule implements RentSchedule {
  const _RentSchedule({required this.id, this.leaseId = '', this.period = '', this.dueDay = 0, this.dueDate, this.amount = 0, this.status = RentScheduleStatus.pending, this.sentAt, this.createdAt, this.updatedAt});
  

@override final  String id;
@override@JsonKey() final  String leaseId;
@override@JsonKey() final  String period;
@override@JsonKey() final  int dueDay;
@override final  DateTime? dueDate;
@override@JsonKey() final  double amount;
@override@JsonKey() final  RentScheduleStatus status;
@override final  DateTime? sentAt;
@override final  DateTime? createdAt;
@override final  DateTime? updatedAt;

/// Create a copy of RentSchedule
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RentScheduleCopyWith<_RentSchedule> get copyWith => __$RentScheduleCopyWithImpl<_RentSchedule>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RentSchedule&&(identical(other.id, id) || other.id == id)&&(identical(other.leaseId, leaseId) || other.leaseId == leaseId)&&(identical(other.period, period) || other.period == period)&&(identical(other.dueDay, dueDay) || other.dueDay == dueDay)&&(identical(other.dueDate, dueDate) || other.dueDate == dueDate)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.status, status) || other.status == status)&&(identical(other.sentAt, sentAt) || other.sentAt == sentAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,leaseId,period,dueDay,dueDate,amount,status,sentAt,createdAt,updatedAt);

@override
String toString() {
  return 'RentSchedule(id: $id, leaseId: $leaseId, period: $period, dueDay: $dueDay, dueDate: $dueDate, amount: $amount, status: $status, sentAt: $sentAt, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$RentScheduleCopyWith<$Res> implements $RentScheduleCopyWith<$Res> {
  factory _$RentScheduleCopyWith(_RentSchedule value, $Res Function(_RentSchedule) _then) = __$RentScheduleCopyWithImpl;
@override @useResult
$Res call({
 String id, String leaseId, String period, int dueDay, DateTime? dueDate, double amount, RentScheduleStatus status, DateTime? sentAt, DateTime? createdAt, DateTime? updatedAt
});




}
/// @nodoc
class __$RentScheduleCopyWithImpl<$Res>
    implements _$RentScheduleCopyWith<$Res> {
  __$RentScheduleCopyWithImpl(this._self, this._then);

  final _RentSchedule _self;
  final $Res Function(_RentSchedule) _then;

/// Create a copy of RentSchedule
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? leaseId = null,Object? period = null,Object? dueDay = null,Object? dueDate = freezed,Object? amount = null,Object? status = null,Object? sentAt = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_RentSchedule(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,leaseId: null == leaseId ? _self.leaseId : leaseId // ignore: cast_nullable_to_non_nullable
as String,period: null == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as String,dueDay: null == dueDay ? _self.dueDay : dueDay // ignore: cast_nullable_to_non_nullable
as int,dueDate: freezed == dueDate ? _self.dueDate : dueDate // ignore: cast_nullable_to_non_nullable
as DateTime?,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as RentScheduleStatus,sentAt: freezed == sentAt ? _self.sentAt : sentAt // ignore: cast_nullable_to_non_nullable
as DateTime?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

/// @nodoc
mixin _$LeaseTenantSummary {

 String get id; String get name; String get nidNumberMasked; VerificationStatus get verificationStatus;
/// Create a copy of LeaseTenantSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LeaseTenantSummaryCopyWith<LeaseTenantSummary> get copyWith => _$LeaseTenantSummaryCopyWithImpl<LeaseTenantSummary>(this as LeaseTenantSummary, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LeaseTenantSummary&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.nidNumberMasked, nidNumberMasked) || other.nidNumberMasked == nidNumberMasked)&&(identical(other.verificationStatus, verificationStatus) || other.verificationStatus == verificationStatus));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,nidNumberMasked,verificationStatus);

@override
String toString() {
  return 'LeaseTenantSummary(id: $id, name: $name, nidNumberMasked: $nidNumberMasked, verificationStatus: $verificationStatus)';
}


}

/// @nodoc
abstract mixin class $LeaseTenantSummaryCopyWith<$Res>  {
  factory $LeaseTenantSummaryCopyWith(LeaseTenantSummary value, $Res Function(LeaseTenantSummary) _then) = _$LeaseTenantSummaryCopyWithImpl;
@useResult
$Res call({
 String id, String name, String nidNumberMasked, VerificationStatus verificationStatus
});




}
/// @nodoc
class _$LeaseTenantSummaryCopyWithImpl<$Res>
    implements $LeaseTenantSummaryCopyWith<$Res> {
  _$LeaseTenantSummaryCopyWithImpl(this._self, this._then);

  final LeaseTenantSummary _self;
  final $Res Function(LeaseTenantSummary) _then;

/// Create a copy of LeaseTenantSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? nidNumberMasked = null,Object? verificationStatus = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,nidNumberMasked: null == nidNumberMasked ? _self.nidNumberMasked : nidNumberMasked // ignore: cast_nullable_to_non_nullable
as String,verificationStatus: null == verificationStatus ? _self.verificationStatus : verificationStatus // ignore: cast_nullable_to_non_nullable
as VerificationStatus,
  ));
}

}


/// Adds pattern-matching-related methods to [LeaseTenantSummary].
extension LeaseTenantSummaryPatterns on LeaseTenantSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LeaseTenantSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LeaseTenantSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LeaseTenantSummary value)  $default,){
final _that = this;
switch (_that) {
case _LeaseTenantSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LeaseTenantSummary value)?  $default,){
final _that = this;
switch (_that) {
case _LeaseTenantSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String nidNumberMasked,  VerificationStatus verificationStatus)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LeaseTenantSummary() when $default != null:
return $default(_that.id,_that.name,_that.nidNumberMasked,_that.verificationStatus);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String nidNumberMasked,  VerificationStatus verificationStatus)  $default,) {final _that = this;
switch (_that) {
case _LeaseTenantSummary():
return $default(_that.id,_that.name,_that.nidNumberMasked,_that.verificationStatus);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String nidNumberMasked,  VerificationStatus verificationStatus)?  $default,) {final _that = this;
switch (_that) {
case _LeaseTenantSummary() when $default != null:
return $default(_that.id,_that.name,_that.nidNumberMasked,_that.verificationStatus);case _:
  return null;

}
}

}

/// @nodoc


class _LeaseTenantSummary implements LeaseTenantSummary {
  const _LeaseTenantSummary({required this.id, this.name = '', this.nidNumberMasked = '', this.verificationStatus = VerificationStatus.unverified});
  

@override final  String id;
@override@JsonKey() final  String name;
@override@JsonKey() final  String nidNumberMasked;
@override@JsonKey() final  VerificationStatus verificationStatus;

/// Create a copy of LeaseTenantSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LeaseTenantSummaryCopyWith<_LeaseTenantSummary> get copyWith => __$LeaseTenantSummaryCopyWithImpl<_LeaseTenantSummary>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LeaseTenantSummary&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.nidNumberMasked, nidNumberMasked) || other.nidNumberMasked == nidNumberMasked)&&(identical(other.verificationStatus, verificationStatus) || other.verificationStatus == verificationStatus));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,nidNumberMasked,verificationStatus);

@override
String toString() {
  return 'LeaseTenantSummary(id: $id, name: $name, nidNumberMasked: $nidNumberMasked, verificationStatus: $verificationStatus)';
}


}

/// @nodoc
abstract mixin class _$LeaseTenantSummaryCopyWith<$Res> implements $LeaseTenantSummaryCopyWith<$Res> {
  factory _$LeaseTenantSummaryCopyWith(_LeaseTenantSummary value, $Res Function(_LeaseTenantSummary) _then) = __$LeaseTenantSummaryCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String nidNumberMasked, VerificationStatus verificationStatus
});




}
/// @nodoc
class __$LeaseTenantSummaryCopyWithImpl<$Res>
    implements _$LeaseTenantSummaryCopyWith<$Res> {
  __$LeaseTenantSummaryCopyWithImpl(this._self, this._then);

  final _LeaseTenantSummary _self;
  final $Res Function(_LeaseTenantSummary) _then;

/// Create a copy of LeaseTenantSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? nidNumberMasked = null,Object? verificationStatus = null,}) {
  return _then(_LeaseTenantSummary(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,nidNumberMasked: null == nidNumberMasked ? _self.nidNumberMasked : nidNumberMasked // ignore: cast_nullable_to_non_nullable
as String,verificationStatus: null == verificationStatus ? _self.verificationStatus : verificationStatus // ignore: cast_nullable_to_non_nullable
as VerificationStatus,
  ));
}


}

/// @nodoc
mixin _$UnitLease {

 Lease get lease; LeaseTenantSummary? get tenant;
/// Create a copy of UnitLease
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$UnitLeaseCopyWith<UnitLease> get copyWith => _$UnitLeaseCopyWithImpl<UnitLease>(this as UnitLease, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is UnitLease&&(identical(other.lease, lease) || other.lease == lease)&&(identical(other.tenant, tenant) || other.tenant == tenant));
}


@override
int get hashCode => Object.hash(runtimeType,lease,tenant);

@override
String toString() {
  return 'UnitLease(lease: $lease, tenant: $tenant)';
}


}

/// @nodoc
abstract mixin class $UnitLeaseCopyWith<$Res>  {
  factory $UnitLeaseCopyWith(UnitLease value, $Res Function(UnitLease) _then) = _$UnitLeaseCopyWithImpl;
@useResult
$Res call({
 Lease lease, LeaseTenantSummary? tenant
});


$LeaseCopyWith<$Res> get lease;$LeaseTenantSummaryCopyWith<$Res>? get tenant;

}
/// @nodoc
class _$UnitLeaseCopyWithImpl<$Res>
    implements $UnitLeaseCopyWith<$Res> {
  _$UnitLeaseCopyWithImpl(this._self, this._then);

  final UnitLease _self;
  final $Res Function(UnitLease) _then;

/// Create a copy of UnitLease
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? lease = null,Object? tenant = freezed,}) {
  return _then(_self.copyWith(
lease: null == lease ? _self.lease : lease // ignore: cast_nullable_to_non_nullable
as Lease,tenant: freezed == tenant ? _self.tenant : tenant // ignore: cast_nullable_to_non_nullable
as LeaseTenantSummary?,
  ));
}
/// Create a copy of UnitLease
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LeaseCopyWith<$Res> get lease {
  
  return $LeaseCopyWith<$Res>(_self.lease, (value) {
    return _then(_self.copyWith(lease: value));
  });
}/// Create a copy of UnitLease
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LeaseTenantSummaryCopyWith<$Res>? get tenant {
    if (_self.tenant == null) {
    return null;
  }

  return $LeaseTenantSummaryCopyWith<$Res>(_self.tenant!, (value) {
    return _then(_self.copyWith(tenant: value));
  });
}
}


/// Adds pattern-matching-related methods to [UnitLease].
extension UnitLeasePatterns on UnitLease {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _UnitLease value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _UnitLease() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _UnitLease value)  $default,){
final _that = this;
switch (_that) {
case _UnitLease():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _UnitLease value)?  $default,){
final _that = this;
switch (_that) {
case _UnitLease() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Lease lease,  LeaseTenantSummary? tenant)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _UnitLease() when $default != null:
return $default(_that.lease,_that.tenant);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Lease lease,  LeaseTenantSummary? tenant)  $default,) {final _that = this;
switch (_that) {
case _UnitLease():
return $default(_that.lease,_that.tenant);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Lease lease,  LeaseTenantSummary? tenant)?  $default,) {final _that = this;
switch (_that) {
case _UnitLease() when $default != null:
return $default(_that.lease,_that.tenant);case _:
  return null;

}
}

}

/// @nodoc


class _UnitLease implements UnitLease {
  const _UnitLease({required this.lease, this.tenant});
  

@override final  Lease lease;
@override final  LeaseTenantSummary? tenant;

/// Create a copy of UnitLease
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$UnitLeaseCopyWith<_UnitLease> get copyWith => __$UnitLeaseCopyWithImpl<_UnitLease>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _UnitLease&&(identical(other.lease, lease) || other.lease == lease)&&(identical(other.tenant, tenant) || other.tenant == tenant));
}


@override
int get hashCode => Object.hash(runtimeType,lease,tenant);

@override
String toString() {
  return 'UnitLease(lease: $lease, tenant: $tenant)';
}


}

/// @nodoc
abstract mixin class _$UnitLeaseCopyWith<$Res> implements $UnitLeaseCopyWith<$Res> {
  factory _$UnitLeaseCopyWith(_UnitLease value, $Res Function(_UnitLease) _then) = __$UnitLeaseCopyWithImpl;
@override @useResult
$Res call({
 Lease lease, LeaseTenantSummary? tenant
});


@override $LeaseCopyWith<$Res> get lease;@override $LeaseTenantSummaryCopyWith<$Res>? get tenant;

}
/// @nodoc
class __$UnitLeaseCopyWithImpl<$Res>
    implements _$UnitLeaseCopyWith<$Res> {
  __$UnitLeaseCopyWithImpl(this._self, this._then);

  final _UnitLease _self;
  final $Res Function(_UnitLease) _then;

/// Create a copy of UnitLease
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? lease = null,Object? tenant = freezed,}) {
  return _then(_UnitLease(
lease: null == lease ? _self.lease : lease // ignore: cast_nullable_to_non_nullable
as Lease,tenant: freezed == tenant ? _self.tenant : tenant // ignore: cast_nullable_to_non_nullable
as LeaseTenantSummary?,
  ));
}

/// Create a copy of UnitLease
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LeaseCopyWith<$Res> get lease {
  
  return $LeaseCopyWith<$Res>(_self.lease, (value) {
    return _then(_self.copyWith(lease: value));
  });
}/// Create a copy of UnitLease
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$LeaseTenantSummaryCopyWith<$Res>? get tenant {
    if (_self.tenant == null) {
    return null;
  }

  return $LeaseTenantSummaryCopyWith<$Res>(_self.tenant!, (value) {
    return _then(_self.copyWith(tenant: value));
  });
}
}

// dart format on
