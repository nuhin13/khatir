import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_message.freezed.dart';
part 'chat_message.g.dart';

/// Wire role values from the chat endpoint (`user` / `assistant`).
enum ChatRole {
  @JsonValue('user')
  user,
  @JsonValue('assistant')
  assistant;

  /// Safe factory — degrades to [user] on unknown values.
  static ChatRole fromWire(String? value) => switch (value) {
        'assistant' => ChatRole.assistant,
        _ => ChatRole.user,
      };
}

/// Immutable representation of one chat turn (user or assistant message).
///
/// Maps to the `ChatMessage` Django model served by
/// `GET /api/v1/chat/history` and echoed back by `POST /api/v1/chat`.
///
/// [isStreaming] is a UI-only flag: `true` while an assistant message is still
/// being streamed (i.e. content is growing). The server never sends this field;
/// the controller sets it to `true` on the optimistic placeholder, then flips it
/// to `false` when the full reply arrives.
@freezed
class ChatMessage with _$ChatMessage {
  const factory ChatMessage({
    required String id,
    required ChatRole role,
    required String content,
    required DateTime createdAt,
    @Default(false) bool isStreaming,
  }) = _ChatMessage;

  factory ChatMessage.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageFromJson(json);
}
