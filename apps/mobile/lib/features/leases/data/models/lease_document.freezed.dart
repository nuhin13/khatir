// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'lease_document.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$LeaseDocumentClause {

 String get id; String get title; String get content; bool get isRequired; int get sortOrder;
/// Create a copy of LeaseDocumentClause
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LeaseDocumentClauseCopyWith<LeaseDocumentClause> get copyWith => _$LeaseDocumentClauseCopyWithImpl<LeaseDocumentClause>(this as LeaseDocumentClause, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LeaseDocumentClause&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.content, content) || other.content == content)&&(identical(other.isRequired, isRequired) || other.isRequired == isRequired)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder));
}


@override
int get hashCode => Object.hash(runtimeType,id,title,content,isRequired,sortOrder);

@override
String toString() {
  return 'LeaseDocumentClause(id: $id, title: $title, content: $content, isRequired: $isRequired, sortOrder: $sortOrder)';
}


}

/// @nodoc
abstract mixin class $LeaseDocumentClauseCopyWith<$Res>  {
  factory $LeaseDocumentClauseCopyWith(LeaseDocumentClause value, $Res Function(LeaseDocumentClause) _then) = _$LeaseDocumentClauseCopyWithImpl;
@useResult
$Res call({
 String id, String title, String content, bool isRequired, int sortOrder
});




}
/// @nodoc
class _$LeaseDocumentClauseCopyWithImpl<$Res>
    implements $LeaseDocumentClauseCopyWith<$Res> {
  _$LeaseDocumentClauseCopyWithImpl(this._self, this._then);

  final LeaseDocumentClause _self;
  final $Res Function(LeaseDocumentClause) _then;

/// Create a copy of LeaseDocumentClause
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? title = null,Object? content = null,Object? isRequired = null,Object? sortOrder = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,isRequired: null == isRequired ? _self.isRequired : isRequired // ignore: cast_nullable_to_non_nullable
as bool,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [LeaseDocumentClause].
extension LeaseDocumentClausePatterns on LeaseDocumentClause {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LeaseDocumentClause value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LeaseDocumentClause() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LeaseDocumentClause value)  $default,){
final _that = this;
switch (_that) {
case _LeaseDocumentClause():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LeaseDocumentClause value)?  $default,){
final _that = this;
switch (_that) {
case _LeaseDocumentClause() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String title,  String content,  bool isRequired,  int sortOrder)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LeaseDocumentClause() when $default != null:
return $default(_that.id,_that.title,_that.content,_that.isRequired,_that.sortOrder);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String title,  String content,  bool isRequired,  int sortOrder)  $default,) {final _that = this;
switch (_that) {
case _LeaseDocumentClause():
return $default(_that.id,_that.title,_that.content,_that.isRequired,_that.sortOrder);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String title,  String content,  bool isRequired,  int sortOrder)?  $default,) {final _that = this;
switch (_that) {
case _LeaseDocumentClause() when $default != null:
return $default(_that.id,_that.title,_that.content,_that.isRequired,_that.sortOrder);case _:
  return null;

}
}

}

/// @nodoc


class _LeaseDocumentClause implements LeaseDocumentClause {
  const _LeaseDocumentClause({required this.id, this.title = '', this.content = '', this.isRequired = false, this.sortOrder = 0});


@override final  String id;
@override@JsonKey() final  String title;
@override@JsonKey() final  String content;
@override@JsonKey() final  bool isRequired;
@override@JsonKey() final  int sortOrder;

/// Create a copy of LeaseDocumentClause
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LeaseDocumentClauseCopyWith<_LeaseDocumentClause> get copyWith => __$LeaseDocumentClauseCopyWithImpl<_LeaseDocumentClause>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LeaseDocumentClause&&(identical(other.id, id) || other.id == id)&&(identical(other.title, title) || other.title == title)&&(identical(other.content, content) || other.content == content)&&(identical(other.isRequired, isRequired) || other.isRequired == isRequired)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder));
}


@override
int get hashCode => Object.hash(runtimeType,id,title,content,isRequired,sortOrder);

@override
String toString() {
  return 'LeaseDocumentClause(id: $id, title: $title, content: $content, isRequired: $isRequired, sortOrder: $sortOrder)';
}

// toJson is defined in the hand-written class, not here.

}

/// @nodoc
abstract mixin class _$LeaseDocumentClauseCopyWith<$Res> implements $LeaseDocumentClauseCopyWith<$Res> {
  factory _$LeaseDocumentClauseCopyWith(_LeaseDocumentClause value, $Res Function(_LeaseDocumentClause) _then) = __$LeaseDocumentClauseCopyWithImpl;
@override @useResult
$Res call({
 String id, String title, String content, bool isRequired, int sortOrder
});




}
/// @nodoc
class __$LeaseDocumentClauseCopyWithImpl<$Res>
    implements _$LeaseDocumentClauseCopyWith<$Res> {
  __$LeaseDocumentClauseCopyWithImpl(this._self, this._then);

  final _LeaseDocumentClause _self;
  final $Res Function(_LeaseDocumentClause) _then;

/// Create a copy of LeaseDocumentClause
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? title = null,Object? content = null,Object? isRequired = null,Object? sortOrder = null,}) {
  return _then(_LeaseDocumentClause(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,isRequired: null == isRequired ? _self.isRequired : isRequired // ignore: cast_nullable_to_non_nullable
as bool,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$LeaseDocument {

 String get id; String get leaseId; LeaseDocumentStatus get status; List<LeaseDocumentClause> get clauses; String get disclaimer; String get pdfUrl; DateTime? get createdAt; DateTime? get updatedAt;
/// Create a copy of LeaseDocument
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$LeaseDocumentCopyWith<LeaseDocument> get copyWith => _$LeaseDocumentCopyWithImpl<LeaseDocument>(this as LeaseDocument, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is LeaseDocument&&(identical(other.id, id) || other.id == id)&&(identical(other.leaseId, leaseId) || other.leaseId == leaseId)&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other.clauses, clauses)&&(identical(other.disclaimer, disclaimer) || other.disclaimer == disclaimer)&&(identical(other.pdfUrl, pdfUrl) || other.pdfUrl == pdfUrl)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,leaseId,status,const DeepCollectionEquality().hash(clauses),disclaimer,pdfUrl,createdAt,updatedAt);

@override
String toString() {
  return 'LeaseDocument(id: $id, leaseId: $leaseId, status: $status, clauses: $clauses, disclaimer: $disclaimer, pdfUrl: $pdfUrl, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $LeaseDocumentCopyWith<$Res>  {
  factory $LeaseDocumentCopyWith(LeaseDocument value, $Res Function(LeaseDocument) _then) = _$LeaseDocumentCopyWithImpl;
@useResult
$Res call({
 String id, String leaseId, LeaseDocumentStatus status, List<LeaseDocumentClause> clauses, String disclaimer, String pdfUrl, DateTime? createdAt, DateTime? updatedAt
});




}
/// @nodoc
class _$LeaseDocumentCopyWithImpl<$Res>
    implements $LeaseDocumentCopyWith<$Res> {
  _$LeaseDocumentCopyWithImpl(this._self, this._then);

  final LeaseDocument _self;
  final $Res Function(LeaseDocument) _then;

/// Create a copy of LeaseDocument
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? leaseId = null,Object? status = null,Object? clauses = null,Object? disclaimer = null,Object? pdfUrl = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,leaseId: null == leaseId ? _self.leaseId : leaseId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as LeaseDocumentStatus,clauses: null == clauses ? _self.clauses : clauses // ignore: cast_nullable_to_non_nullable
as List<LeaseDocumentClause>,disclaimer: null == disclaimer ? _self.disclaimer : disclaimer // ignore: cast_nullable_to_non_nullable
as String,pdfUrl: null == pdfUrl ? _self.pdfUrl : pdfUrl // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [LeaseDocument].
extension LeaseDocumentPatterns on LeaseDocument {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _LeaseDocument value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _LeaseDocument() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _LeaseDocument value)  $default,){
final _that = this;
switch (_that) {
case _LeaseDocument():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _LeaseDocument value)?  $default,){
final _that = this;
switch (_that) {
case _LeaseDocument() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String leaseId,  LeaseDocumentStatus status,  List<LeaseDocumentClause> clauses,  String disclaimer,  String pdfUrl,  DateTime? createdAt,  DateTime? updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _LeaseDocument() when $default != null:
return $default(_that.id,_that.leaseId,_that.status,_that.clauses,_that.disclaimer,_that.pdfUrl,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String leaseId,  LeaseDocumentStatus status,  List<LeaseDocumentClause> clauses,  String disclaimer,  String pdfUrl,  DateTime? createdAt,  DateTime? updatedAt)  $default,) {final _that = this;
switch (_that) {
case _LeaseDocument():
return $default(_that.id,_that.leaseId,_that.status,_that.clauses,_that.disclaimer,_that.pdfUrl,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String leaseId,  LeaseDocumentStatus status,  List<LeaseDocumentClause> clauses,  String disclaimer,  String pdfUrl,  DateTime? createdAt,  DateTime? updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _LeaseDocument() when $default != null:
return $default(_that.id,_that.leaseId,_that.status,_that.clauses,_that.disclaimer,_that.pdfUrl,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc


class _LeaseDocument implements LeaseDocument {
  const _LeaseDocument({required this.id, this.leaseId = '', this.status = LeaseDocumentStatus.draft, final  List<LeaseDocumentClause> clauses = const <LeaseDocumentClause>[], this.disclaimer = '', this.pdfUrl = '', this.createdAt, this.updatedAt}): _clauses = clauses;


@override final  String id;
@override@JsonKey() final  String leaseId;
@override@JsonKey() final  LeaseDocumentStatus status;
 final  List<LeaseDocumentClause> _clauses;
@override@JsonKey() List<LeaseDocumentClause> get clauses {
  if (_clauses is EqualUnmodifiableListView) return _clauses;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_clauses);
}

@override@JsonKey() final  String disclaimer;
@override@JsonKey() final  String pdfUrl;
@override final  DateTime? createdAt;
@override final  DateTime? updatedAt;

/// Create a copy of LeaseDocument
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$LeaseDocumentCopyWith<_LeaseDocument> get copyWith => __$LeaseDocumentCopyWithImpl<_LeaseDocument>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _LeaseDocument&&(identical(other.id, id) || other.id == id)&&(identical(other.leaseId, leaseId) || other.leaseId == leaseId)&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other._clauses, _clauses)&&(identical(other.disclaimer, disclaimer) || other.disclaimer == disclaimer)&&(identical(other.pdfUrl, pdfUrl) || other.pdfUrl == pdfUrl)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,leaseId,status,const DeepCollectionEquality().hash(_clauses),disclaimer,pdfUrl,createdAt,updatedAt);

@override
String toString() {
  return 'LeaseDocument(id: $id, leaseId: $leaseId, status: $status, clauses: $clauses, disclaimer: $disclaimer, pdfUrl: $pdfUrl, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$LeaseDocumentCopyWith<$Res> implements $LeaseDocumentCopyWith<$Res> {
  factory _$LeaseDocumentCopyWith(_LeaseDocument value, $Res Function(_LeaseDocument) _then) = __$LeaseDocumentCopyWithImpl;
@override @useResult
$Res call({
 String id, String leaseId, LeaseDocumentStatus status, List<LeaseDocumentClause> clauses, String disclaimer, String pdfUrl, DateTime? createdAt, DateTime? updatedAt
});




}
/// @nodoc
class __$LeaseDocumentCopyWithImpl<$Res>
    implements _$LeaseDocumentCopyWith<$Res> {
  __$LeaseDocumentCopyWithImpl(this._self, this._then);

  final _LeaseDocument _self;
  final $Res Function(_LeaseDocument) _then;

/// Create a copy of LeaseDocument
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? leaseId = null,Object? status = null,Object? clauses = null,Object? disclaimer = null,Object? pdfUrl = null,Object? createdAt = freezed,Object? updatedAt = freezed,}) {
  return _then(_LeaseDocument(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,leaseId: null == leaseId ? _self.leaseId : leaseId // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as LeaseDocumentStatus,clauses: null == clauses ? _self._clauses : clauses // ignore: cast_nullable_to_non_nullable
as List<LeaseDocumentClause>,disclaimer: null == disclaimer ? _self.disclaimer : disclaimer // ignore: cast_nullable_to_non_nullable
as String,pdfUrl: null == pdfUrl ? _self.pdfUrl : pdfUrl // ignore: cast_nullable_to_non_nullable
as String,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}

// dart format on
