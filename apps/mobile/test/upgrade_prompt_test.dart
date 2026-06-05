import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:khatir_mobile/core/i18n/locale_provider.dart';
import 'package:khatir_mobile/features/billing/presentation/screens/plan_screen.dart';
import 'package:khatir_mobile/features/billing/presentation/widgets/upgrade_prompt.dart';
import 'package:khatir_mobile/l10n/app_localizations.dart';

/// T-008 — upgrade prompt (limit reached). The bottom sheet renders the
/// localised copy, routes to the plan screen on **Upgrade plan**, and simply
/// closes on **Not now**.
void main() {
  late AppLocalizations l10n;

  setUp(() async {
    l10n = await AppLocalizations.delegate.load(kLocaleEn);
  });

  /// Builds an app with a trigger button that opens [UpgradePrompt.show] and a
  /// stub `/settings/plan` route, so both the dismiss and the upgrade-navigation
  /// paths are observable.
  Widget harness({required void Function(bool) onResult}) {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, _) => Scaffold(
            body: Center(
              child: ElevatedButton(
                key: const ValueKey('openPrompt'),
                onPressed: () async {
                  final chose = await UpgradePrompt.show(context);
                  onResult(chose);
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: PlanScreen.routePath,
          name: PlanScreen.routeName,
          builder: (context, _) => const Scaffold(
            body: Text('PLAN SCREEN', key: ValueKey('planScreenStub')),
          ),
        ),
      ],
    );

    return MaterialApp.router(
      locale: kLocaleEn,
      supportedLocales: kSupportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
    );
  }

  testWidgets('renders the localised title, body and actions', (tester) async {
    await tester.pumpWidget(harness(onResult: (_) {}));
    await tester.tap(find.byKey(const ValueKey('openPrompt')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('upgradePrompt')), findsOneWidget);
    expect(find.text(l10n.upgrade_title), findsOneWidget);
    expect(find.text(l10n.upgrade_body), findsOneWidget);
    expect(find.text(l10n.upgrade_cta), findsOneWidget);
    expect(find.text(l10n.upgrade_later), findsOneWidget);
  });

  testWidgets('upgrade routes to the plan screen and resolves true', (
    tester,
  ) async {
    bool? result;
    await tester.pumpWidget(harness(onResult: (r) => result = r));
    await tester.tap(find.byKey(const ValueKey('openPrompt')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('upgradePromptUpgrade')));
    await tester.pumpAndSettle();

    // Sheet closed, plan screen pushed, caller saw `true`.
    expect(find.byKey(const ValueKey('upgradePrompt')), findsNothing);
    expect(find.byKey(const ValueKey('planScreenStub')), findsOneWidget);
    expect(result, isTrue);
  });

  testWidgets('not now closes the sheet without navigating', (tester) async {
    bool? result;
    await tester.pumpWidget(harness(onResult: (r) => result = r));
    await tester.tap(find.byKey(const ValueKey('openPrompt')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('upgradePromptLater')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('upgradePrompt')), findsNothing);
    expect(find.byKey(const ValueKey('planScreenStub')), findsNothing);
    expect(result, isFalse);
  });
}
