import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khatir_mobile/core/i18n/locale_provider.dart';
import 'package:khatir_mobile/features/maintenance/data/expense_repository.dart';
import 'package:khatir_mobile/features/maintenance/data/maintenance_repository.dart';
import 'package:khatir_mobile/features/maintenance/data/models/maintenance_enums.dart';
import 'package:khatir_mobile/features/maintenance/data/models/models.dart';
import 'package:khatir_mobile/features/maintenance/data/providers.dart';
import 'package:khatir_mobile/features/maintenance/presentation/screens/expenses_screen.dart';
import 'package:khatir_mobile/features/maintenance/presentation/screens/maintenance_queue_screen.dart';
import 'package:khatir_mobile/features/maintenance/presentation/widgets/unit_maint_expense_section.dart';
import 'package:khatir_mobile/l10n/app_localizations.dart';

/// A maintenance repository that serves a fixed per-unit queue (or throws /
/// hangs), recording the unit it was asked for so the unit-scoped read can be
/// asserted without a network.
class _FakeMaintenanceRepo extends MaintenanceRepository {
  _FakeMaintenanceRepo({
    this.requests = const [],
    this.fail = false,
    this.hang = false,
  }) : super(Dio());

  final List<MaintenanceRequest> requests;
  final bool fail;
  final bool hang;
  String? lastUnitId;

  @override
  Future<List<MaintenanceRequest>> listQueue({
    MaintenanceStatus? status,
    String? unitId,
  }) async {
    lastUnitId = unitId;
    if (hang) return Completer<List<MaintenanceRequest>>().future;
    if (fail) throw Exception('boom');
    return requests;
  }
}

/// An expense repository that serves a fixed per-unit list (or throws),
/// recording the filter it was asked for.
class _FakeExpenseRepo extends ExpenseRepository {
  _FakeExpenseRepo({this.expenses = const [], this.fail = false}) : super(Dio());

  final List<Expense> expenses;
  final bool fail;
  ExpenseFilter? lastFilter;

  @override
  Future<List<Expense>> listExpenses({ExpenseFilter? filter}) async {
    lastFilter = filter;
    if (fail) throw Exception('boom');
    return expenses;
  }
}

void main() {
  late AppLocalizations l10n;

  setUp(() async {
    l10n = await AppLocalizations.delegate.load(kLocaleEn);
  });

  final requests = [
    const MaintenanceRequest(
      id: 'm-1',
      unitId: 'u1',
      category: MaintenanceCategory.plumbing,
      description: 'Water pipe leaking',
      status: MaintenanceStatus.open,
    ),
    const MaintenanceRequest(
      id: 'm-2',
      unitId: 'u1',
      category: MaintenanceCategory.electrical,
      description: 'Bathroom light broken',
      status: MaintenanceStatus.resolved,
    ),
  ];

  final expenses = [
    const Expense(
      id: 'e-1',
      unitId: 'u1',
      category: ExpenseCategory.plumbing,
      amount: 1500,
    ),
    const Expense(
      id: 'e-2',
      unitId: 'u1',
      category: ExpenseCategory.paint,
      amount: 3500,
    ),
  ];

  Widget harness({
    required _FakeMaintenanceRepo maintenanceRepo,
    required _FakeExpenseRepo expenseRepo,
  }) {
    final router = GoRouter(
      initialLocation: '/unit',
      routes: [
        GoRoute(
          path: '/unit',
          builder: (context, state) => const Scaffold(
            body: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: UnitMaintExpenseSection(unitId: 'u1'),
            ),
          ),
        ),
        GoRoute(
          path: MaintenanceQueueScreen.routePath,
          name: MaintenanceQueueScreen.routeName,
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('MAINTENANCE_ROUTE'))),
        ),
        GoRoute(
          path: ExpensesScreen.routePath,
          name: ExpensesScreen.routeName,
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('EXPENSES_ROUTE'))),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        maintenanceRepositoryProvider.overrideWithValue(maintenanceRepo),
        expenseRepositoryProvider.overrideWithValue(expenseRepo),
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

  testWidgets('data state shows section headings, counts and recent rows',
      (tester) async {
    await tester.pumpWidget(
      harness(
        maintenanceRepo: _FakeMaintenanceRepo(requests: requests),
        expenseRepo: _FakeExpenseRepo(expenses: expenses),
      ),
    );
    await tester.pumpAndSettle();

    // Both section headings render.
    expect(find.text(l10n.unit_maintenance), findsOneWidget);
    expect(find.text(l10n.unit_expenses), findsOneWidget);

    // The maintenance card shows the open count (1 of the 2 requests is open).
    expect(find.text(l10n.unit_maint_open_count('1')), findsOneWidget);
    // A recent request description surfaces.
    expect(find.text('Water pipe leaking'), findsOneWidget);

    // The expense card shows the total (1500 + 3500 = 5000) and the count.
    expect(find.text(l10n.unit_expenses_total('5,000')), findsWidgets);
    expect(find.text(l10n.unit_expenses_count('2')), findsOneWidget);

    // "View all" appears on both cards.
    expect(find.text(l10n.unit_view_all), findsNWidgets(2));
  });

  testWidgets('reads are unit-scoped (unit filter passed through)',
      (tester) async {
    final maintenanceRepo = _FakeMaintenanceRepo(requests: requests);
    final expenseRepo = _FakeExpenseRepo(expenses: expenses);
    await tester.pumpWidget(
      harness(maintenanceRepo: maintenanceRepo, expenseRepo: expenseRepo),
    );
    await tester.pumpAndSettle();

    expect(maintenanceRepo.lastUnitId, 'u1');
    expect(expenseRepo.lastFilter?.unitId, 'u1');
  });

  testWidgets('empty state shows the friendly empty lines', (tester) async {
    await tester.pumpWidget(
      harness(
        maintenanceRepo: _FakeMaintenanceRepo(),
        expenseRepo: _FakeExpenseRepo(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(l10n.unit_maint_empty), findsOneWidget);
    expect(find.text(l10n.unit_expenses_empty), findsOneWidget);
  });

  testWidgets('loading state shows a spinner while the queue is pending',
      (tester) async {
    await tester.pumpWidget(
      harness(
        maintenanceRepo: _FakeMaintenanceRepo(hang: true),
        expenseRepo: _FakeExpenseRepo(expenses: expenses),
      ),
    );
    // Do not settle — the maintenance future never completes.
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsWidgets);
  });

  testWidgets('error state shows the section error line', (tester) async {
    await tester.pumpWidget(
      harness(
        maintenanceRepo: _FakeMaintenanceRepo(fail: true),
        expenseRepo: _FakeExpenseRepo(fail: true),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(l10n.unit_section_error), findsNWidgets(2));
  });

  testWidgets('maintenance "View all" routes to the queue', (tester) async {
    await tester.pumpWidget(
      harness(
        maintenanceRepo: _FakeMaintenanceRepo(requests: requests),
        expenseRepo: _FakeExpenseRepo(expenses: expenses),
      ),
    );
    await tester.pumpAndSettle();

    // The first "View all" link is on the maintenance card.
    await tester.tap(find.text(l10n.unit_view_all).first);
    await tester.pumpAndSettle();

    expect(find.text('MAINTENANCE_ROUTE'), findsOneWidget);
  });

  testWidgets('expense "View all" routes to the expenses list',
      (tester) async {
    await tester.pumpWidget(
      harness(
        maintenanceRepo: _FakeMaintenanceRepo(requests: requests),
        expenseRepo: _FakeExpenseRepo(expenses: expenses),
      ),
    );
    await tester.pumpAndSettle();

    // The last "View all" link is on the expense card.
    await tester.tap(find.text(l10n.unit_view_all).last);
    await tester.pumpAndSettle();

    expect(find.text('EXPENSES_ROUTE'), findsOneWidget);
  });
}
