// T-008 — Chat safety, scoping, and guardrail tests.
//
// Covers three guarantees:
//  1. Own-data scoping: user A's ChatController cannot retrieve user B's
//     history (structural enforcement via no user-id parameter).
//  2. Guardrails: if the assistant response contains legal/financial advice
//     keywords the UI shows a disclaimer overlay (tested via the
//     _containsGuardrailKeyword function that drives [_MessageBubble]).
//  3. Feature-flag gate: when chatbot_enabled = false the send button is
//     disabled and ChatSheet shows the feature-off state.

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khatir_mobile/core/config/public_config_provider.dart';
import 'package:khatir_mobile/core/network/api_endpoints.dart';
import 'package:khatir_mobile/core/network/dio_client.dart';
import 'package:khatir_mobile/core/storage/secure_storage.dart';
import 'package:khatir_mobile/features/chat/data/chat_providers.dart';
import 'package:khatir_mobile/features/chat/data/models/chat_message.dart';
import 'package:khatir_mobile/features/chat/presentation/widgets/chat_sheet.dart';
import 'package:khatir_mobile/l10n/app_localizations.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

class _FakeStorage implements SecureStorage {
  const _FakeStorage({this.token = 'user-a-tok'});
  final String token;
  @override
  Future<void> writeTokens({
    required String accessToken,
    required String refreshToken,
  }) async {}
  @override
  Future<String?> readAccessToken() async => token;
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
  ) async =>
      handler(options);
}

ResponseBody _json(Object body, {int status = 200}) =>
    ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

Map<String, dynamic> _msgJson({
  String id = 'm1',
  String role = 'user',
  String content = 'Test',
}) =>
    {
      'id': id,
      'role': role,
      'content': content,
      'created_at': '2026-06-01T10:00:00.000Z',
    };

// ── 1. Own-data scoping ───────────────────────────────────────────────────────

void main() {
  group('T-008 · Own-data scoping', () {
    test(
        'ChatRepository.history() sends no user-id parameter — '
        'scoping is structural (server-side via request.user)', () async {
      // Set up two separate containers representing user A and user B.
      // Each has a different auth token; the history endpoint is called per-user.
      RequestOptions? userARequest;
      RequestOptions? userBRequest;

      final adapterA = _ScriptedAdapter((opts) {
        if (opts.path == ApiEndpoints.chatHistory) {
          userARequest = opts;
          return _json([_msgJson(id: 'a-msg', content: 'User A message')]);
        }
        return _json({}, status: 404);
      });

      final adapterB = _ScriptedAdapter((opts) {
        if (opts.path == ApiEndpoints.chatHistory) {
          userBRequest = opts;
          return _json([_msgJson(id: 'b-msg', content: 'User B message')]);
        }
        return _json({}, status: 404);
      });

      // Container for user A.
      final containerA = ProviderContainer(
        overrides: [
          secureStorageProvider.overrideWithValue(
              const _FakeStorage(token: 'user-a-access-token')),
        ],
      );
      addTearDown(containerA.dispose);
      containerA.read(dioClientProvider).httpClientAdapter = adapterA;

      // Container for user B.
      final containerB = ProviderContainer(
        overrides: [
          secureStorageProvider.overrideWithValue(
              const _FakeStorage(token: 'user-b-access-token')),
        ],
      );
      addTearDown(containerB.dispose);
      containerB.read(dioClientProvider).httpClientAdapter = adapterB;

      // User A fetches history.
      final repoA = containerA.read(chatRepositoryProvider);
      final msgsA = await repoA.history();

      // User B fetches history.
      final repoB = containerB.read(chatRepositoryProvider);
      final msgsB = await repoB.history();

      // Each user received their own messages — never crossed.
      expect(msgsA.map((m) => m.id), contains('a-msg'));
      expect(msgsB.map((m) => m.id), contains('b-msg'));
      expect(msgsA.map((m) => m.id), isNot(contains('b-msg')));
      expect(msgsB.map((m) => m.id), isNot(contains('a-msg')));

      // Structural assertion: no user_id parameter was ever sent.
      // The backend resolves the user from the Authorization header alone.
      expect(
        userARequest!.queryParameters.containsKey('user_id'),
        isFalse,
        reason: 'history() must never send a user_id query parameter',
      );
      expect(
        userBRequest!.queryParameters.containsKey('user_id'),
        isFalse,
        reason: 'history() must never send a user_id query parameter',
      );

      // Authorization headers differ per user (different tokens).
      final authA =
          userARequest!.headers['authorization'] as String? ?? '';
      final authB =
          userBRequest!.headers['authorization'] as String? ?? '';
      expect(authA, isNot(equals(authB)),
          reason:
              'Different users must authenticate with different tokens — '
              'the bearer token is the only user-scoping mechanism');
    });

    test(
        'ChatController for user A cannot directly invoke user B history '
        'because the notifier uses the shared dioClientProvider scoped to the container',
        () async {
      // User A's container has messages for user A only.
      final containerA = ProviderContainer(
        overrides: [
          secureStorageProvider.overrideWithValue(
              const _FakeStorage(token: 'tok-a')),
        ],
      );
      addTearDown(containerA.dispose);
      containerA.read(dioClientProvider).httpClientAdapter =
          _ScriptedAdapter((opts) {
        if (opts.path == ApiEndpoints.chatHistory) {
          return _json([_msgJson(id: 'user-a-1', content: 'A owns this')]);
        }
        return _json({}, status: 404);
      });

      await containerA.read(chatProvider.notifier).refresh();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final stateA = containerA.read(chatProvider);
      expect(stateA.messages.map((m) => m.id), contains('user-a-1'));

      // User B's container — completely separate, never touches A's data.
      final containerB = ProviderContainer(
        overrides: [
          secureStorageProvider.overrideWithValue(
              const _FakeStorage(token: 'tok-b')),
        ],
      );
      addTearDown(containerB.dispose);
      containerB.read(dioClientProvider).httpClientAdapter =
          _ScriptedAdapter((opts) {
        if (opts.path == ApiEndpoints.chatHistory) {
          return _json([_msgJson(id: 'user-b-1', content: 'B owns this')]);
        }
        return _json({}, status: 404);
      });

      await containerB.read(chatProvider.notifier).refresh();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final stateB = containerB.read(chatProvider);

      // No cross-contamination between provider containers.
      expect(
          stateA.messages.map((m) => m.id), isNot(contains('user-b-1')));
      expect(
          stateB.messages.map((m) => m.id), isNot(contains('user-a-1')));
    });
  });

  // ── 2. Guardrail: UI shows disclaimer on advisory content ────────────────

  group('T-008 · Guardrails', () {
    testWidgets(
        'ChatSheet shows guardrail disclaimer when assistant reply '
        'contains "financial advice" keyword', (tester) async {
      final advisoryMessages = [
        const ChatMessage(
          id: 'u1',
          role: ChatRole.user,
          content: 'Should I take a mortgage?',
          createdAt: DateTime(2026, 6, 1),
        ),
        const ChatMessage(
          id: 'a1',
          role: ChatRole.assistant,
          content: 'For detailed financial advice, please consult a financial advisor.',
          createdAt: DateTime(2026, 6, 1),
        ),
      ];

      final container = ProviderContainer(
        overrides: [
          secureStorageProvider.overrideWithValue(const _FakeStorage()),
          publicConfigProvider.overrideWith(
            (ref) async => PublicConfig.fromJson({
              'flags': {'chatbot_enabled': true},
            }),
          ),
          chatProvider.overrideWith(
              () => _FakeChatController(advisoryMessages)),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(
              body: SingleChildScrollView(child: ChatSheet()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // The guardrail disclaimer must appear.
      expect(
        find.textContaining(
            'AI does not provide legal or financial advice'),
        findsWidgets,
      );
    });

    testWidgets(
        'ChatSheet shows guardrail disclaimer when assistant reply '
        'contains Bangla keyword "আইনি পরামর্শ"', (tester) async {
      final advisoryMessages = [
        const ChatMessage(
          id: 'u2',
          role: ChatRole.user,
          content: 'আমার কি আইনি সাহায্য দরকার?',
          createdAt: DateTime(2026, 6, 1),
        ),
        const ChatMessage(
          id: 'a2',
          role: ChatRole.assistant,
          content: 'এটি শুধু সাধারণ তথ্য। আইনি পরামর্শের জন্য একজন আইনজীবীর সাথে যোগাযোগ করুন।',
          createdAt: DateTime(2026, 6, 1),
        ),
      ];

      final container = ProviderContainer(
        overrides: [
          secureStorageProvider.overrideWithValue(const _FakeStorage()),
          publicConfigProvider.overrideWith(
            (ref) async => PublicConfig.fromJson({
              'flags': {'chatbot_enabled': true},
            }),
          ),
          chatProvider.overrideWith(
              () => _FakeChatController(advisoryMessages)),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(
              body: SingleChildScrollView(child: ChatSheet()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.textContaining(
            'AI does not provide legal or financial advice'),
        findsWidgets,
      );
    });

    testWidgets(
        'ChatSheet does NOT show guardrail for benign assistant replies',
        (tester) async {
      final benignMessages = [
        const ChatMessage(
          id: 'u3',
          role: ChatRole.user,
          content: 'How much rent did I collect this month?',
          createdAt: DateTime(2026, 6, 1),
        ),
        const ChatMessage(
          id: 'a3',
          role: ChatRole.assistant,
          content: 'You collected ৳15,000 this month across 3 units.',
          createdAt: DateTime(2026, 6, 1),
        ),
      ];

      final container = ProviderContainer(
        overrides: [
          secureStorageProvider.overrideWithValue(const _FakeStorage()),
          publicConfigProvider.overrideWith(
            (ref) async => PublicConfig.fromJson({
              'flags': {'chatbot_enabled': true},
            }),
          ),
          chatProvider.overrideWith(
              () => _FakeChatController(benignMessages)),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(
              body: SingleChildScrollView(child: ChatSheet()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Guardrail must NOT appear for benign content.
      expect(
        find.textContaining(
            'AI does not provide legal or financial advice'),
        findsNothing,
      );
    });
  });

  // ── 3. Feature-flag gate ──────────────────────────────────────────────────

  group('T-008 · Feature flag gate', () {
    testWidgets(
        'chatbot_enabled = false → send button disabled, disabled state shown',
        (tester) async {
      final container = ProviderContainer(
        overrides: [
          secureStorageProvider.overrideWithValue(const _FakeStorage()),
          publicConfigProvider.overrideWith(
            (ref) async => PublicConfig.fromJson({
              'flags': {'chatbot_enabled': false},
            }),
          ),
        ],
      );
      addTearDown(container.dispose);

      container.read(dioClientProvider).httpClientAdapter =
          _ScriptedAdapter((_) => _json(<dynamic>[]));

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(body: ChatSheet()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Disabled state text must be present.
      expect(find.textContaining('AI Chat Unavailable'), findsWidgets);

      // Input TextField must be disabled.
      final textFields = tester.widgetList<TextField>(find.byType(TextField));
      for (final tf in textFields) {
        expect(
          tf.enabled,
          isFalse,
          reason: 'Send input must be disabled when chatbot_enabled is off',
        );
      }
    });

    testWidgets(
        'chatbot_enabled = true → sheet shows message area and enabled input',
        (tester) async {
      final container = ProviderContainer(
        overrides: [
          secureStorageProvider.overrideWithValue(const _FakeStorage()),
          publicConfigProvider.overrideWith(
            (ref) async => PublicConfig.fromJson({
              'flags': {'chatbot_enabled': true},
            }),
          ),
          chatProvider.overrideWith(() => _FakeChatController(const [])),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(body: ChatSheet()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // "AI Chat Unavailable" should NOT appear.
      expect(find.textContaining('AI Chat Unavailable'), findsNothing);

      // Input should be enabled.
      final textFields = tester.widgetList<TextField>(find.byType(TextField));
      expect(
        textFields.any((tf) => tf.enabled != false),
        isTrue,
        reason: 'At least one TextField should be enabled when flag is on',
      );
    });
  });
}

// ── Fake ChatController for widget tests ──────────────────────────────────────

class _FakeChatController extends ChatController {
  _FakeChatController(this._messages);

  final List<ChatMessage> _messages;

  @override
  ChatState build() => ChatState(messages: _messages);

  @override
  Future<void> send(String text) async {}
}
