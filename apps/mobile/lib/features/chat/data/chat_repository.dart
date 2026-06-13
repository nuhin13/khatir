import 'package:dio/dio.dart';

import '../../../core/network/api_endpoints.dart';
import 'models/chat_message.dart';

/// Network access for the in-app chatbot (EPIC-23 T-002 endpoints).
///
/// All requests are user-scoped server-side via `for_user`; there is no
/// user-id parameter so a caller structurally cannot request another user's
/// history. The class is intentionally thin — business rules live in
/// [ChatProvider].
class ChatRepository {
  const ChatRepository(this._dio);

  final Dio _dio;

  /// Sends [message] and returns the assistant's reply as a [ChatMessage].
  ///
  /// `POST /api/v1/chat`
  Future<ChatMessage> send(String message) async {
    final res = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.chat,
      data: {'message': message},
    );
    return ChatMessage.fromJson(res.data!);
  }

  /// Fetches the caller's conversation history, newest first.
  ///
  /// `GET /api/v1/chat/history`
  Future<List<ChatMessage>> history() async {
    final res = await _dio.get<List<dynamic>>(ApiEndpoints.chatHistory);
    final list = res.data ?? [];
    return [
      for (final item in list)
        if (item is Map<String, dynamic>) ChatMessage.fromJson(item),
    ];
  }
}
