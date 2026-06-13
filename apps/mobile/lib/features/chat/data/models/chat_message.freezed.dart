// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chat_message.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ChatMessage {

 String get id; ChatRole get role; String get content; DateTime get createdAt; bool get isStreaming;
/// Create a copy of ChatMessage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChatMessageCopyWith<ChatMessage> get copyWith => _$ChatMessageCopyWithImpl<ChatMessage>(this as ChatMessage, _$identity);

/// Serializes this ChatMessage to a JSON map.
Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChatMessage&&(identical(other.id, id) || other.id == id)&&(identical(other.role, role) || other.role == role)&&(identical(other.content, content) || other.content == content)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.isStreaming, isStreaming) || other.isStreaming == isStreaming));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,role,content,createdAt,isStreaming);

@override
String toString() {
  return 'ChatMessage(id: $id, role: $role, content: $content, createdAt: $createdAt, isStreaming: $isStreaming)';
}


}

/// @nodoc
abstract mixin class $ChatMessageCopyWith<$Res>  {
  factory $ChatMessageCopyWith(ChatMessage value, $Res Function(ChatMessage) _then) = _$ChatMessageCopyWithImpl;
@useResult
$Res call({
 String id, ChatRole role, String content, DateTime createdAt, bool isStreaming
});




}
/// @nodoc
class _$ChatMessageCopyWithImpl<$Res>
    implements $ChatMessageCopyWith<$Res> {
  _$ChatMessageCopyWithImpl(this._self, this._then);

  final ChatMessage _self;
  final $Res Function(ChatMessage) _then;

/// Create a copy of ChatMessage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? role = null,Object? content = null,Object? createdAt = null,Object? isStreaming = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as ChatRole,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,isStreaming: null == isStreaming ? _self.isStreaming : isStreaming // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [ChatMessage].
extension ChatMessagePatterns on ChatMessage {
@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChatMessage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChatMessage() when $default != null:
return $default(_that);case _:
  return orElse();

}
}

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChatMessage value)  $default,){
final _that = this;
switch (_that) {
case _ChatMessage():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChatMessage value)?  $default,){
final _that = this;
switch (_that) {
case _ChatMessage() when $default != null:
return $default(_that);case _:
  return null;

}
}

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  ChatRole role,  String content,  DateTime createdAt,  bool isStreaming)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChatMessage() when $default != null:
return $default(_that.id,_that.role,_that.content,_that.createdAt,_that.isStreaming);case _:
  return orElse();

}
}

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  ChatRole role,  String content,  DateTime createdAt,  bool isStreaming)  $default,) {final _that = this;
switch (_that) {
case _ChatMessage():
return $default(_that.id,_that.role,_that.content,_that.createdAt,_that.isStreaming);case _:
  throw StateError('Unexpected subclass');

}
}

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  ChatRole role,  String content,  DateTime createdAt,  bool isStreaming)?  $default,) {final _that = this;
switch (_that) {
case _ChatMessage() when $default != null:
return $default(_that.id,_that.role,_that.content,_that.createdAt,_that.isStreaming);case _:
  return null;

}
}

}

/// @nodoc


class _ChatMessage implements ChatMessage {
  const _ChatMessage({required this.id, required this.role, required this.content, required this.createdAt, this.isStreaming = false});

@override final  String id;
@override final  ChatRole role;
@override final  String content;
@override final  DateTime createdAt;
@override @JsonKey() final  bool isStreaming;

/// Create a copy of ChatMessage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChatMessageCopyWith<_ChatMessage> get copyWith => __$ChatMessageCopyWithImpl<_ChatMessage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ChatMessageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChatMessage&&(identical(other.id, id) || other.id == id)&&(identical(other.role, role) || other.role == role)&&(identical(other.content, content) || other.content == content)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.isStreaming, isStreaming) || other.isStreaming == isStreaming));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,role,content,createdAt,isStreaming);

@override
String toString() {
  return 'ChatMessage(id: $id, role: $role, content: $content, createdAt: $createdAt, isStreaming: $isStreaming)';
}


}

/// @nodoc
abstract mixin class _$ChatMessageCopyWith<$Res> implements $ChatMessageCopyWith<$Res> {
  factory _$ChatMessageCopyWith(_ChatMessage value, $Res Function(_ChatMessage) _then) = __$ChatMessageCopyWithImpl;
@override @useResult
$Res call({
 String id, ChatRole role, String content, DateTime createdAt, bool isStreaming
});




}
/// @nodoc
class __$ChatMessageCopyWithImpl<$Res>
    implements _$ChatMessageCopyWith<$Res> {
  __$ChatMessageCopyWithImpl(this._self, this._then);

  final _ChatMessage _self;
  final $Res Function(_ChatMessage) _then;

/// Create a copy of ChatMessage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? role = null,Object? content = null,Object? createdAt = null,Object? isStreaming = null,}) {
  return _then(_ChatMessage(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as ChatRole,content: null == content ? _self.content : content // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,isStreaming: null == isStreaming ? _self.isStreaming : isStreaming // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
