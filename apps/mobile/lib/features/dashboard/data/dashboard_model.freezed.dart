// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'dashboard_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$MonthPoint {

 String get period; double get collected; double get expense;
/// Create a copy of MonthPoint
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$MonthPointCopyWith<MonthPoint> get copyWith => _$MonthPointCopyWithImpl<MonthPoint>(this as MonthPoint, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is MonthPoint&&(identical(other.period, period) || other.period == period)&&(identical(other.collected, collected) || other.collected == collected)&&(identical(other.expense, expense) || other.expense == expense));
}


@override
int get hashCode => Object.hash(runtimeType,period,collected,expense);

@override
String toString() {
  return 'MonthPoint(period: $period, collected: $collected, expense: $expense)';
}


}

/// @nodoc
abstract mixin class $MonthPointCopyWith<$Res>  {
  factory $MonthPointCopyWith(MonthPoint value, $Res Function(MonthPoint) _then) = _$MonthPointCopyWithImpl;
@useResult
$Res call({
 String period, double collected, double expense
});




}
/// @nodoc
class _$MonthPointCopyWithImpl<$Res>
    implements $MonthPointCopyWith<$Res> {
  _$MonthPointCopyWithImpl(this._self, this._then);

  final MonthPoint _self;
  final $Res Function(MonthPoint) _then;

/// Create a copy of MonthPoint
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? period = null,Object? collected = null,Object? expense = null,}) {
  return _then(_self.copyWith(
period: null == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as String,collected: null == collected ? _self.collected : collected // ignore: cast_nullable_to_non_nullable
as double,expense: null == expense ? _self.expense : expense // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [MonthPoint].
extension MonthPointPatterns on MonthPoint {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _MonthPoint value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _MonthPoint() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _MonthPoint value)  $default,){
final _that = this;
switch (_that) {
case _MonthPoint():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _MonthPoint value)?  $default,){
final _that = this;
switch (_that) {
case _MonthPoint() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String period,  double collected,  double expense)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _MonthPoint() when $default != null:
return $default(_that.period,_that.collected,_that.expense);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String period,  double collected,  double expense)  $default,) {final _that = this;
switch (_that) {
case _MonthPoint():
return $default(_that.period,_that.collected,_that.expense);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String period,  double collected,  double expense)?  $default,) {final _that = this;
switch (_that) {
case _MonthPoint() when $default != null:
return $default(_that.period,_that.collected,_that.expense);case _:
  return null;

}
}

}

/// @nodoc


class _MonthPoint implements MonthPoint {
  const _MonthPoint({this.period = '', this.collected = 0, this.expense = 0});
  

@override@JsonKey() final  String period;
@override@JsonKey() final  double collected;
@override@JsonKey() final  double expense;

/// Create a copy of MonthPoint
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$MonthPointCopyWith<_MonthPoint> get copyWith => __$MonthPointCopyWithImpl<_MonthPoint>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _MonthPoint&&(identical(other.period, period) || other.period == period)&&(identical(other.collected, collected) || other.collected == collected)&&(identical(other.expense, expense) || other.expense == expense));
}


@override
int get hashCode => Object.hash(runtimeType,period,collected,expense);

@override
String toString() {
  return 'MonthPoint(period: $period, collected: $collected, expense: $expense)';
}


}

/// @nodoc
abstract mixin class _$MonthPointCopyWith<$Res> implements $MonthPointCopyWith<$Res> {
  factory _$MonthPointCopyWith(_MonthPoint value, $Res Function(_MonthPoint) _then) = __$MonthPointCopyWithImpl;
@override @useResult
$Res call({
 String period, double collected, double expense
});




}
/// @nodoc
class __$MonthPointCopyWithImpl<$Res>
    implements _$MonthPointCopyWith<$Res> {
  __$MonthPointCopyWithImpl(this._self, this._then);

  final _MonthPoint _self;
  final $Res Function(_MonthPoint) _then;

/// Create a copy of MonthPoint
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? period = null,Object? collected = null,Object? expense = null,}) {
  return _then(_MonthPoint(
period: null == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as String,collected: null == collected ? _self.collected : collected // ignore: cast_nullable_to_non_nullable
as double,expense: null == expense ? _self.expense : expense // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc
mixin _$CategoryTotal {

 ExpenseCategory get category; double get amount;
/// Create a copy of CategoryTotal
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CategoryTotalCopyWith<CategoryTotal> get copyWith => _$CategoryTotalCopyWithImpl<CategoryTotal>(this as CategoryTotal, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CategoryTotal&&(identical(other.category, category) || other.category == category)&&(identical(other.amount, amount) || other.amount == amount));
}


@override
int get hashCode => Object.hash(runtimeType,category,amount);

@override
String toString() {
  return 'CategoryTotal(category: $category, amount: $amount)';
}


}

/// @nodoc
abstract mixin class $CategoryTotalCopyWith<$Res>  {
  factory $CategoryTotalCopyWith(CategoryTotal value, $Res Function(CategoryTotal) _then) = _$CategoryTotalCopyWithImpl;
@useResult
$Res call({
 ExpenseCategory category, double amount
});




}
/// @nodoc
class _$CategoryTotalCopyWithImpl<$Res>
    implements $CategoryTotalCopyWith<$Res> {
  _$CategoryTotalCopyWithImpl(this._self, this._then);

  final CategoryTotal _self;
  final $Res Function(CategoryTotal) _then;

/// Create a copy of CategoryTotal
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? category = null,Object? amount = null,}) {
  return _then(_self.copyWith(
category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as ExpenseCategory,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [CategoryTotal].
extension CategoryTotalPatterns on CategoryTotal {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CategoryTotal value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CategoryTotal() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CategoryTotal value)  $default,){
final _that = this;
switch (_that) {
case _CategoryTotal():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CategoryTotal value)?  $default,){
final _that = this;
switch (_that) {
case _CategoryTotal() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ExpenseCategory category,  double amount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CategoryTotal() when $default != null:
return $default(_that.category,_that.amount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ExpenseCategory category,  double amount)  $default,) {final _that = this;
switch (_that) {
case _CategoryTotal():
return $default(_that.category,_that.amount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ExpenseCategory category,  double amount)?  $default,) {final _that = this;
switch (_that) {
case _CategoryTotal() when $default != null:
return $default(_that.category,_that.amount);case _:
  return null;

}
}

}

/// @nodoc


class _CategoryTotal implements CategoryTotal {
  const _CategoryTotal({this.category = ExpenseCategory.other, this.amount = 0});
  

@override@JsonKey() final  ExpenseCategory category;
@override@JsonKey() final  double amount;

/// Create a copy of CategoryTotal
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CategoryTotalCopyWith<_CategoryTotal> get copyWith => __$CategoryTotalCopyWithImpl<_CategoryTotal>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CategoryTotal&&(identical(other.category, category) || other.category == category)&&(identical(other.amount, amount) || other.amount == amount));
}


@override
int get hashCode => Object.hash(runtimeType,category,amount);

@override
String toString() {
  return 'CategoryTotal(category: $category, amount: $amount)';
}


}

/// @nodoc
abstract mixin class _$CategoryTotalCopyWith<$Res> implements $CategoryTotalCopyWith<$Res> {
  factory _$CategoryTotalCopyWith(_CategoryTotal value, $Res Function(_CategoryTotal) _then) = __$CategoryTotalCopyWithImpl;
@override @useResult
$Res call({
 ExpenseCategory category, double amount
});




}
/// @nodoc
class __$CategoryTotalCopyWithImpl<$Res>
    implements _$CategoryTotalCopyWith<$Res> {
  __$CategoryTotalCopyWithImpl(this._self, this._then);

  final _CategoryTotal _self;
  final $Res Function(_CategoryTotal) _then;

/// Create a copy of CategoryTotal
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? category = null,Object? amount = null,}) {
  return _then(_CategoryTotal(
category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as ExpenseCategory,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc
mixin _$DashboardData {

 double get totalCollected; double get totalPending; double get totalOverdue; double get collectionRate; int get occupiedUnits; int get totalUnits; double get occupancyRate; double get totalIncome; double get totalExpense; double get net; int get latePayerCount; List<MonthPoint> get monthlySeries; List<CategoryTotal> get topExpenseCategories;
/// Create a copy of DashboardData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DashboardDataCopyWith<DashboardData> get copyWith => _$DashboardDataCopyWithImpl<DashboardData>(this as DashboardData, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DashboardData&&(identical(other.totalCollected, totalCollected) || other.totalCollected == totalCollected)&&(identical(other.totalPending, totalPending) || other.totalPending == totalPending)&&(identical(other.totalOverdue, totalOverdue) || other.totalOverdue == totalOverdue)&&(identical(other.collectionRate, collectionRate) || other.collectionRate == collectionRate)&&(identical(other.occupiedUnits, occupiedUnits) || other.occupiedUnits == occupiedUnits)&&(identical(other.totalUnits, totalUnits) || other.totalUnits == totalUnits)&&(identical(other.occupancyRate, occupancyRate) || other.occupancyRate == occupancyRate)&&(identical(other.totalIncome, totalIncome) || other.totalIncome == totalIncome)&&(identical(other.totalExpense, totalExpense) || other.totalExpense == totalExpense)&&(identical(other.net, net) || other.net == net)&&(identical(other.latePayerCount, latePayerCount) || other.latePayerCount == latePayerCount)&&const DeepCollectionEquality().equals(other.monthlySeries, monthlySeries)&&const DeepCollectionEquality().equals(other.topExpenseCategories, topExpenseCategories));
}


@override
int get hashCode => Object.hash(runtimeType,totalCollected,totalPending,totalOverdue,collectionRate,occupiedUnits,totalUnits,occupancyRate,totalIncome,totalExpense,net,latePayerCount,const DeepCollectionEquality().hash(monthlySeries),const DeepCollectionEquality().hash(topExpenseCategories));

@override
String toString() {
  return 'DashboardData(totalCollected: $totalCollected, totalPending: $totalPending, totalOverdue: $totalOverdue, collectionRate: $collectionRate, occupiedUnits: $occupiedUnits, totalUnits: $totalUnits, occupancyRate: $occupancyRate, totalIncome: $totalIncome, totalExpense: $totalExpense, net: $net, latePayerCount: $latePayerCount, monthlySeries: $monthlySeries, topExpenseCategories: $topExpenseCategories)';
}


}

/// @nodoc
abstract mixin class $DashboardDataCopyWith<$Res>  {
  factory $DashboardDataCopyWith(DashboardData value, $Res Function(DashboardData) _then) = _$DashboardDataCopyWithImpl;
@useResult
$Res call({
 double totalCollected, double totalPending, double totalOverdue, double collectionRate, int occupiedUnits, int totalUnits, double occupancyRate, double totalIncome, double totalExpense, double net, int latePayerCount, List<MonthPoint> monthlySeries, List<CategoryTotal> topExpenseCategories
});




}
/// @nodoc
class _$DashboardDataCopyWithImpl<$Res>
    implements $DashboardDataCopyWith<$Res> {
  _$DashboardDataCopyWithImpl(this._self, this._then);

  final DashboardData _self;
  final $Res Function(DashboardData) _then;

/// Create a copy of DashboardData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? totalCollected = null,Object? totalPending = null,Object? totalOverdue = null,Object? collectionRate = null,Object? occupiedUnits = null,Object? totalUnits = null,Object? occupancyRate = null,Object? totalIncome = null,Object? totalExpense = null,Object? net = null,Object? latePayerCount = null,Object? monthlySeries = null,Object? topExpenseCategories = null,}) {
  return _then(_self.copyWith(
totalCollected: null == totalCollected ? _self.totalCollected : totalCollected // ignore: cast_nullable_to_non_nullable
as double,totalPending: null == totalPending ? _self.totalPending : totalPending // ignore: cast_nullable_to_non_nullable
as double,totalOverdue: null == totalOverdue ? _self.totalOverdue : totalOverdue // ignore: cast_nullable_to_non_nullable
as double,collectionRate: null == collectionRate ? _self.collectionRate : collectionRate // ignore: cast_nullable_to_non_nullable
as double,occupiedUnits: null == occupiedUnits ? _self.occupiedUnits : occupiedUnits // ignore: cast_nullable_to_non_nullable
as int,totalUnits: null == totalUnits ? _self.totalUnits : totalUnits // ignore: cast_nullable_to_non_nullable
as int,occupancyRate: null == occupancyRate ? _self.occupancyRate : occupancyRate // ignore: cast_nullable_to_non_nullable
as double,totalIncome: null == totalIncome ? _self.totalIncome : totalIncome // ignore: cast_nullable_to_non_nullable
as double,totalExpense: null == totalExpense ? _self.totalExpense : totalExpense // ignore: cast_nullable_to_non_nullable
as double,net: null == net ? _self.net : net // ignore: cast_nullable_to_non_nullable
as double,latePayerCount: null == latePayerCount ? _self.latePayerCount : latePayerCount // ignore: cast_nullable_to_non_nullable
as int,monthlySeries: null == monthlySeries ? _self.monthlySeries : monthlySeries // ignore: cast_nullable_to_non_nullable
as List<MonthPoint>,topExpenseCategories: null == topExpenseCategories ? _self.topExpenseCategories : topExpenseCategories // ignore: cast_nullable_to_non_nullable
as List<CategoryTotal>,
  ));
}

}


/// Adds pattern-matching-related methods to [DashboardData].
extension DashboardDataPatterns on DashboardData {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DashboardData value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DashboardData() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DashboardData value)  $default,){
final _that = this;
switch (_that) {
case _DashboardData():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DashboardData value)?  $default,){
final _that = this;
switch (_that) {
case _DashboardData() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double totalCollected,  double totalPending,  double totalOverdue,  double collectionRate,  int occupiedUnits,  int totalUnits,  double occupancyRate,  double totalIncome,  double totalExpense,  double net,  int latePayerCount,  List<MonthPoint> monthlySeries,  List<CategoryTotal> topExpenseCategories)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DashboardData() when $default != null:
return $default(_that.totalCollected,_that.totalPending,_that.totalOverdue,_that.collectionRate,_that.occupiedUnits,_that.totalUnits,_that.occupancyRate,_that.totalIncome,_that.totalExpense,_that.net,_that.latePayerCount,_that.monthlySeries,_that.topExpenseCategories);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double totalCollected,  double totalPending,  double totalOverdue,  double collectionRate,  int occupiedUnits,  int totalUnits,  double occupancyRate,  double totalIncome,  double totalExpense,  double net,  int latePayerCount,  List<MonthPoint> monthlySeries,  List<CategoryTotal> topExpenseCategories)  $default,) {final _that = this;
switch (_that) {
case _DashboardData():
return $default(_that.totalCollected,_that.totalPending,_that.totalOverdue,_that.collectionRate,_that.occupiedUnits,_that.totalUnits,_that.occupancyRate,_that.totalIncome,_that.totalExpense,_that.net,_that.latePayerCount,_that.monthlySeries,_that.topExpenseCategories);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double totalCollected,  double totalPending,  double totalOverdue,  double collectionRate,  int occupiedUnits,  int totalUnits,  double occupancyRate,  double totalIncome,  double totalExpense,  double net,  int latePayerCount,  List<MonthPoint> monthlySeries,  List<CategoryTotal> topExpenseCategories)?  $default,) {final _that = this;
switch (_that) {
case _DashboardData() when $default != null:
return $default(_that.totalCollected,_that.totalPending,_that.totalOverdue,_that.collectionRate,_that.occupiedUnits,_that.totalUnits,_that.occupancyRate,_that.totalIncome,_that.totalExpense,_that.net,_that.latePayerCount,_that.monthlySeries,_that.topExpenseCategories);case _:
  return null;

}
}

}

/// @nodoc


class _DashboardData implements DashboardData {
  const _DashboardData({this.totalCollected = 0, this.totalPending = 0, this.totalOverdue = 0, this.collectionRate = 0, this.occupiedUnits = 0, this.totalUnits = 0, this.occupancyRate = 0, this.totalIncome = 0, this.totalExpense = 0, this.net = 0, this.latePayerCount = 0, final  List<MonthPoint> monthlySeries = const <MonthPoint>[], final  List<CategoryTotal> topExpenseCategories = const <CategoryTotal>[]}): _monthlySeries = monthlySeries,_topExpenseCategories = topExpenseCategories;
  

@override@JsonKey() final  double totalCollected;
@override@JsonKey() final  double totalPending;
@override@JsonKey() final  double totalOverdue;
@override@JsonKey() final  double collectionRate;
@override@JsonKey() final  int occupiedUnits;
@override@JsonKey() final  int totalUnits;
@override@JsonKey() final  double occupancyRate;
@override@JsonKey() final  double totalIncome;
@override@JsonKey() final  double totalExpense;
@override@JsonKey() final  double net;
@override@JsonKey() final  int latePayerCount;
 final  List<MonthPoint> _monthlySeries;
@override@JsonKey() List<MonthPoint> get monthlySeries {
  if (_monthlySeries is EqualUnmodifiableListView) return _monthlySeries;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_monthlySeries);
}

 final  List<CategoryTotal> _topExpenseCategories;
@override@JsonKey() List<CategoryTotal> get topExpenseCategories {
  if (_topExpenseCategories is EqualUnmodifiableListView) return _topExpenseCategories;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_topExpenseCategories);
}


/// Create a copy of DashboardData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DashboardDataCopyWith<_DashboardData> get copyWith => __$DashboardDataCopyWithImpl<_DashboardData>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DashboardData&&(identical(other.totalCollected, totalCollected) || other.totalCollected == totalCollected)&&(identical(other.totalPending, totalPending) || other.totalPending == totalPending)&&(identical(other.totalOverdue, totalOverdue) || other.totalOverdue == totalOverdue)&&(identical(other.collectionRate, collectionRate) || other.collectionRate == collectionRate)&&(identical(other.occupiedUnits, occupiedUnits) || other.occupiedUnits == occupiedUnits)&&(identical(other.totalUnits, totalUnits) || other.totalUnits == totalUnits)&&(identical(other.occupancyRate, occupancyRate) || other.occupancyRate == occupancyRate)&&(identical(other.totalIncome, totalIncome) || other.totalIncome == totalIncome)&&(identical(other.totalExpense, totalExpense) || other.totalExpense == totalExpense)&&(identical(other.net, net) || other.net == net)&&(identical(other.latePayerCount, latePayerCount) || other.latePayerCount == latePayerCount)&&const DeepCollectionEquality().equals(other._monthlySeries, _monthlySeries)&&const DeepCollectionEquality().equals(other._topExpenseCategories, _topExpenseCategories));
}


@override
int get hashCode => Object.hash(runtimeType,totalCollected,totalPending,totalOverdue,collectionRate,occupiedUnits,totalUnits,occupancyRate,totalIncome,totalExpense,net,latePayerCount,const DeepCollectionEquality().hash(_monthlySeries),const DeepCollectionEquality().hash(_topExpenseCategories));

@override
String toString() {
  return 'DashboardData(totalCollected: $totalCollected, totalPending: $totalPending, totalOverdue: $totalOverdue, collectionRate: $collectionRate, occupiedUnits: $occupiedUnits, totalUnits: $totalUnits, occupancyRate: $occupancyRate, totalIncome: $totalIncome, totalExpense: $totalExpense, net: $net, latePayerCount: $latePayerCount, monthlySeries: $monthlySeries, topExpenseCategories: $topExpenseCategories)';
}


}

/// @nodoc
abstract mixin class _$DashboardDataCopyWith<$Res> implements $DashboardDataCopyWith<$Res> {
  factory _$DashboardDataCopyWith(_DashboardData value, $Res Function(_DashboardData) _then) = __$DashboardDataCopyWithImpl;
@override @useResult
$Res call({
 double totalCollected, double totalPending, double totalOverdue, double collectionRate, int occupiedUnits, int totalUnits, double occupancyRate, double totalIncome, double totalExpense, double net, int latePayerCount, List<MonthPoint> monthlySeries, List<CategoryTotal> topExpenseCategories
});




}
/// @nodoc
class __$DashboardDataCopyWithImpl<$Res>
    implements _$DashboardDataCopyWith<$Res> {
  __$DashboardDataCopyWithImpl(this._self, this._then);

  final _DashboardData _self;
  final $Res Function(_DashboardData) _then;

/// Create a copy of DashboardData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? totalCollected = null,Object? totalPending = null,Object? totalOverdue = null,Object? collectionRate = null,Object? occupiedUnits = null,Object? totalUnits = null,Object? occupancyRate = null,Object? totalIncome = null,Object? totalExpense = null,Object? net = null,Object? latePayerCount = null,Object? monthlySeries = null,Object? topExpenseCategories = null,}) {
  return _then(_DashboardData(
totalCollected: null == totalCollected ? _self.totalCollected : totalCollected // ignore: cast_nullable_to_non_nullable
as double,totalPending: null == totalPending ? _self.totalPending : totalPending // ignore: cast_nullable_to_non_nullable
as double,totalOverdue: null == totalOverdue ? _self.totalOverdue : totalOverdue // ignore: cast_nullable_to_non_nullable
as double,collectionRate: null == collectionRate ? _self.collectionRate : collectionRate // ignore: cast_nullable_to_non_nullable
as double,occupiedUnits: null == occupiedUnits ? _self.occupiedUnits : occupiedUnits // ignore: cast_nullable_to_non_nullable
as int,totalUnits: null == totalUnits ? _self.totalUnits : totalUnits // ignore: cast_nullable_to_non_nullable
as int,occupancyRate: null == occupancyRate ? _self.occupancyRate : occupancyRate // ignore: cast_nullable_to_non_nullable
as double,totalIncome: null == totalIncome ? _self.totalIncome : totalIncome // ignore: cast_nullable_to_non_nullable
as double,totalExpense: null == totalExpense ? _self.totalExpense : totalExpense // ignore: cast_nullable_to_non_nullable
as double,net: null == net ? _self.net : net // ignore: cast_nullable_to_non_nullable
as double,latePayerCount: null == latePayerCount ? _self.latePayerCount : latePayerCount // ignore: cast_nullable_to_non_nullable
as int,monthlySeries: null == monthlySeries ? _self._monthlySeries : monthlySeries // ignore: cast_nullable_to_non_nullable
as List<MonthPoint>,topExpenseCategories: null == topExpenseCategories ? _self._topExpenseCategories : topExpenseCategories // ignore: cast_nullable_to_non_nullable
as List<CategoryTotal>,
  ));
}


}

// dart format on
