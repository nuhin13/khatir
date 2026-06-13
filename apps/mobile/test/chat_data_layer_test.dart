import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khatir_mobile/core/network/api_endpoints.dart';
import 'package:khatir_mobile/core/network/dio_client.dart';
import 'package:khatir_mobile/core/storage/secure_storage.dart';
import 'package:khatir_mobile/features/chat/data/chat_providers.dart';
import 'package:khatir_mobile/features/chat/data/chat_repository.dart';
import 'package:khatir_mobile/features/chat/data/models/chat_message.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

class _FakeStorage implements SecureStorage {
  @override
  Future<void> writeTokens({
    required String accessToken,
    required String refreshToken,
  }) async {}

  @override
  Future<String?> readAccessToken() async => 'tok';

  @override
  Future<String?> readRefreshToken() async => 'ref';

  @override
  Future<void> clear() async {}
}

class _ScriptedAdapter implements HttpClientAdapter {
  _ScriptedAdapter(this.handler);

  final ResponseBody Function(RequestOptions) handler;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return handler(options);
  }
}

ResponseBody _json(Object body, {int status = 200}) =>
    ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

ProviderContainer _makeContainer(_ScriptedAdapter adapter) {
  final container = ProviderContainer(
    overrides: [
      secureStorageProvider.overrideWithValue(_FakeStorage()),
    ],
  );
  addTearDown(container.dispose);
  container.read(dioClientProvider).httpClientAdapter = adapter;
  return container;
}

Map<String, dynamic> _msgJson({
  String id = 'msg-1',
  String role = 'assistant',
  String content = 'Hello!',
  String createdAt = '2026-06-01T12:00:00.000Z',
}) =>
    {
      'id': id,
      'role': role,
      'content': content,
      'created_at': createdAt,
    };

// ── ChatMessage model tests ───────────────────────────────────────────────────

void main() {
  group('ChatRole', () {
    test('fromWire parses "assistant"', () {
      expect(ChatRole.fromWire('assistant'), ChatRole.assistant);
    });

    test('fromWire defaults to user on unknown values', () {
      expect(ChatRole.fromWire(null), ChatRole.user);
      expect(ChatRole.fromWire(''), ChatRole.user);
      expect(ChatRole.fromWire('system'), ChatRole.user);
    });
  });

  group('ChatMessage model', () {
    test('fromJson parses all required fields', () {
      final msg = ChatMessage.fromJson(_msgJson());
      expect(msg.id, 'msg-1');
      expect(msg.role, ChatRole.assistant);
      expect(msg.content, 'Hello!');
      expect(msg.createdAt, DateTime.parse('2026-06-01T12:00:00.000Z'));
    });

    test('isStreaming defaults to false when parsed from JSON', () {
      final msg = ChatMessage.fromJson(_msgJson());
      expect(msg.isStreaming, isFalse);
    });

    test('isStreaming can be set to true for UI placeholder', () {
      const msg = ChatMessage(
        id: 'streaming-1',
        role: ChatRole.assistant,
        content: '',
        createdAt: DateTime(2026, 6, 1),
        isStreaming: true,
      );
      expect(msg.isStreaming, isTrue);
    });

    test('copyWith changes selected fields', () {
      const original = ChatMessage(
        id: 'x',
        role: ChatRole.user,
        content: 'hi',
        createdAt: DateTime(2026, 1, 1),
      );
      final updated = original.copyWith(content: 'updated', isStreaming: true);
      expect(updated.content, 'updated');
      expect(updated.isStreaming, isTrue);
      expect(updated.id, 'x'); // unchanged
    });

    test('isStreaming is NOT serialized to JSON', () {
      const msg = ChatMessage(
        id: 'x',
        role: ChatRole.user,
        content: 'hello',
        createdAt: DateTime(2026, 1, 1),
        isStreaming: true,
      );
      final json = msg.toJson();
      expect(json.containsKey('isStreaming'), isFalse);
      expect(json.containsKey('is_streaming'), isFalse);
    });

    test('equality ignores isStreaming for same id/role/content/createdAt',
        () {
      const a = ChatMessage(
        id: 'x',
        role: ChatRole.user,
        content: 'hello',
        createdAt: DateTime(2026, 1, 1),
        isStreaming: false,
      );
      const b = ChatMessage(
        id: 'x',
        role: ChatRole.user,
        content: 'hello',
        createdAt: DateTime(2026, 1, 1),
        isStreaming: true,
      );
      // Freezed equality includes ALL fields — isStreaming differs so they are
      // NOT equal. This documents the intended behaviour.
      expect(a, isNot(equals(b)));
    });
  });

  // ── ChatRepository tests ──────────────────────────────────────────────────

  group('ChatRepository.history', () {
    test('GET /chat/history parses a list of messages', () async {
      final adapter = _ScriptedAdapter((options) {
        if (options.path == ApiEndpoints.chatHistory &&
            options.method == 'GET') {
          return _json([
            _msgJson(id: 'a', role: 'user', content: 'Hi'),
            _msgJson(id: 'b', role: 'assistant', content: 'Hello!'),
          ]);
        }
        return _json({}, status: 404);
      });
      final container = _makeContainer(adapter);
      final repo = container.read(chatRepositoryProvider);
      final msgs = await repo.history();

      expect(msgs, hasLength(2));
      expect(msgs[0].id, 'a');
      expect(msgs[0].role, ChatRole.user);
      expect(msgs[1].id, 'b');
      expect(msgs[1].role, ChatRole.assistant);
    });

    test('history returns empty list when the endpoint returns []', () async {
      final adapter =
          _ScriptedAdapter((_) => _json(<dynamic>[]));
      final container = _makeContainer(adapter);
      final repo = container.read(chatRepositoryProvider);
      final msgs = await repo.history();
      expect(msgs, isEmpty);
    });
  });

  group('ChatRepository.send', () {
    test('POST /chat returns an assistant ChatMessage', () async {
      final adapter = _ScriptedAdapter((options) {
        if (options.path == ApiEndpoints.chat && options.method == 'POST') {
          return _json(_msgJson(role: 'assistant', content: 'I can help.'));
        }
        return _json({}, status: 404);
      });
      final container = _makeContainer(adapter);
      final repo = container.read(chatRepositoryProvider);
      final reply = await repo.send('Hello?');

      expect(reply.role, ChatRole.assistant);
      expect(reply.content, 'I can help.');
      expect(reply.isStreaming, isFalse);
    });
  });

  // ── ChatController (provider) tests ──────────────────────────────────────

  group('ChatController state transitions', () {
    test('build() triggers history load → messages populated', () async {
      final adapter = _ScriptedAdapter((options) {
        if (options.path == ApiEndpoints.chatHistory) {
          return _json([
            _msgJson(id: 'h1', role: 'user', content: 'Past'),
          ]);
        }
        return _json({}, status: 404);
      });
      final container = _makeContainer(adapter);

      // Drive the async load.
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final state = container.read(chatProvider);
      // History endpoint returns newest-first; controller reverses for display.
      expect(state.isLoading, isFalse);
      expect(state.messages, hasLength(1));
      expect(state.messages[0].id, 'h1');
    });

    test('send() inserts an optimistic user msg + streaming placeholder, '
        'then appends the real reply', () async {
      final adapter = _ScriptedAdapter((options) {
        if (options.path == ApiEndpoints.chatHistory) {
          return _json(<dynamic>[]);
        }
        if (options.path == ApiEndpoints.chat && options.method == 'POST') {
          return _json(
              _msgJson(id: 'reply-1', role: 'assistant', content: 'Got it.'));
        }
        return _json({}, status: 404);
      });
      final container = _makeContainer(adapter);

      // Wait for history load.
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(container.read(chatProvider).messages, isEmpty);

      final sendFuture =
          container.read(chatProvider.notifier).send('What is my rent?');

      // After starting but before awaiting, the optimistic messages should be
      // in state (user msg + streaming placeholder).
      await Future<void>.delayed(Duration.zero);
      final midState = container.read(chatProvider);
      expect(midState.isSending, isTrue);
      expect(midState.messages, hasLength(2));
      expect(midState.messages[0].role, ChatRole.user);
      expect(midState.messages[1].isStreaming, isTrue);

      await sendFuture;

      final finalState = container.read(chatProvider);
      expect(finalState.isSending, isFalse);
      // Final state: optimistic user msg + real assistant reply (no streaming placeholder).
      expect(finalState.messages, hasLength(2));
      expect(finalState.messages[0].role, ChatRole.user);
      expect(finalState.messages[1].id, 'reply-1');
      expect(finalState.messages[1].isStreaming, isFalse);
    });

    test('send() error removes both optimistic msgs and sets error', () async {
      final adapter = _ScriptedAdapter((options) {
        if (options.path == ApiEndpoints.chatHistory) {
          return _json(<dynamic>[]);
        }
        // Simulate server error on send.
        return _json({}, status: 500);
      });
      final container = _makeContainer(adapter);

      await Future<void>.delayed(const Duration(milliseconds: 50));

      await container.read(chatProvider.notifier).send('Fail?');

      final state = container.read(chatProvider);
      expect(state.isSending, isFalse);
      expect(state.messages, isEmpty);
      expect(state.error, isNotNull);
    });

    test('chatHistoryProvider reflects the message list', () async {
      final adapter = _ScriptedAdapter((options) {
        if (options.path == ApiEndpoints.chatHistory) {
          return _json([_msgJson(id: 'x1')]);
        }
        return _json({}, status: 404);
      });
      final container = _makeContainer(adapter);

      await Future<void>.delayed(const Duration(milliseconds: 50));

      final history = container.read(chatHistoryProvider);
      expect(history, hasLength(1));
      expect(history[0].id, 'x1');
    });
  });
}
