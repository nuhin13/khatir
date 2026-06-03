// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'portfolio_summary.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$BuildingSummary {

 String get id; String get name; Area? get area; int get totalUnits; int get occupied; int get vacant; int get maintenance; double get totalRent;
/// Create a copy of BuildingSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BuildingSummaryCopyWith<BuildingSummary> get copyWith => _$BuildingSummaryCopyWithImpl<BuildingSummary>(this as BuildingSummary, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BuildingSummary&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.area, area) || other.area == area)&&(identical(other.totalUnits, totalUnits) || other.totalUnits == totalUnits)&&(identical(other.occupied, occupied) || other.occupied == occupied)&&(identical(other.vacant, vacant) || other.vacant == vacant)&&(identical(other.maintenance, maintenance) || other.maintenance == maintenance)&&(identical(other.totalRent, totalRent) || other.totalRent == totalRent));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,area,totalUnits,occupied,vacant,maintenance,totalRent);

@override
String toString() {
  return 'BuildingSummary(id: $id, name: $name, area: $area, totalUnits: $totalUnits, occupied: $occupied, vacant: $vacant, maintenance: $maintenance, totalRent: $totalRent)';
}


}

/// @nodoc
abstract mixin class $BuildingSummaryCopyWith<$Res>  {
  factory $BuildingSummaryCopyWith(BuildingSummary value, $Res Function(BuildingSummary) _then) = _$BuildingSummaryCopyWithImpl;
@useResult
$Res call({
 String id, String name, Area? area, int totalUnits, int occupied, int vacant, int maintenance, double totalRent
});




}
/// @nodoc
class _$BuildingSummaryCopyWithImpl<$Res>
    implements $BuildingSummaryCopyWith<$Res> {
  _$BuildingSummaryCopyWithImpl(this._self, this._then);

  final BuildingSummary _self;
  final $Res Function(BuildingSummary) _then;

/// Create a copy of BuildingSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? area = freezed,Object? totalUnits = null,Object? occupied = null,Object? vacant = null,Object? maintenance = null,Object? totalRent = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,area: freezed == area ? _self.area : area // ignore: cast_nullable_to_non_nullable
as Area?,totalUnits: null == totalUnits ? _self.totalUnits : totalUnits // ignore: cast_nullable_to_non_nullable
as int,occupied: null == occupied ? _self.occupied : occupied // ignore: cast_nullable_to_non_nullable
as int,vacant: null == vacant ? _self.vacant : vacant // ignore: cast_nullable_to_non_nullable
as int,maintenance: null == maintenance ? _self.maintenance : maintenance // ignore: cast_nullable_to_non_nullable
as int,totalRent: null == totalRent ? _self.totalRent : totalRent // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [BuildingSummary].
extension BuildingSummaryPatterns on BuildingSummary {
/// A variant of `map` that fallback to returning `orElse`.
@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BuildingSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BuildingSummary() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BuildingSummary value)  $default,){
final _that = this;
switch (_that) {
case _BuildingSummary():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BuildingSummary value)?  $default,){
final _that = this;
switch (_that) {
case _BuildingSummary() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  Area? area,  int totalUnits,  int occupied,  int vacant,  int maintenance,  double totalRent)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BuildingSummary() when $default != null:
return $default(_that.id,_that.name,_that.area,_that.totalUnits,_that.occupied,_that.vacant,_that.maintenance,_that.totalRent);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  Area? area,  int totalUnits,  int occupied,  int vacant,  int maintenance,  double totalRent)  $default,) {final _that = this;
switch (_that) {
case _BuildingSummary():
return $default(_that.id,_that.name,_that.area,_that.totalUnits,_that.occupied,_that.vacant,_that.maintenance,_that.totalRent);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  Area? area,  int totalUnits,  int occupied,  int vacant,  int maintenance,  double totalRent)?  $default,) {final _that = this;
switch (_that) {
case _BuildingSummary() when $default != null:
return $default(_that.id,_that.name,_that.area,_that.totalUnits,_that.occupied,_that.vacant,_that.maintenance,_that.totalRent);case _:
  return null;

}
}

}

/// @nodoc


class _BuildingSummary implements BuildingSummary {
  const _BuildingSummary({required this.id, required this.name, this.area, this.totalUnits = 0, this.occupied = 0, this.vacant = 0, this.maintenance = 0, this.totalRent = 0});


@override final  String id;
@override final  String name;
@override final  Area? area;
@override@JsonKey() final  int totalUnits;
@override@JsonKey() final  int occupied;
@override@JsonKey() final  int vacant;
@override@JsonKey() final  int maintenance;
@override@JsonKey() final  double totalRent;

/// Create a copy of BuildingSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BuildingSummaryCopyWith<_BuildingSummary> get copyWith => __$BuildingSummaryCopyWithImpl<_BuildingSummary>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _BuildingSummary&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.area, area) || other.area == area)&&(identical(other.totalUnits, totalUnits) || other.totalUnits == totalUnits)&&(identical(other.occupied, occupied) || other.occupied == occupied)&&(identical(other.vacant, vacant) || other.vacant == vacant)&&(identical(other.maintenance, maintenance) || other.maintenance == maintenance)&&(identical(other.totalRent, totalRent) || other.totalRent == totalRent));
}


@override
int get hashCode => Object.hash(runtimeType,id,name,area,totalUnits,occupied,vacant,maintenance,totalRent);

@override
String toString() {
  return 'BuildingSummary(id: $id, name: $name, area: $area, totalUnits: $totalUnits, occupied: $occupied, vacant: $vacant, maintenance: $maintenance, totalRent: $totalRent)';
}


}

/// @nodoc
abstract mixin class _$BuildingSummaryCopyWith<$Res> implements $BuildingSummaryCopyWith<$Res> {
  factory _$BuildingSummaryCopyWith(_BuildingSummary value, $Res Function(_BuildingSummary) _then) = __$BuildingSummaryCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, Area? area, int totalUnits, int occupied, int vacant, int maintenance, double totalRent
});




}
/// @nodoc
class __$BuildingSummaryCopyWithImpl<$Res>
    implements _$BuildingSummaryCopyWith<$Res> {
  __$BuildingSummaryCopyWithImpl(this._self, this._then);

  final _BuildingSummary _self;
  final $Res Function(_BuildingSummary) _then;

/// Create a copy of BuildingSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? area = freezed,Object? totalUnits = null,Object? occupied = null,Object? vacant = null,Object? maintenance = null,Object? totalRent = null,}) {
  return _then(_BuildingSummary(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,area: freezed == area ? _self.area : area // ignore: cast_nullable_to_non_nullable
as Area?,totalUnits: null == totalUnits ? _self.totalUnits : totalUnits // ignore: cast_nullable_to_non_nullable
as int,occupied: null == occupied ? _self.occupied : occupied // ignore: cast_nullable_to_non_nullable
as int,vacant: null == vacant ? _self.vacant : vacant // ignore: cast_nullable_to_non_nullable
as int,maintenance: null == maintenance ? _self.maintenance : maintenance // ignore: cast_nullable_to_non_nullable
as int,totalRent: null == totalRent ? _self.totalRent : totalRent // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc
mixin _$PortfolioTotals {

 int get buildings; int get totalUnits; int get occupied; int get vacant; int get maintenance; double get totalRent;
/// Create a copy of PortfolioTotals
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PortfolioTotalsCopyWith<PortfolioTotals> get copyWith => _$PortfolioTotalsCopyWithImpl<PortfolioTotals>(this as PortfolioTotals, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PortfolioTotals&&(identical(other.buildings, buildings) || other.buildings == buildings)&&(identical(other.totalUnits, totalUnits) || other.totalUnits == totalUnits)&&(identical(other.occupied, occupied) || other.occupied == occupied)&&(identical(other.vacant, vacant) || other.vacant == vacant)&&(identical(other.maintenance, maintenance) || other.maintenance == maintenance)&&(identical(other.totalRent, totalRent) || other.totalRent == totalRent));
}


@override
int get hashCode => Object.hash(runtimeType,buildings,totalUnits,occupied,vacant,maintenance,totalRent);

@override
String toString() {
  return 'PortfolioTotals(buildings: $buildings, totalUnits: $totalUnits, occupied: $occupied, vacant: $vacant, maintenance: $maintenance, totalRent: $totalRent)';
}


}

/// @nodoc
abstract mixin class $PortfolioTotalsCopyWith<$Res>  {
  factory $PortfolioTotalsCopyWith(PortfolioTotals value, $Res Function(PortfolioTotals) _then) = _$PortfolioTotalsCopyWithImpl;
@useResult
$Res call({
 int buildings, int totalUnits, int occupied, int vacant, int maintenance, double totalRent
});




}
/// @nodoc
class _$PortfolioTotalsCopyWithImpl<$Res>
    implements $PortfolioTotalsCopyWith<$Res> {
  _$PortfolioTotalsCopyWithImpl(this._self, this._then);

  final PortfolioTotals _self;
  final $Res Function(PortfolioTotals) _then;

/// Create a copy of PortfolioTotals
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? buildings = null,Object? totalUnits = null,Object? occupied = null,Object? vacant = null,Object? maintenance = null,Object? totalRent = null,}) {
  return _then(_self.copyWith(
buildings: null == buildings ? _self.buildings : buildings // ignore: cast_nullable_to_non_nullable
as int,totalUnits: null == totalUnits ? _self.totalUnits : totalUnits // ignore: cast_nullable_to_non_nullable
as int,occupied: null == occupied ? _self.occupied : occupied // ignore: cast_nullable_to_non_nullable
as int,vacant: null == vacant ? _self.vacant : vacant // ignore: cast_nullable_to_non_nullable
as int,maintenance: null == maintenance ? _self.maintenance : maintenance // ignore: cast_nullable_to_non_nullable
as int,totalRent: null == totalRent ? _self.totalRent : totalRent // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [PortfolioTotals].
extension PortfolioTotalsPatterns on PortfolioTotals {
/// A variant of `map` that fallback to returning `orElse`.
@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PortfolioTotals value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PortfolioTotals() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PortfolioTotals value)  $default,){
final _that = this;
switch (_that) {
case _PortfolioTotals():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PortfolioTotals value)?  $default,){
final _that = this;
switch (_that) {
case _PortfolioTotals() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int buildings,  int totalUnits,  int occupied,  int vacant,  int maintenance,  double totalRent)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PortfolioTotals() when $default != null:
return $default(_that.buildings,_that.totalUnits,_that.occupied,_that.vacant,_that.maintenance,_that.totalRent);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int buildings,  int totalUnits,  int occupied,  int vacant,  int maintenance,  double totalRent)  $default,) {final _that = this;
switch (_that) {
case _PortfolioTotals():
return $default(_that.buildings,_that.totalUnits,_that.occupied,_that.vacant,_that.maintenance,_that.totalRent);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int buildings,  int totalUnits,  int occupied,  int vacant,  int maintenance,  double totalRent)?  $default,) {final _that = this;
switch (_that) {
case _PortfolioTotals() when $default != null:
return $default(_that.buildings,_that.totalUnits,_that.occupied,_that.vacant,_that.maintenance,_that.totalRent);case _:
  return null;

}
}

}

/// @nodoc


class _PortfolioTotals implements PortfolioTotals {
  const _PortfolioTotals({this.buildings = 0, this.totalUnits = 0, this.occupied = 0, this.vacant = 0, this.maintenance = 0, this.totalRent = 0});


@override@JsonKey() final  int buildings;
@override@JsonKey() final  int totalUnits;
@override@JsonKey() final  int occupied;
@override@JsonKey() final  int vacant;
@override@JsonKey() final  int maintenance;
@override@JsonKey() final  double totalRent;

/// Create a copy of PortfolioTotals
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PortfolioTotalsCopyWith<_PortfolioTotals> get copyWith => __$PortfolioTotalsCopyWithImpl<_PortfolioTotals>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PortfolioTotals&&(identical(other.buildings, buildings) || other.buildings == buildings)&&(identical(other.totalUnits, totalUnits) || other.totalUnits == totalUnits)&&(identical(other.occupied, occupied) || other.occupied == occupied)&&(identical(other.vacant, vacant) || other.vacant == vacant)&&(identical(other.maintenance, maintenance) || other.maintenance == maintenance)&&(identical(other.totalRent, totalRent) || other.totalRent == totalRent));
}


@override
int get hashCode => Object.hash(runtimeType,buildings,totalUnits,occupied,vacant,maintenance,totalRent);

@override
String toString() {
  return 'PortfolioTotals(buildings: $buildings, totalUnits: $totalUnits, occupied: $occupied, vacant: $vacant, maintenance: $maintenance, totalRent: $totalRent)';
}


}

/// @nodoc
abstract mixin class _$PortfolioTotalsCopyWith<$Res> implements $PortfolioTotalsCopyWith<$Res> {
  factory _$PortfolioTotalsCopyWith(_PortfolioTotals value, $Res Function(_PortfolioTotals) _then) = __$PortfolioTotalsCopyWithImpl;
@override @useResult
$Res call({
 int buildings, int totalUnits, int occupied, int vacant, int maintenance, double totalRent
});




}
/// @nodoc
class __$PortfolioTotalsCopyWithImpl<$Res>
    implements _$PortfolioTotalsCopyWith<$Res> {
  __$PortfolioTotalsCopyWithImpl(this._self, this._then);

  final _PortfolioTotals _self;
  final $Res Function(_PortfolioTotals) _then;

/// Create a copy of PortfolioTotals
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? buildings = null,Object? totalUnits = null,Object? occupied = null,Object? vacant = null,Object? maintenance = null,Object? totalRent = null,}) {
  return _then(_PortfolioTotals(
buildings: null == buildings ? _self.buildings : buildings // ignore: cast_nullable_to_non_nullable
as int,totalUnits: null == totalUnits ? _self.totalUnits : totalUnits // ignore: cast_nullable_to_non_nullable
as int,occupied: null == occupied ? _self.occupied : occupied // ignore: cast_nullable_to_non_nullable
as int,vacant: null == vacant ? _self.vacant : vacant // ignore: cast_nullable_to_non_nullable
as int,maintenance: null == maintenance ? _self.maintenance : maintenance // ignore: cast_nullable_to_non_nullable
as int,totalRent: null == totalRent ? _self.totalRent : totalRent // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc
mixin _$PortfolioSummary {

 List<BuildingSummary> get buildings; PortfolioTotals get totals;
/// Create a copy of PortfolioSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PortfolioSummaryCopyWith<PortfolioSummary> get copyWith => _$PortfolioSummaryCopyWithImpl<PortfolioSummary>(this as PortfolioSummary, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PortfolioSummary&&const DeepCollectionEquality().equals(other.buildings, buildings)&&(identical(other.totals, totals) || other.totals == totals));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(buildings),totals);

@override
String toString() {
  return 'PortfolioSummary(buildings: $buildings, totals: $totals)';
}


}

/// @nodoc
abstract mixin class $PortfolioSummaryCopyWith<$Res>  {
  factory $PortfolioSummaryCopyWith(PortfolioSummary value, $Res Function(PortfolioSummary) _then) = _$PortfolioSummaryCopyWithImpl;
@useResult
$Res call({
 List<BuildingSummary> buildings, PortfolioTotals totals
});


$PortfolioTotalsCopyWith<$Res> get totals;

}
/// @nodoc
class _$PortfolioSummaryCopyWithImpl<$Res>
    implements $PortfolioSummaryCopyWith<$Res> {
  _$PortfolioSummaryCopyWithImpl(this._self, this._then);

  final PortfolioSummary _self;
  final $Res Function(PortfolioSummary) _then;

/// Create a copy of PortfolioSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? buildings = null,Object? totals = null,}) {
  return _then(_self.copyWith(
buildings: null == buildings ? _self.buildings : buildings // ignore: cast_nullable_to_non_nullable
as List<BuildingSummary>,totals: null == totals ? _self.totals : totals // ignore: cast_nullable_to_non_nullable
as PortfolioTotals,
  ));
}
/// Create a copy of PortfolioSummary
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PortfolioTotalsCopyWith<$Res> get totals {

  return $PortfolioTotalsCopyWith<$Res>(_self.totals, (value) {
    return _then(_self.copyWith(totals: value));
  });
}
}


/// Adds pattern-matching-related methods to [PortfolioSummary].
extension PortfolioSummaryPatterns on PortfolioSummary {
/// A variant of `map` that fallback to returning `orElse`.
@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PortfolioSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PortfolioSummary() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PortfolioSummary value)  $default,){
final _that = this;
switch (_that) {
case _PortfolioSummary():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PortfolioSummary value)?  $default,){
final _that = this;
switch (_that) {
case _PortfolioSummary() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<BuildingSummary> buildings,  PortfolioTotals totals)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PortfolioSummary() when $default != null:
return $default(_that.buildings,_that.totals);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<BuildingSummary> buildings,  PortfolioTotals totals)  $default,) {final _that = this;
switch (_that) {
case _PortfolioSummary():
return $default(_that.buildings,_that.totals);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<BuildingSummary> buildings,  PortfolioTotals totals)?  $default,) {final _that = this;
switch (_that) {
case _PortfolioSummary() when $default != null:
return $default(_that.buildings,_that.totals);case _:
  return null;

}
}

}

/// @nodoc


class _PortfolioSummary implements PortfolioSummary {
  const _PortfolioSummary({final  List<BuildingSummary> buildings = const <BuildingSummary>[], this.totals = const PortfolioTotals()}): _buildings = buildings;


 final  List<BuildingSummary> _buildings;
@override@JsonKey() List<BuildingSummary> get buildings {
  if (_buildings is EqualUnmodifiableListView) return _buildings;
// ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_buildings);
}

@override@JsonKey() final  PortfolioTotals totals;

/// Create a copy of PortfolioSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PortfolioSummaryCopyWith<_PortfolioSummary> get copyWith => __$PortfolioSummaryCopyWithImpl<_PortfolioSummary>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PortfolioSummary&&const DeepCollectionEquality().equals(other._buildings, _buildings)&&(identical(other.totals, totals) || other.totals == totals));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_buildings),totals);

@override
String toString() {
  return 'PortfolioSummary(buildings: $buildings, totals: $totals)';
}


}

/// @nodoc
abstract mixin class _$PortfolioSummaryCopyWith<$Res> implements $PortfolioSummaryCopyWith<$Res> {
  factory _$PortfolioSummaryCopyWith(_PortfolioSummary value, $Res Function(_PortfolioSummary) _then) = __$PortfolioSummaryCopyWithImpl;
@override @useResult
$Res call({
 List<BuildingSummary> buildings, PortfolioTotals totals
});


@override $PortfolioTotalsCopyWith<$Res> get totals;

}
/// @nodoc
class __$PortfolioSummaryCopyWithImpl<$Res>
    implements _$PortfolioSummaryCopyWith<$Res> {
  __$PortfolioSummaryCopyWithImpl(this._self, this._then);

  final _PortfolioSummary _self;
  final $Res Function(_PortfolioSummary) _then;

/// Create a copy of PortfolioSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? buildings = null,Object? totals = null,}) {
  return _then(_PortfolioSummary(
buildings: null == buildings ? _self._buildings : buildings // ignore: cast_nullable_to_non_nullable
as List<BuildingSummary>,totals: null == totals ? _self.totals : totals // ignore: cast_nullable_to_non_nullable
as PortfolioTotals,
  ));
}

/// Create a copy of PortfolioSummary
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PortfolioTotalsCopyWith<$Res> get totals {

  return $PortfolioTotalsCopyWith<$Res>(_self.totals, (value) {
    return _then(_self.copyWith(totals: value));
  });
}
}

// dart format on
