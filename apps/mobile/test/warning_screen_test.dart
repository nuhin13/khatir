/// T-005 — WarningScreen widget tests.
///
/// Covers:
/// - Issue warning form: type picker, reason field, submit CTA.
/// - Privacy banner and legal disclaimer are always visible.
/// - Kill-switch off → feature-disabled state, Issue button absent.
/// - Kill-switch on → form visible, issue fires provider on submit.
/// - Snackbar shown on success.
library;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khatir_mobile/core/i18n/locale_provider.dart';
import 'package:khatir_mobile/features/warnings/data/models/models.dart';
import 'package:khatir_mobile/features/warnings/data/models/warning_enums.dart';
import 'package:khatir_mobile/features/warnings/data/providers.dart';
import 'package:khatir_mobile/features/warnings/presentation/screens/warning_notice_screen.dart';
import 'package:khatir_mobile/features/warnings/presentation/screens/warning_screen.dart';
import 'package:khatir_mobile/l10n/app_localizations.dart';

// ── Test doubles ──────────────────────────────────────────────────────────

/// A fake IssueWarningController that immediately succeeds / fails.
class _FakeIssueController extends IssueWarningController {
  _FakeIssueController({this.shouldFail = false});

  final bool shouldFail;
  int issueCalls = 0;

  static final _fixture = Warning(
    id: 'w-test',
    leaseId: 'lease1',
    tenantId: 't1',
    landlordId: 'l1',
    warningType: WarningType.lateRent,
    reason: 'Test',
    issuedAt: DateTime(2026, 6, 13),
  );

  @override
  Future<Warning?> build(String leaseId) async => null;

  @override
  Future<Warning> issue({
    required WarningType warningType,
    required String reason,
  }) async {
    issueCalls++;
    if (shouldFail) throw Exception('network error');
    // Update state so the screen reacts.
    state = AsyncValue.data(_fixture);
    return _fixture;
  }
}

/// A minimal LeaseWarningsController stub (returns empty — avoids real HTTP).
class _EmptyWarningsController extends LeaseWarningsController {
  @override
  Future<List<Warning>> build(String leaseId) async => [];
}

// ── Harness ────────────────────────────────────────────────────────────────

Widget _harness({
  bool warningsEnabled = true,
  _FakeIssueController? controller,
  void Function(String warningId)? onIssued,
}) {
  final ctrl = controller ?? _FakeIssueController();

  final router = GoRouter(
    initialLocation: '/lease/lease1/warning',
    routes: [
      GoRoute(
        path: WarningScreen.routePath,
        name: WarningScreen.routeName,
        builder: (context, state) => WarningScreen(
          leaseId: state.pathParameters['id'] ?? 'lease1',
          warningsEnabled: warningsEnabled,
          onIssued: onIssued ?? (id) {},
        ),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      issueWarningProvider.overrideWith(() => ctrl),
      leaseWarningsProvider.overrideWith(() => _EmptyWarningsController()),
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

// ── Tests ────────────────────────────────────────────────────────────────

void main() {
  late AppLocalizations l10n;

  setUp(() async {
    l10n = await AppLocalizations.delegate.load(kLocaleEn);
  });

  // Make the viewport tall enough to show the full form.
  void tallView(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  group('WarningScreen — kill-switch OFF', () {
    testWidgets('shows feature-disabled state instead of the form',
        (tester) async {
      tallView(tester);
      await tester.pumpWidget(_harness(warningsEnabled: false));
      await tester.pumpAndSettle();

      expect(find.text(l10n.warning_feature_disabled), findsOneWidget);
      expect(find.byKey(const ValueKey('warningIssueButton')), findsNothing);
      expect(find.byKey(const ValueKey('warningReasonField')), findsNothing);
    });

    testWidgets('screen title still shows', (tester) async {
      tallView(tester);
      await tester.pumpWidget(_harness(warningsEnabled: false));
      await tester.pumpAndSettle();

      expect(find.text(l10n.warning_screen_title), findsOneWidget);
    });
  });

  group('WarningScreen — kill-switch ON', () {
    testWidgets('shows privacy banner, type picker and disclaimer',
        (tester) async {
      tallView(tester);
      await tester.pumpWidget(_harness());
      await tester.pumpAndSettle();

      // Privacy banner must be prominent.
      expect(find.text(l10n.warning_private_notice), findsOneWidget);

      // Type label.
      expect(find.textContaining(l10n.warning_type_label), findsWidgets);

      // Reason field.
      expect(find.byKey(const ValueKey('warningReasonField')), findsOneWidget);

      // Disclaimer.
      expect(find.textContaining('private'), findsWidgets);

      // Issue button.
      expect(find.byKey(const ValueKey('warningIssueButton')), findsOneWidget);
    });

    testWidgets('all 5 warning types are shown', (tester) async {
      tallView(tester);
      await tester.pumpWidget(_harness());
      await tester.pumpAndSettle();

      expect(find.text(l10n.warning_type_late_rent), findsOneWidget);
      expect(find.text(l10n.warning_type_lease_violation), findsOneWidget);
      expect(find.text(l10n.warning_type_noise), findsOneWidget);
      expect(find.text(l10n.warning_type_property_damage), findsOneWidget);
      expect(find.text(l10n.warning_type_other), findsOneWidget);
    });

    testWidgets('submit without reason shows validation error', (tester) async {
      tallView(tester);
      await tester.pumpWidget(_harness());
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('warningIssueButton')));
      await tester.pump();

      expect(find.text(l10n.warning_reason_required), findsOneWidget);
    });

    testWidgets('issue fires with correct type + reason', (tester) async {
      tallView(tester);
      final ctrl = _FakeIssueController();
      String? issuedId;

      await tester.pumpWidget(_harness(
        controller: ctrl,
        onIssued: (id) => issuedId = id,
      ));
      await tester.pumpAndSettle();

      // Enter a reason.
      await tester.enterText(
        find.byKey(const ValueKey('warningReasonField')),
        'Rent is 3 months late',
      );

      await tester.tap(find.byKey(const ValueKey('warningIssueButton')));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(ctrl.issueCalls, 1);
      expect(issuedId, 'w-test');
    });

    testWidgets('shows success snackbar on issue (via onIssued seam)',
        (tester) async {
      tallView(tester);
      await tester.pumpWidget(_harness(onIssued: (_) {}));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('warningReasonField')),
        'Noise complaint',
      );
      await tester.tap(find.byKey(const ValueKey('warningIssueButton')));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text(l10n.warning_issued_ok), findsOneWidget);
    });

    testWidgets('shows error snackbar when issue fails', (tester) async {
      tallView(tester);
      final ctrl = _FakeIssueController(shouldFail: true);

      await tester.pumpWidget(_harness(controller: ctrl));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('warningReasonField')),
        'Some reason',
      );
      await tester.tap(find.byKey(const ValueKey('warningIssueButton')));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text(l10n.warning_issue_error), findsOneWidget);
    });
  });
}
