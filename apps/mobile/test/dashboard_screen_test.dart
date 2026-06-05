import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khatir_mobile/core/i18n/locale_provider.dart';
import 'package:khatir_mobile/features/dashboard/data/dashboard_model.dart';
import 'package:khatir_mobile/features/dashboard/data/dashboard_providers.dart';
import 'package:khatir_mobile/features/dashboard/data/dashboard_repository.dart';
import 'package:khatir_mobile/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:khatir_mobile/features/maintenance/data/models/maintenance_enums.dart';
import 'package:khatir_mobile/l10n/app_localizations.dart';

/// A dashboard repository that serves a fixed payload (or throws), recording
/// how many times it was hit so the retry path can be asserted.
class _FakeDashboardRepo extends DashboardRepository {
  _FakeDashboardRepo({required this.data, this.fail = false}) : super(Dio());

  final DashboardData data;
  bool fail;
  int calls = 0;

  @override
  Future<DashboardData> fetchDashboard({int? months}) async {
    calls++;
    if (fail) throw Exception('boom');
    return data;
  }
}

void main() {
  late AppLocalizations l10n;

  setUp(() async {
    l10n = await AppLocalizations.delegate.load(kLocaleEn);
  });

  // The dashboard is a tall scrolling list; give the test a tall surface so
  // every card/chart lays out without having to scroll the lazy ListView.
  Future<void> pumpTall(WidgetTester tester, Widget widget) async {
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();
  }

  const populated = DashboardData(
    totalCollected: 71000,
    totalIncome: 71000,
    totalExpense: 42000,
    occupiedUnits: 11,
    totalUnits: 14,
    occupancyRate: 0.78,
    latePayerCount: 3,
    monthlySeries: [
      MonthPoint(period: '2025-12', collected: 60000, expense: 20000),
      MonthPoint(period: '2026-01', collected: 72000, expense: 25000),
      MonthPoint(period: '2026-05', collected: 71000, expense: 42000),
    ],
    topExpenseCategories: [
      CategoryTotal(category: ExpenseCategory.plumbing, amount: 18500),
      CategoryTotal(category: ExpenseCategory.paint, amount: 12000),
    ],
  );

  Widget harness({
    required _FakeDashboardRepo repo,
    VoidCallback? onLatePayerRequest,
  }) {
    return ProviderScope(
      overrides: [
        dashboardRepositoryProvider.overrideWithValue(repo),
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
        home: DashboardScreen(onLatePayerRequest: onLatePayerRequest),
      ),
    );
  }

  testWidgets('renders the income hero, all charts, and late-payers card',
      (tester) async {
    await pumpTall(tester, harness(repo: _FakeDashboardRepo(data: populated)));

    // Income hero with the localized amount.
    expect(find.byKey(const ValueKey('dashboardIncomeCard')), findsOneWidget);
    expect(find.text(l10n.dashboard_amount('71,000')), findsOneWidget);

    // All four chart blocks render.
    expect(
        find.byKey(const ValueKey('dashboardCollectionChart')), findsOneWidget);
    expect(
        find.byKey(const ValueKey('dashboardOccupancyDonut')), findsOneWidget);
    expect(find.byKey(const ValueKey('dashboardIncomeExpenseChart')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('dashboardTopExpenses')), findsOneWidget);

    // The income-vs-expense chart renders its two-series legend (T-009):
    // a sage income series beside a rose expense series.
    expect(find.text(l10n.dashboard_income_series), findsOneWidget);
    expect(find.text(l10n.dashboard_expense_series), findsOneWidget);

    // Occupancy donut shows the 78% ring.
    expect(find.text('78%'), findsOneWidget);

    // Late-payers card with its quick-request CTA (3 are late).
    expect(find.byKey(const ValueKey('dashboardLatePayers')), findsOneWidget);
    expect(
        find.byKey(const ValueKey('dashboardLateRequest')), findsOneWidget);
    expect(find.text(l10n.dashboard_late_count('3')), findsOneWidget);
  });

  testWidgets('late-payers quick-request fires the navigation callback',
      (tester) async {
    var tapped = false;
    await pumpTall(
      tester,
      harness(
        repo: _FakeDashboardRepo(data: populated),
        onLatePayerRequest: () => tapped = true,
      ),
    );

    await tester.tap(find.byKey(const ValueKey('dashboardLateRequest')));
    await tester.pumpAndSettle();
    expect(tapped, isTrue);
  });

  testWidgets('shows the empty state for a brand-new landlord',
      (tester) async {
    await pumpTall(
      tester,
      harness(repo: _FakeDashboardRepo(data: const DashboardData())),
    );

    expect(find.byKey(const ValueKey('dashboardEmpty')), findsOneWidget);
    expect(find.text(l10n.dashboard_empty), findsOneWidget);
    // No charts when there's nothing to show.
    expect(find.byKey(const ValueKey('dashboardCollectionChart')), findsNothing);
  });

  testWidgets('shows an error state with a working retry', (tester) async {
    final repo = _FakeDashboardRepo(data: populated, fail: true);
    await pumpTall(tester, harness(repo: repo));

    expect(find.text(l10n.common_network_error), findsOneWidget);
    final retry = find.byKey(const ValueKey('dashboardRetry'));
    expect(retry, findsOneWidget);

    // Recover, then retry re-fetches and renders the data.
    repo.fail = false;
    await tester.tap(retry);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('dashboardIncomeCard')), findsOneWidget);
    expect(repo.calls, greaterThanOrEqualTo(2));
  });

  testWidgets('no late payers → no quick-request CTA', (tester) async {
    await pumpTall(
      tester,
      harness(
        repo: _FakeDashboardRepo(
          data: populated.copyWith(latePayerCount: 0),
        ),
      ),
    );

    expect(find.text(l10n.dashboard_late_none), findsOneWidget);
    expect(find.byKey(const ValueKey('dashboardLateRequest')), findsNothing);
  });
}
