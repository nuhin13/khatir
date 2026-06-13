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
mixin _$MaintenanceRequest {

 String get id; String get unitId; String get leaseId; MaintenanceCategory get category; String get description; String get photoRef; MaintenanceStatus get status; DateTime? get resolvedAt; double? get resolutionCost; String get resolutionNote; DateTime? get createdAt; DateTime? get updatedAt;
/// Create a copy of MaintenanceRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MaintenanceRequestCopyWith<MaintenanceRequest> get copyWith => _$MaintenanceRequestCopyWithImpl<MaintenanceRequest>(this as MaintenanceRequest, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MaintenanceRequest&&(identical(other.id, id) || other.id == id)&&(identical(other.unitId, unitId) || other.unitId == unitId)&&(identical(other.leaseId, leaseId) || other.leaseId == leaseId)&&(identical(other.category, category) || other.category == category)&&(identical(other.description, description) || other.description == description)&&(identical(other.photoRef, photoRef) || other.photoRef == photoRef)&&(identical(other.status, status) || other.status == status)&&(identical(other.resolvedAt, resolvedAt) || other.resolvedAt == resolvedAt)&&(identical(other.resolutionCost, resolutionCost) || other.resolutionCost == resolutionCost)&&(identical(other.resolutionNote, resolutionNote) || other.resolutionNote == resolutionNote)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,unitId,leaseId,category,description,photoRef,status,resolvedAt,resolutionCost,resolutionNote,createdAt,updatedAt);

@override
String toString() {
  return 'MaintenanceRequest(id: $id, unitId: $unitId, leaseId: $leaseId, category: $category, description: $description, photoRef: $photoRef, status: $status, resolvedAt: $resolvedAt, resolutionCost: $resolutionCost, resolutionNote: $resolutionNote, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $MaintenanceRequestCopyWith<$Res>  {
  factory $MaintenanceRequestCopyWith(MaintenanceRequest value, $Res Function(MaintenanceRequest) _then) = _$MaintenanceRequestCopyWithImpl;
@useResult
$Res call({
 String id, String unitId, String leaseId, MaintenanceCategory category, String description, String photoRef, MaintenanceStatus status, DateTime? resolvedAt, double? resolutionCost, String resolutionNote, DateTime? createdAt, DateTime? updatedAt
});




}
/// @nodoc
class _$MaintenanceRequestCopyWithImpl<$Res>
    implements $MaintenanceRequestCopyWith<$Res> {
  _$MaintenanceRequestCopyWithImpl(this._self, this._then);

  final MaintenanceRequest _self;
  final $Res Function(MaintenanceRequest) _then;

/// Create a copy of MaintenanceRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? unitId = null,Object? leaseId = null,Object? category = null,Object? description = null,Object? photoRef = null,Object? status = null,Object? resolvedAt = freezed,Object? resolutionCost = freezed,Object? resolutionNote = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,unitId: null == unitId ? _self.unitId : unitId // ignore: cast_nullable_to_non_nullable
as String,leaseId: null == leaseId ? _self.leaseId : leaseId // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as MaintenanceCategory,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,photoRef: null == photoRef ? _self.photoRef : photoRef // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as MaintenanceStatus,resolvedAt: freezed == resolvedAt ? _self.resolvedAt : resolvedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,resolutionCost: freezed == resolutionCost ? _self.resolutionCost : resolutionCost // ignore: cast_nullable_to_non_nullable
as double?,resolutionNote: null == resolutionNote ? _self.resolutionNote : resolutionNote // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [MaintenanceRequest].
extension MaintenanceRequestPatterns on MaintenanceRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MaintenanceRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MaintenanceRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MaintenanceRequest value)  $default,){
final _that = this;
switch (_that) {
case _MaintenanceRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MaintenanceRequest value)?  $default,){
final _that = this;
switch (_that) {
case _MaintenanceRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String unitId,  String leaseId,  MaintenanceCategory category,  String description,  String photoRef,  MaintenanceStatus status,  DateTime? resolvedAt,  double? resolutionCost,  String resolutionNote,  DateTime? createdAt,  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MaintenanceRequest() when $default != null:
return $default(_that.id,_that.unitId,_that.leaseId,_that.category,_that.description,_that.photoRef,_that.status,_that.resolvedAt,_that.resolutionCost,_that.resolutionNote,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String unitId,  String leaseId,  MaintenanceCategory category,  String description,  String photoRef,  MaintenanceStatus status,  DateTime? resolvedAt,  double? resolutionCost,  String resolutionNote,  DateTime? createdAt,  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _MaintenanceRequest():
return $default(_that.id,_that.unitId,_that.leaseId,_that.category,_that.description,_that.photoRef,_that.status,_that.resolvedAt,_that.resolutionCost,_that.resolutionNote,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String unitId,  String leaseId,  MaintenanceCategory category,  String description,  String photoRef,  MaintenanceStatus status,  DateTime? resolvedAt,  double? resolutionCost,  String resolutionNote,  DateTime? createdAt,  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _MaintenanceRequest() when $default != null:
return $default(_that.id,_that.unitId,_that.leaseId,_that.category,_that.description,_that.photoRef,_that.status,_that.resolvedAt,_that.resolutionCost,_that.resolutionNote,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc


class _MaintenanceRequest implements MaintenanceRequest {
  const _MaintenanceRequest({required this.id, this.unitId = '', this.leaseId = '', this.category = MaintenanceCategory.other, this.description = '', this.photoRef = '', this.status = MaintenanceStatus.open, this.resolvedAt, this.resolutionCost, this.resolutionNote = '', this.createdAt, this.updatedAt});
  

@override final  String id;
@override@JsonKey() final  String unitId;
@override@JsonKey() final  String leaseId;
@override@JsonKey() final  MaintenanceCategory category;
@override@JsonKey() final  String description;
@override@JsonKey() final  String photoRef;
@override@JsonKey() final  MaintenanceStatus status;
@override final  DateTime? resolvedAt;
@override final  double? resolutionCost;
@override@JsonKey() final  String resolutionNote;
@override final  DateTime? createdAt;
@override final  DateTime? updatedAt;

/// Create a copy of MaintenanceRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MaintenanceRequestCopyWith<_MaintenanceRequest> get copyWith => __$MaintenanceRequestCopyWithImpl<_MaintenanceRequest>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MaintenanceRequest&&(identical(other.id, id) || other.id == id)&&(identical(other.unitId, unitId) || other.unitId == unitId)&&(identical(other.leaseId, leaseId) || other.leaseId == leaseId)&&(identical(other.category, category) || other.category == category)&&(identical(other.description, description) || other.description == description)&&(identical(other.photoRef, photoRef) || other.photoRef == photoRef)&&(identical(other.status, status) || other.status == status)&&(identical(other.resolvedAt, resolvedAt) || other.resolvedAt == resolvedAt)&&(identical(other.resolutionCost, resolutionCost) || other.resolutionCost == resolutionCost)&&(identical(other.resolutionNote, resolutionNote) || other.resolutionNote == resolutionNote)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,unitId,leaseId,category,description,photoRef,status,resolvedAt,resolutionCost,resolutionNote,createdAt,updatedAt);

@override
String toString() {
  return 'MaintenanceRequest(id: $id, unitId: $unitId, leaseId: $leaseId, category: $category, description: $description, photoRef: $photoRef, status: $status, resolvedAt: $resolvedAt, resolutionCost: $resolutionCost, resolutionNote: $resolutionNote, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$MaintenanceRequestCopyWith<$Res> implements $MaintenanceRequestCopyWith<$Res> {
  factory _$MaintenanceRequestCopyWith(_MaintenanceRequest value, $Res Function(_MaintenanceRequest) _then) = __$MaintenanceRequestCopyWithImpl;
@override @useResult
$Res call({
 String id, String unitId, String leaseId, MaintenanceCategory category, String description, String photoRef, MaintenanceStatus status, DateTime? resolvedAt, double? resolutionCost, String resolutionNote, DateTime? createdAt, DateTime? updatedAt
});




}
/// @nodoc
class __$MaintenanceRequestCopyWithImpl<$Res>
    implements _$MaintenanceRequestCopyWith<$Res> {
  __$MaintenanceRequestCopyWithImpl(this._self, this._then);

  final _MaintenanceRequest _self;
  final $Res Function(_MaintenanceRequest) _then;

/// Create a copy of MaintenanceRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? unitId = null,Object? leaseId = null,Object? category = null,Object? description = null,Object? photoRef = null,Object? status = null,Object? resolvedAt = freezed,Object? resolutionCost = freezed,Object? resolutionNote = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_MaintenanceRequest(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,unitId: null == unitId ? _self.unitId : unitId // ignore: cast_nullable_to_non_nullable
as String,leaseId: null == leaseId ? _self.leaseId : leaseId // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as MaintenanceCategory,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,photoRef: null == photoRef ? _self.photoRef : photoRef // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as MaintenanceStatus,resolvedAt: freezed == resolvedAt ? _self.resolvedAt : resolvedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,resolutionCost: freezed == resolutionCost ? _self.resolutionCost : resolutionCost // ignore: cast_nullable_to_non_nullable
as double?,resolutionNote: null == resolutionNote ? _self.resolutionNote : resolutionNote // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

/// @nodoc
mixin _$Expense {

 String get id; String get unitId; String get requestId; ExpenseCategory get category; double get amount; DateTime? get date; ExpenseSource get source; String get note; String get receiptRef; DateTime? get createdAt; DateTime? get updatedAt;
/// Create a copy of Expense
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExpenseCopyWith<Expense> get copyWith => _$ExpenseCopyWithImpl<Expense>(this as Expense, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Expense&&(identical(other.id, id) || other.id == id)&&(identical(other.unitId, unitId) || other.unitId == unitId)&&(identical(other.requestId, requestId) || other.requestId == requestId)&&(identical(other.category, category) || other.category == category)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.date, date) || other.date == date)&&(identical(other.source, source) || other.source == source)&&(identical(other.note, note) || other.note == note)&&(identical(other.receiptRef, receiptRef) || other.receiptRef == receiptRef)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,unitId,requestId,category,amount,date,source,note,receiptRef,createdAt,updatedAt);

@override
String toString() {
  return 'Expense(id: $id, unitId: $unitId, requestId: $requestId, category: $category, amount: $amount, date: $date, source: $source, note: $note, receiptRef: $receiptRef, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $ExpenseCopyWith<$Res>  {
  factory $ExpenseCopyWith(Expense value, $Res Function(Expense) _then) = _$ExpenseCopyWithImpl;
@useResult
$Res call({
 String id, String unitId, String requestId, ExpenseCategory category, double amount, DateTime? date, ExpenseSource source, String note, String receiptRef, DateTime? createdAt, DateTime? updatedAt
});




}
/// @nodoc
class _$ExpenseCopyWithImpl<$Res>
    implements $ExpenseCopyWith<$Res> {
  _$ExpenseCopyWithImpl(this._self, this._then);

  final Expense _self;
  final $Res Function(Expense) _then;

/// Create a copy of Expense
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? unitId = null,Object? requestId = null,Object? category = null,Object? amount = null,Object? date = freezed,Object? source = null,Object? note = null,Object? receiptRef = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,unitId: null == unitId ? _self.unitId : unitId // ignore: cast_nullable_to_non_nullable
as String,requestId: null == requestId ? _self.requestId : requestId // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as ExpenseCategory,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,date: freezed == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime?,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as ExpenseSource,note: null == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String,receiptRef: null == receiptRef ? _self.receiptRef : receiptRef // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [Expense].
extension ExpensePatterns on Expense {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Expense value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Expense() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Expense value)  $default,){
final _that = this;
switch (_that) {
case _Expense():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Expense value)?  $default,){
final _that = this;
switch (_that) {
case _Expense() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String unitId,  String requestId,  ExpenseCategory category,  double amount,  DateTime? date,  ExpenseSource source,  String note,  String receiptRef,  DateTime? createdAt,  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Expense() when $default != null:
return $default(_that.id,_that.unitId,_that.requestId,_that.category,_that.amount,_that.date,_that.source,_that.note,_that.receiptRef,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String unitId,  String requestId,  ExpenseCategory category,  double amount,  DateTime? date,  ExpenseSource source,  String note,  String receiptRef,  DateTime? createdAt,  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _Expense():
return $default(_that.id,_that.unitId,_that.requestId,_that.category,_that.amount,_that.date,_that.source,_that.note,_that.receiptRef,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String unitId,  String requestId,  ExpenseCategory category,  double amount,  DateTime? date,  ExpenseSource source,  String note,  String receiptRef,  DateTime? createdAt,  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _Expense() when $default != null:
return $default(_that.id,_that.unitId,_that.requestId,_that.category,_that.amount,_that.date,_that.source,_that.note,_that.receiptRef,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc


class _Expense implements Expense {
  const _Expense({required this.id, this.unitId = '', this.requestId = '', this.category = ExpenseCategory.other, this.amount = 0, this.date, this.source = ExpenseSource.manual, this.note = '', this.receiptRef = '', this.createdAt, this.updatedAt});
  

@override final  String id;
@override@JsonKey() final  String unitId;
@override@JsonKey() final  String requestId;
@override@JsonKey() final  ExpenseCategory category;
@override@JsonKey() final  double amount;
@override final  DateTime? date;
@override@JsonKey() final  ExpenseSource source;
@override@JsonKey() final  String note;
@override@JsonKey() final  String receiptRef;
@override final  DateTime? createdAt;
@override final  DateTime? updatedAt;

/// Create a copy of Expense
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ExpenseCopyWith<_Expense> get copyWith => __$ExpenseCopyWithImpl<_Expense>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Expense&&(identical(other.id, id) || other.id == id)&&(identical(other.unitId, unitId) || other.unitId == unitId)&&(identical(other.requestId, requestId) || other.requestId == requestId)&&(identical(other.category, category) || other.category == category)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.date, date) || other.date == date)&&(identical(other.source, source) || other.source == source)&&(identical(other.note, note) || other.note == note)&&(identical(other.receiptRef, receiptRef) || other.receiptRef == receiptRef)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,unitId,requestId,category,amount,date,source,note,receiptRef,createdAt,updatedAt);

@override
String toString() {
  return 'Expense(id: $id, unitId: $unitId, requestId: $requestId, category: $category, amount: $amount, date: $date, source: $source, note: $note, receiptRef: $receiptRef, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$ExpenseCopyWith<$Res> implements $ExpenseCopyWith<$Res> {
  factory _$ExpenseCopyWith(_Expense value, $Res Function(_Expense) _then) = __$ExpenseCopyWithImpl;
@override @useResult
$Res call({
 String id, String unitId, String requestId, ExpenseCategory category, double amount, DateTime? date, ExpenseSource source, String note, String receiptRef, DateTime? createdAt, DateTime? updatedAt
});




}
/// @nodoc
class __$ExpenseCopyWithImpl<$Res>
    implements _$ExpenseCopyWith<$Res> {
  __$ExpenseCopyWithImpl(this._self, this._then);

  final _Expense _self;
  final $Res Function(_Expense) _then;

/// Create a copy of Expense
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? unitId = null,Object? requestId = null,Object? category = null,Object? amount = null,Object? date = freezed,Object? source = null,Object? note = null,Object? receiptRef = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_Expense(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,unitId: null == unitId ? _self.unitId : unitId // ignore: cast_nullable_to_non_nullable
as String,requestId: null == requestId ? _self.requestId : requestId // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as ExpenseCategory,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,date: freezed == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime?,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as ExpenseSource,note: null == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String,receiptRef: null == receiptRef ? _self.receiptRef : receiptRef // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

/// @nodoc
mixin _$ExpenseCategoryTotal {

 ExpenseCategory get category; double get total;
/// Create a copy of ExpenseCategoryTotal
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExpenseCategoryTotalCopyWith<ExpenseCategoryTotal> get copyWith => _$ExpenseCategoryTotalCopyWithImpl<ExpenseCategoryTotal>(this as ExpenseCategoryTotal, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExpenseCategoryTotal&&(identical(other.category, category) || other.category == category)&&(identical(other.total, total) || other.total == total));
}


@override
int get hashCode => Object.hash(runtimeType,category,total);

@override
String toString() {
  return 'ExpenseCategoryTotal(category: $category, total: $total)';
}


}

/// @nodoc
abstract mixin class $ExpenseCategoryTotalCopyWith<$Res>  {
  factory $ExpenseCategoryTotalCopyWith(ExpenseCategoryTotal value, $Res Function(ExpenseCategoryTotal) _then) = _$ExpenseCategoryTotalCopyWithImpl;
@useResult
$Res call({
 ExpenseCategory category, double total
});




}
/// @nodoc
class _$ExpenseCategoryTotalCopyWithImpl<$Res>
    implements $ExpenseCategoryTotalCopyWith<$Res> {
  _$ExpenseCategoryTotalCopyWithImpl(this._self, this._then);

  final ExpenseCategoryTotal _self;
  final $Res Function(ExpenseCategoryTotal) _then;

/// Create a copy of ExpenseCategoryTotal
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? category = null,Object? total = null,}) {
  return _then(_self.copyWith(
category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as ExpenseCategory,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [ExpenseCategoryTotal].
extension ExpenseCategoryTotalPatterns on ExpenseCategoryTotal {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ExpenseCategoryTotal value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ExpenseCategoryTotal() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ExpenseCategoryTotal value)  $default,){
final _that = this;
switch (_that) {
case _ExpenseCategoryTotal():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ExpenseCategoryTotal value)?  $default,){
final _that = this;
switch (_that) {
case _ExpenseCategoryTotal() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ExpenseCategory category,  double total)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ExpenseCategoryTotal() when $default != null:
return $default(_that.category,_that.total);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ExpenseCategory category,  double total)  $default,) {final _that = this;
switch (_that) {
case _ExpenseCategoryTotal():
return $default(_that.category,_that.total);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ExpenseCategory category,  double total)?  $default,) {final _that = this;
switch (_that) {
case _ExpenseCategoryTotal() when $default != null:
return $default(_that.category,_that.total);case _:
  return null;

}
}

}

/// @nodoc


class _ExpenseCategoryTotal implements ExpenseCategoryTotal {
  const _ExpenseCategoryTotal({this.category = ExpenseCategory.other, this.total = 0});
  

@override@JsonKey() final  ExpenseCategory category;
@override@JsonKey() final  double total;

/// Create a copy of ExpenseCategoryTotal
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ExpenseCategoryTotalCopyWith<_ExpenseCategoryTotal> get copyWith => __$ExpenseCategoryTotalCopyWithImpl<_ExpenseCategoryTotal>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ExpenseCategoryTotal&&(identical(other.category, category) || other.category == category)&&(identical(other.total, total) || other.total == total));
}


@override
int get hashCode => Object.hash(runtimeType,category,total);

@override
String toString() {
  return 'ExpenseCategoryTotal(category: $category, total: $total)';
}


}

/// @nodoc
abstract mixin class _$ExpenseCategoryTotalCopyWith<$Res> implements $ExpenseCategoryTotalCopyWith<$Res> {
  factory _$ExpenseCategoryTotalCopyWith(_ExpenseCategoryTotal value, $Res Function(_ExpenseCategoryTotal) _then) = __$ExpenseCategoryTotalCopyWithImpl;
@override @useResult
$Res call({
 ExpenseCategory category, double total
});




}
/// @nodoc
class __$ExpenseCategoryTotalCopyWithImpl<$Res>
    implements _$ExpenseCategoryTotalCopyWith<$Res> {
  __$ExpenseCategoryTotalCopyWithImpl(this._self, this._then);

  final _ExpenseCategoryTotal _self;
  final $Res Function(_ExpenseCategoryTotal) _then;

/// Create a copy of ExpenseCategoryTotal
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? category = null,Object? total = null,}) {
  return _then(_ExpenseCategoryTotal(
category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as ExpenseCategory,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc
mixin _$ExpenseMonthTotal {

 DateTime? get month; double get total;
/// Create a copy of ExpenseMonthTotal
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExpenseMonthTotalCopyWith<ExpenseMonthTotal> get copyWith => _$ExpenseMonthTotalCopyWithImpl<ExpenseMonthTotal>(this as ExpenseMonthTotal, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExpenseMonthTotal&&(identical(other.month, month) || other.month == month)&&(identical(other.total, total) || other.total == total));
}


@override
int get hashCode => Object.hash(runtimeType,month,total);

@override
String toString() {
  return 'ExpenseMonthTotal(month: $month, total: $total)';
}


}

/// @nodoc
abstract mixin class $ExpenseMonthTotalCopyWith<$Res>  {
  factory $ExpenseMonthTotalCopyWith(ExpenseMonthTotal value, $Res Function(ExpenseMonthTotal) _then) = _$ExpenseMonthTotalCopyWithImpl;
@useResult
$Res call({
 DateTime? month, double total
});




}
/// @nodoc
class _$ExpenseMonthTotalCopyWithImpl<$Res>
    implements $ExpenseMonthTotalCopyWith<$Res> {
  _$ExpenseMonthTotalCopyWithImpl(this._self, this._then);

  final ExpenseMonthTotal _self;
  final $Res Function(ExpenseMonthTotal) _then;

/// Create a copy of ExpenseMonthTotal
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? month = freezed,Object? total = null,}) {
  return _then(_self.copyWith(
month: freezed == month ? _self.month : month // ignore: cast_nullable_to_non_nullable
as DateTime?,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [ExpenseMonthTotal].
extension ExpenseMonthTotalPatterns on ExpenseMonthTotal {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ExpenseMonthTotal value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ExpenseMonthTotal() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ExpenseMonthTotal value)  $default,){
final _that = this;
switch (_that) {
case _ExpenseMonthTotal():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ExpenseMonthTotal value)?  $default,){
final _that = this;
switch (_that) {
case _ExpenseMonthTotal() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime? month,  double total)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ExpenseMonthTotal() when $default != null:
return $default(_that.month,_that.total);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime? month,  double total)  $default,) {final _that = this;
switch (_that) {
case _ExpenseMonthTotal():
return $default(_that.month,_that.total);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime? month,  double total)?  $default,) {final _that = this;
switch (_that) {
case _ExpenseMonthTotal() when $default != null:
return $default(_that.month,_that.total);case _:
  return null;

}
}

}

/// @nodoc


class _ExpenseMonthTotal implements ExpenseMonthTotal {
  const _ExpenseMonthTotal({this.month, this.total = 0});
  

@override final  DateTime? month;
@override@JsonKey() final  double total;

/// Create a copy of ExpenseMonthTotal
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ExpenseMonthTotalCopyWith<_ExpenseMonthTotal> get copyWith => __$ExpenseMonthTotalCopyWithImpl<_ExpenseMonthTotal>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ExpenseMonthTotal&&(identical(other.month, month) || other.month == month)&&(identical(other.total, total) || other.total == total));
}


@override
int get hashCode => Object.hash(runtimeType,month,total);

@override
String toString() {
  return 'ExpenseMonthTotal(month: $month, total: $total)';
}


}

/// @nodoc
abstract mixin class _$ExpenseMonthTotalCopyWith<$Res> implements $ExpenseMonthTotalCopyWith<$Res> {
  factory _$ExpenseMonthTotalCopyWith(_ExpenseMonthTotal value, $Res Function(_ExpenseMonthTotal) _then) = __$ExpenseMonthTotalCopyWithImpl;
@override @useResult
$Res call({
 DateTime? month, double total
});




}
/// @nodoc
class __$ExpenseMonthTotalCopyWithImpl<$Res>
    implements _$ExpenseMonthTotalCopyWith<$Res> {
  __$ExpenseMonthTotalCopyWithImpl(this._self, this._then);

  final _ExpenseMonthTotal _self;
  final $Res Function(_ExpenseMonthTotal) _then;

/// Create a copy of ExpenseMonthTotal
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? month = freezed,Object? total = null,}) {
  return _then(_ExpenseMonthTotal(
month: freezed == month ? _self.month : month // ignore: cast_nullable_to_non_nullable
as DateTime?,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc
mixin _$ExpenseSummary {

 List<ExpenseCategoryTotal> get byCategory; List<ExpenseMonthTotal> get byMonth;
/// Create a copy of ExpenseSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExpenseSummaryCopyWith<ExpenseSummary> get copyWith => _$ExpenseSummaryCopyWithImpl<ExpenseSummary>(this as ExpenseSummary, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExpenseSummary&&const DeepCollectionEquality().equals(other.byCategory, byCategory)&&const DeepCollectionEquality().equals(other.byMonth, byMonth));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(byCategory),const DeepCollectionEquality().hash(byMonth));

@override
String toString() {
  return 'ExpenseSummary(byCategory: $byCategory, byMonth: $byMonth)';
}


}

/// @nodoc
abstract mixin class $ExpenseSummaryCopyWith<$Res>  {
  factory $ExpenseSummaryCopyWith(ExpenseSummary value, $Res Function(ExpenseSummary) _then) = _$ExpenseSummaryCopyWithImpl;
@useResult
$Res call({
 List<ExpenseCategoryTotal> byCategory, List<ExpenseMonthTotal> byMonth
});




}
/// @nodoc
class _$ExpenseSummaryCopyWithImpl<$Res>
    implements $ExpenseSummaryCopyWith<$Res> {
  _$ExpenseSummaryCopyWithImpl(this._self, this._then);

  final ExpenseSummary _self;
  final $Res Function(ExpenseSummary) _then;

/// Create a copy of ExpenseSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? byCategory = null,Object? byMonth = null,}) {
  return _then(_self.copyWith(
byCategory: null == byCategory ? _self.byCategory : byCategory // ignore: cast_nullable_to_non_nullable
as List<ExpenseCategoryTotal>,byMonth: null == byMonth ? _self.byMonth : byMonth // ignore: cast_nullable_to_non_nullable
as List<ExpenseMonthTotal>,
  ));
}

}


/// Adds pattern-matching-related methods to [ExpenseSummary].
extension ExpenseSummaryPatterns on ExpenseSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ExpenseSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ExpenseSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ExpenseSummary value)  $default,){
final _that = this;
switch (_that) {
case _ExpenseSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ExpenseSummary value)?  $default,){
final _that = this;
switch (_that) {
case _ExpenseSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<ExpenseCategoryTotal> byCategory,  List<ExpenseMonthTotal> byMonth)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ExpenseSummary() when $default != null:
return $default(_that.byCategory,_that.byMonth);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<ExpenseCategoryTotal> byCategory,  List<ExpenseMonthTotal> byMonth)  $default,) {final _that = this;
switch (_that) {
case _ExpenseSummary():
return $default(_that.byCategory,_that.byMonth);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<ExpenseCategoryTotal> byCategory,  List<ExpenseMonthTotal> byMonth)?  $default,) {final _that = this;
switch (_that) {
case _ExpenseSummary() when $default != null:
return $default(_that.byCategory,_that.byMonth);case _:
  return null;

}
}

}

/// @nodoc


class _ExpenseSummary implements ExpenseSummary {
  const _ExpenseSummary({final  List<ExpenseCategoryTotal> byCategory = const <ExpenseCategoryTotal>[], final  List<ExpenseMonthTotal> byMonth = const <ExpenseMonthTotal>[]}): _byCategory = byCategory,_byMonth = byMonth;
  

 final  List<ExpenseCategoryTotal> _byCategory;
@override@JsonKey() List<ExpenseCategoryTotal> get byCategory {
  if (_byCategory is EqualUnmodifiableListView) return _byCategory;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_byCategory);
}

 final  List<ExpenseMonthTotal> _byMonth;
@override@JsonKey() List<ExpenseMonthTotal> get byMonth {
  if (_byMonth is EqualUnmodifiableListView) return _byMonth;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_byMonth);
}


/// Create a copy of ExpenseSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ExpenseSummaryCopyWith<_ExpenseSummary> get copyWith => __$ExpenseSummaryCopyWithImpl<_ExpenseSummary>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ExpenseSummary&&const DeepCollectionEquality().equals(other._byCategory, _byCategory)&&const DeepCollectionEquality().equals(other._byMonth, _byMonth));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_byCategory),const DeepCollectionEquality().hash(_byMonth));

@override
String toString() {
  return 'ExpenseSummary(byCategory: $byCategory, byMonth: $byMonth)';
}


}

/// @nodoc
abstract mixin class _$ExpenseSummaryCopyWith<$Res> implements $ExpenseSummaryCopyWith<$Res> {
  factory _$ExpenseSummaryCopyWith(_ExpenseSummary value, $Res Function(_ExpenseSummary) _then) = __$ExpenseSummaryCopyWithImpl;
@override @useResult
$Res call({
 List<ExpenseCategoryTotal> byCategory, List<ExpenseMonthTotal> byMonth
});




}
/// @nodoc
class __$ExpenseSummaryCopyWithImpl<$Res>
    implements _$ExpenseSummaryCopyWith<$Res> {
  __$ExpenseSummaryCopyWithImpl(this._self, this._then);

  final _ExpenseSummary _self;
  final $Res Function(_ExpenseSummary) _then;

/// Create a copy of ExpenseSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? byCategory = null,Object? byMonth = null,}) {
  return _then(_ExpenseSummary(
byCategory: null == byCategory ? _self._byCategory : byCategory // ignore: cast_nullable_to_non_nullable
as List<ExpenseCategoryTotal>,byMonth: null == byMonth ? _self._byMonth : byMonth // ignore: cast_nullable_to_non_nullable
as List<ExpenseMonthTotal>,
  ));
}


}

// dart format on
