import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khatir_mobile/core/i18n/locale_provider.dart';
import 'package:khatir_mobile/features/billing/data/billing_providers.dart';
import 'package:khatir_mobile/features/billing/data/billing_repository.dart';
import 'package:khatir_mobile/features/billing/data/models/plan_models.dart';
import 'package:khatir_mobile/features/billing/presentation/screens/plan_screen.dart';
import 'package:khatir_mobile/l10n/app_localizations.dart';

/// A billing repository that serves a fixed plan config and records subscribe
/// calls, so the screen's read + subscribe paths can both be asserted without a
/// real network.
class _FakeBillingRepo extends BillingRepository {
  _FakeBillingRepo({required this.config, this.fail = false}) : super(Dio());

  PlanConfig config;
  bool fail;
  final List<String> subscribed = <String>[];

  @override
  Future<PlanConfig> fetchPlanConfig() async {
    if (fail) throw Exception('boom');
    return config;
  }

  @override
  Future<void> subscribe(String tierKey) async {
    subscribed.add(tierKey);
  }
}

void main() {
  late AppLocalizations l10n;

  setUp(() async {
    l10n = await AppLocalizations.delegate.load(kLocaleEn);
  });

  const config = PlanConfig(
    tiers: [
      PlanTier(
        key: 'free',
        label: 'Free',
        labelBn: 'ফ্রি',
        tenantMin: 1,
        tenantMax: 2,
        monthlyPrice: 0,
      ),
      PlanTier(
        key: 'bundle_10',
        label: 'Bundle 10',
        labelBn: 'বান্ডল ১০',
        tenantMin: 3,
        tenantMax: 10,
        monthlyPrice: 300,
      ),
      PlanTier(
        key: 'unlimited',
        label: 'Unlimited',
        labelBn: 'সীমাহীন',
        tenantMin: 11,
        monthlyPrice: 999,
        includesVerification: true,
      ),
    ],
    subscription: PlanSubscription(
      tierKey: 'free',
      status: 'active',
      tenantsUsed: 1,
      tenantLimit: 2,
    ),
  );

  Future<void> pumpTall(WidgetTester tester, Widget widget) async {
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();
  }

  Widget harness(_FakeBillingRepo repo) {
    return ProviderScope(
      overrides: [
        billingRepositoryProvider.overrideWithValue(repo),
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
        home: const PlanScreen(),
      ),
    );
  }

  testWidgets('renders all tiers with current highlighted and usage', (
    tester,
  ) async {
    final repo = _FakeBillingRepo(config: config);
    await pumpTall(tester, harness(repo));

    // Every tier renders.
    expect(find.byKey(const ValueKey('planTier-free')), findsOneWidget);
    expect(find.byKey(const ValueKey('planTier-bundle_10')), findsOneWidget);
    expect(find.byKey(const ValueKey('planTier-unlimited')), findsOneWidget);

    // Current (free) tier shows the "Now" chip; usage reads 1/2.
    expect(find.text(l10n.plan_current), findsOneWidget);
    expect(find.text(l10n.plan_usage('1', '2')), findsOneWidget);

    // The current tier has no subscribe action; the others do.
    expect(
      find.byKey(const ValueKey('planSubscribe-free')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('planSubscribe-bundle_10')),
      findsOneWidget,
    );

    // The unlimited tier is ringed as best value.
    expect(find.byKey(const ValueKey('planBestValue')), findsOneWidget);
  });

  testWidgets('subscribe fires the repo and shows the pending confirmation', (
    tester,
  ) async {
    final repo = _FakeBillingRepo(config: config);
    await pumpTall(tester, harness(repo));

    await tester.tap(find.byKey(const ValueKey('planSubscribe-bundle_10')));
    await tester.pumpAndSettle();

    expect(repo.subscribed, ['bundle_10']);
    expect(find.text(l10n.plan_billing_confirm_pending), findsOneWidget);
  });

  testWidgets('error state retries the read', (tester) async {
    final repo = _FakeBillingRepo(config: config, fail: true);
    await pumpTall(tester, harness(repo));

    expect(find.byKey(const ValueKey('planRetry')), findsOneWidget);

    repo.fail = false;
    await tester.tap(find.byKey(const ValueKey('planRetry')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('planTier-free')), findsOneWidget);
  });

  testWidgets('empty state shown when no tiers configured', (tester) async {
    final repo = _FakeBillingRepo(config: const PlanConfig());
    await pumpTall(tester, harness(repo));

    expect(find.byKey(const ValueKey('planEmpty')), findsOneWidget);
  });
}
