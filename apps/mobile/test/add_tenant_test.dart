import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khatir_mobile/core/config/public_config_provider.dart';
import 'package:khatir_mobile/core/i18n/locale_provider.dart';
import 'package:khatir_mobile/features/tenants/presentation/screens/add_tenant_screen.dart';
import 'package:khatir_mobile/l10n/app_localizations.dart';

/// Records the route + unit context the chooser navigates to so the tests can
/// assert the OCR/voice/manual routes are reached with the carried unit id.
class _RouteProbe extends StatelessWidget {
  const _RouteProbe({required this.label, required this.unit});

  final String label;
  final String? unit;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(child: Text('$label:${unit ?? '-'}')),
      );
}

void main() {
  late AppLocalizations l10n;

  setUp(() async {
    l10n = await AppLocalizations.delegate.load(kLocaleBn);
  });

  Widget harness({required bool voiceEnabled, String? unitId}) {
    final router = GoRouter(
      initialLocation: unitId == null
          ? AddTenantScreen.routePath
          : '${AddTenantScreen.routePath}?unit=$unitId',
      routes: [
        GoRoute(
          path: AddTenantScreen.routePath,
          name: AddTenantScreen.routeName,
          builder: (context, state) =>
              AddTenantScreen(unitId: state.uri.queryParameters['unit']),
          routes: [
            GoRoute(
              path: 'ocr',
              name: AddTenantScreen.ocrRouteName,
              builder: (context, state) => _RouteProbe(
                label: 'OCR',
                unit: state.uri.queryParameters['unit'],
              ),
            ),
            GoRoute(
              path: 'voice',
              name: AddTenantScreen.voiceRouteName,
              builder: (context, state) => _RouteProbe(
                label: 'VOICE',
                unit: state.uri.queryParameters['unit'],
              ),
            ),
            GoRoute(
              path: 'manual',
              name: AddTenantScreen.manualRouteName,
              builder: (context, state) => _RouteProbe(
                label: 'MANUAL',
                unit: state.uri.queryParameters['unit'],
              ),
            ),
          ],
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        publicConfigProvider.overrideWith(
          (ref) async => PublicConfig.withVoice(voiceTenantEntry: voiceEnabled),
        ),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        locale: kLocaleBn,
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

  testWidgets('shows three method cards when the voice flag is on',
      (tester) async {
    await tester.pumpWidget(harness(voiceEnabled: true));
    await tester.pumpAndSettle();

    expect(find.text(l10n.add_tenant_ocr), findsOneWidget);
    expect(find.text(l10n.add_tenant_voice), findsOneWidget);
    expect(find.text(l10n.add_tenant_manual), findsOneWidget);
  });

  testWidgets('hides the voice card when the voice flag is off',
      (tester) async {
    await tester.pumpWidget(harness(voiceEnabled: false));
    await tester.pumpAndSettle();

    expect(find.text(l10n.add_tenant_ocr), findsOneWidget);
    expect(find.text(l10n.add_tenant_voice), findsNothing);
    expect(find.text(l10n.add_tenant_manual), findsOneWidget);
  });

  testWidgets('tapping OCR routes to the OCR sub-flow carrying the unit id',
      (tester) async {
    await tester.pumpWidget(harness(voiceEnabled: true, unitId: 'u42'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('addTenantOcr')));
    await tester.pumpAndSettle();

    expect(find.text('OCR:u42'), findsOneWidget);
  });

  testWidgets('tapping manual routes to the manual sub-flow carrying the unit',
      (tester) async {
    await tester.pumpWidget(harness(voiceEnabled: true, unitId: 'u7'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('addTenantManual')));
    await tester.pumpAndSettle();

    expect(find.text('MANUAL:u7'), findsOneWidget);
  });

  testWidgets('tapping voice routes to the voice sub-flow', (tester) async {
    await tester.pumpWidget(harness(voiceEnabled: true));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('addTenantVoice')));
    await tester.pumpAndSettle();

    // No unit context from a home-level launch → '-'.
    expect(find.text('VOICE:-'), findsOneWidget);
  });
}
