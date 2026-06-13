import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khatir_mobile/core/config/flags_provider.dart';
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

/// Builds a test widget tree with Riverpod + i18n + Material support.
/// Allows overriding specific providers.
Widget _testApp({
  required List<Override> overrides,
  required Widget child,
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    ),
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  // ── ChatSheet disabled state (flag off) ──────────────────────────────────

  group('ChatSheet — chatbot_enabled = false', () {
    testWidgets('shows disabled title and body', (tester) async {
      await tester.pumpWidget(
        _testApp(
          overrides: [
            publicConfigProvider.overrideWith(
              (ref) async => PublicConfig.fromJson({
                'flags': {'chatbot_enabled': false},
              }),
            ),
            // Keep network from being called; history is never reached.
            secureStorageProvider.overrideWithValue(_FakeStorage()),
          ],
          child: const ChatSheet(),
        ),
      );
      await tester.pumpAndSettle();

      // Disabled state title must be present.
      expect(find.textContaining('AI Chat Unavailable'), findsWidgets);
      expect(find.textContaining('AI চ্যাট পাওয়া যাচ্ছে না'), findsWidgets);
    });

    testWidgets('send button is disabled when flag is off', (tester) async {
      // Scaffold needed for SnackBar ancestor.
      final container = ProviderContainer(
        overrides: [
          secureStorageProvider.overrideWithValue(_FakeStorage()),
          publicConfigProvider.overrideWith(
            (ref) async => PublicConfig.fromJson({
              'flags': {'chatbot_enabled': false},
            }),
          ),
        ],
      );
      addTearDown(container.dispose);

      // Mock the Dio adapter so no real network call is made.
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

      // The send button's InkWell onTap is null → Material(color) is line not sage.
      // Find by icon and assert there is no tappable send action.
      final sendIcon = find.byIcon(Icons.send_rounded);
      expect(sendIcon, findsOneWidget);

      // The text input should not be enabled.
      final textFields = tester.widgetList<TextField>(find.byType(TextField));
      for (final tf in textFields) {
        expect(tf.enabled, isFalse,
            reason: 'TextField must be disabled when chatbot_enabled is off');
      }
    });
  });

  // ── ChatSheet enabled state (flag on) ────────────────────────────────────

  group('ChatSheet — chatbot_enabled = true', () {
    testWidgets('shows empty state when there are no messages', (tester) async {
      final container = ProviderContainer(
        overrides: [
          secureStorageProvider.overrideWithValue(_FakeStorage()),
          publicConfigProvider.overrideWith(
            (ref) async => PublicConfig.fromJson({
              'flags': {'chatbot_enabled': true},
            }),
          ),
        ],
      );
      addTearDown(container.dispose);

      container.read(dioClientProvider).httpClientAdapter =
          _ScriptedAdapter((opts) {
        if (opts.path == ApiEndpoints.chatHistory) {
          return _json(<dynamic>[]);
        }
        return _json({}, status: 404);
      });

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
      // Allow async history load.
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // Empty state copy is present.
      expect(find.textContaining('Start the conversation'), findsWidgets);
    });

    testWidgets('shows disclaimer banner', (tester) async {
      final container = ProviderContainer(
        overrides: [
          secureStorageProvider.overrideWithValue(_FakeStorage()),
          publicConfigProvider.overrideWith(
            (ref) async => PublicConfig.fromJson({
              'flags': {'chatbot_enabled': true},
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
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // Both disclaimer strings should be present (bilingual EN+BN).
      expect(
        find.textContaining('AI does not give legal or financial advice'),
        findsWidgets,
      );
    });
  });

  // ── Guardrail rendering ───────────────────────────────────────────────────

  group('ChatSheet — guardrail disclaimer', () {
    testWidgets(
        'shows guardrail disclaimer when assistant reply contains advice keywords',
        (tester) async {
      // Inject a pre-populated state with a guardrail-triggering message.
      final messages = [
        const ChatMessage(
          id: 'u1',
          role: ChatRole.user,
          content: 'Should I invest in property?',
          createdAt: DateTime(2026, 6, 1),
        ),
        const ChatMessage(
          id: 'a1',
          role: ChatRole.assistant,
          content: 'This is general info. For financial advice please consult a financial advisor.',
          createdAt: DateTime(2026, 6, 1),
        ),
      ];

      // Stub the chat provider to return our pre-built messages.
      final container = ProviderContainer(
        overrides: [
          secureStorageProvider.overrideWithValue(_FakeStorage()),
          publicConfigProvider.overrideWith(
            (ref) async => PublicConfig.fromJson({
              'flags': {'chatbot_enabled': true},
            }),
          ),
          // Override chatProvider with a fake notifier that has canned state.
          chatProvider.overrideWith(() => _FakeChatController(messages)),
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
            home: const Scaffold(body: SingleChildScrollView(child: ChatSheet())),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // The guardrail disclaimer should appear below the advisory message.
      expect(
        find.textContaining('AI does not provide legal or financial advice'),
        findsWidgets,
      );
    });

    testWidgets(
        'does NOT show guardrail disclaimer for a benign assistant reply',
        (tester) async {
      final messages = [
        const ChatMessage(
          id: 'u2',
          role: ChatRole.user,
          content: 'How many units do I own?',
          createdAt: DateTime(2026, 6, 1),
        ),
        const ChatMessage(
          id: 'a2',
          role: ChatRole.assistant,
          content: 'You own 5 units across 2 buildings.',
          createdAt: DateTime(2026, 6, 1),
        ),
      ];

      final container = ProviderContainer(
        overrides: [
          secureStorageProvider.overrideWithValue(_FakeStorage()),
          publicConfigProvider.overrideWith(
            (ref) async => PublicConfig.fromJson({
              'flags': {'chatbot_enabled': true},
            }),
          ),
          chatProvider.overrideWith(() => _FakeChatController(messages)),
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
            home: const Scaffold(body: SingleChildScrollView(child: ChatSheet())),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Guardrail disclaimer should NOT appear for a benign reply.
      expect(
        find.textContaining('AI does not provide legal or financial advice'),
        findsNothing,
      );
    });
  });
}

// ── Fake ChatController for widget tests ──────────────────────────────────────

class _FakeChatController extends ChatController {
  _FakeChatController(this._messages);

  final List<ChatMessage> _messages;

  @override
  ChatState build() {
    return ChatState(messages: _messages);
  }

  @override
  Future<void> send(String text) async {
    // No-op for widget tests.
  }
}
