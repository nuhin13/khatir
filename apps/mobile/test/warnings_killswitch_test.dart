/// T-009 — Kill-switch enforcement tests for warnings_feature.
///
/// Verifies:
/// 1. When `warnings_feature` flag is FALSE:
///    - The WarningScreen shows a feature-disabled state (no form, no issue CTA).
///    - The LeaseWarningsSection hides the "Issue Warning" CTA.
/// 2. When `warnings_feature` flag is TRUE:
///    - The WarningScreen shows the full form.
///    - The LeaseWarningsSection shows the "Issue Warning" CTA.
/// 3. The repository layer surfaces a 403 (feature_disabled) as ApiException(403)
///    when the server-side kill-switch is off.
library;

import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khatir_mobile/core/i18n/locale_provider.dart';
import 'package:khatir_mobile/core/network/api_exception.dart';
import 'package:khatir_mobile/core/network/dio_client.dart';
import 'package:khatir_mobile/core/storage/secure_storage.dart';
import 'package:khatir_mobile/features/warnings/data/models/models.dart';
import 'package:khatir_mobile/features/warnings/data/models/warning_enums.dart';
import 'package:khatir_mobile/features/warnings/data/providers.dart';
import 'package:khatir_mobile/features/warnings/data/warning_repository.dart';
import 'package:khatir_mobile/features/warnings/presentation/screens/warning_screen.dart';
import 'package:khatir_mobile/features/warnings/presentation/widgets/lease_warnings_section.dart';
import 'package:khatir_mobile/l10n/app_localizations.dart';

// ── Fakes ─────────────────────────────────────────────────────────────────

class _FakeSecureStorage implements SecureStorage {
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
  _ScriptedAdapter(this._body, {this.statusCode = 200});

  final Object _body;
  final int statusCode;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      jsonEncode(_body),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}

ProviderContainer _container(HttpClientAdapter adapter) {
  final c = ProviderContainer(
    overrides: [
      secureStorageProvider.overrideWithValue(_FakeSecureStorage()),
    ],
  );
  addTearDown(c.dispose);
  c.read(dioClientProvider).httpClientAdapter = adapter;
  return c;
}

/// A minimal IssueWarningController stub that stays idle.
class _IdleIssueController extends IssueWarningController {
  @override
  Future<Warning?> build(String leaseId) async => null;

  @override
  Future<Warning> issue({
    required WarningType warningType,
    required String reason,
  }) async {
    throw UnimplementedError();
  }
}

/// A minimal LeaseWarningsController stub that returns an empty list.
class _EmptyWarningsController extends LeaseWarningsController {
  @override
  Future<List<Warning>> build(String leaseId) async => [];
}

// ── Harness helpers ────────────────────────────────────────────────────────

Widget _warningScreenHarness({required bool warningsEnabled}) {
  final router = GoRouter(
    initialLocation: '/lease/lease1/warning',
    routes: [
      GoRoute(
        path: WarningScreen.routePath,
        name: WarningScreen.routeName,
        builder: (context, state) => WarningScreen(
          leaseId: state.pathParameters['id'] ?? 'lease1',
          warningsEnabled: warningsEnabled,
          onIssued: (_) {},
        ),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      issueWarningProvider.overrideWith(() => _IdleIssueController()),
    ],
    child: MaterialApp.router(
      routerConfig: router,
      locale: kLocaleEn,
      supportedLocales: kSupportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    ),
  );
}

Widget _warningSectionHarness({required bool warningsEnabled}) {
  return ProviderScope(
    overrides: [
      leaseWarningsProvider.overrideWith(() => _EmptyWarningsController()),
    ],
    child: MaterialApp(
      locale: kLocaleEn,
      supportedLocales: kSupportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: LeaseWarningsSection(
              leaseId: 'lease1',
              warningsEnabled: warningsEnabled,
            ),
          ),
        ),
      ),
    ),
  );
}

// ── Tests ────────────────────────────────────────────────────────────────

void main() {
  late AppLocalizations l10n;

  setUp(() async {
    l10n = await AppLocalizations.delegate.load(kLocaleEn);
  });

  void tallView(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  // ── WarningScreen kill-switch tests ──────────────────────────────────────

  group('WarningScreen — kill-switch OFF', () {
    testWidgets('shows feature-disabled state; Issue button is ABSENT',
        (tester) async {
      tallView(tester);
      await tester.pumpWidget(_warningScreenHarness(warningsEnabled: false));
      await tester.pumpAndSettle();

      // Feature-disabled message must be visible.
      expect(find.text(l10n.warning_feature_disabled), findsOneWidget);

      // Issue Warning button must be ABSENT.
      expect(find.byKey(const ValueKey('warningIssueButton')), findsNothing);

      // Reason field must be ABSENT.
      expect(find.byKey(const ValueKey('warningReasonField')), findsNothing);
    });
  });

  group('WarningScreen — kill-switch ON', () {
    testWidgets('shows full form; Issue button IS present', (tester) async {
      tallView(tester);
      await tester.pumpWidget(_warningScreenHarness(warningsEnabled: true));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('warningIssueButton')), findsOneWidget);
      expect(find.byKey(const ValueKey('warningReasonField')), findsOneWidget);
      expect(find.text(l10n.warning_feature_disabled), findsNothing);
    });
  });

  // ── LeaseWarningsSection kill-switch tests ────────────────────────────────

  group('LeaseWarningsSection — kill-switch OFF', () {
    testWidgets('Issue Warning CTA is ABSENT', (tester) async {
      tallView(tester);
      await tester.pumpWidget(_warningSectionHarness(warningsEnabled: false));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('leaseIssueWarningCta')),
        findsNothing,
      );
    });
  });

  group('LeaseWarningsSection — kill-switch ON', () {
    testWidgets('Issue Warning CTA IS present', (tester) async {
      tallView(tester);
      await tester.pumpWidget(_warningSectionHarness(warningsEnabled: true));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('leaseIssueWarningCta')),
        findsOneWidget,
      );
    });
  });

  // ── Repository level: server returns 403 (feature_disabled) ──────────────

  group('WarningRepository — server kill-switch returns 403', () {
    test('issueWarning throws ApiException(403) when feature disabled',
        () async {
      final adapter = _ScriptedAdapter(
        {'code': 'feature_disabled', 'detail': 'Warnings are disabled.'},
        statusCode: 403,
      );
      final c = _container(adapter);
      final repo = c.read(warningRepositoryProvider);

      await expectLater(
        repo.issueWarning(
          leaseId: 'lease1',
          warningType: WarningType.lateRent,
          reason: 'Overdue',
        ),
        throwsA(isA<ApiException>()
            .having((e) => e.statusCode, 'statusCode', 403)),
      );
    });

    test('listWarnings is NOT gated (always returns own list or 404)', () async {
      // The list endpoint is not gated by the kill-switch on the server
      // (only issue is). Confirm the client can still parse a 200 list.
      final adapter = _ScriptedAdapter(<dynamic>[], statusCode: 200);
      final c = _container(adapter);
      final repo = c.read(warningRepositoryProvider);

      final warnings = await repo.listWarnings('lease1');
      expect(warnings, isEmpty);
    });
  });
}
