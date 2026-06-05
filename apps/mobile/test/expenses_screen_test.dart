import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khatir_mobile/core/i18n/locale_provider.dart';
import 'package:khatir_mobile/features/maintenance/data/expense_csv_sharer.dart';
import 'package:khatir_mobile/features/maintenance/data/expense_repository.dart';
import 'package:khatir_mobile/features/maintenance/data/models/maintenance_enums.dart';
import 'package:khatir_mobile/features/maintenance/data/models/models.dart';
import 'package:khatir_mobile/features/maintenance/data/providers.dart';
import 'package:khatir_mobile/features/maintenance/presentation/screens/expenses_screen.dart';
import 'package:khatir_mobile/features/properties/data/building_repository.dart';
import 'package:khatir_mobile/features/properties/data/models/building.dart';
import 'package:khatir_mobile/features/properties/data/properties_providers.dart';
import 'package:khatir_mobile/l10n/app_localizations.dart';

/// An expense repository that serves a fixed list (or throws) and records the
/// filter it was last called with, so the list screen + filter + export can be
/// driven deterministically without a network.
class _FakeExpenseRepo extends ExpenseRepository {
  _FakeExpenseRepo({this.expenses = const [], this.fail = false}) : super(Dio());

  final List<Expense> expenses;
  final bool fail;
  ExpenseFilter? lastListFilter;
  ExpenseFilter? lastExportFilter;
  int exportCalls = 0;

  @override
  Future<List<Expense>> listExpenses({ExpenseFilter? filter}) async {
    lastListFilter = filter;
    if (fail) throw Exception('boom');
    if (filter?.buildingId == null) return expenses;
    return expenses
        .where((e) => e.unitId == filter!.buildingId)
        .toList(growable: false);
  }

  @override
  Future<String> exportCsv({ExpenseFilter? filter}) async {
    exportCalls++;
    lastExportFilter = filter;
    return 'id,amount\ne1,3500\n';
  }
}

/// A building repository serving a fixed building list (drives the filter row).
class _FakeBuildingRepo extends BuildingRepository {
  _FakeBuildingRepo(this.buildings) : super(Dio());

  final List<Building> buildings;

  @override
  Future<List<Building>> listBuildings() async => buildings;
}

/// A CSV sharer that records what it was asked to share instead of opening the
/// platform share sheet (unavailable in a headless test).
class _FakeCsvSharer implements ExpenseCsvSharer {
  String? sharedCsv;
  String? sharedFileName;

  @override
  Future<void> shareCsv({required String csv, required String fileName}) async {
    sharedCsv = csv;
    sharedFileName = fileName;
  }
}

void main() {
  late AppLocalizations l10n;

  setUp(() async {
    l10n = await AppLocalizations.delegate.load(kLocaleEn);
  });

  final expenses = [
    const Expense(
      id: 'e-1',
      unitId: 'b-1',
      amount: 3500,
      category: ExpenseCategory.plumbing,
      source: ExpenseSource.manual,
    ),
    const Expense(
      id: 'e-2',
      unitId: 'b-2',
      amount: 12000,
      category: ExpenseCategory.paint,
      source: ExpenseSource.request,
    ),
  ];

  Widget harness({
    required _FakeExpenseRepo repo,
    _FakeCsvSharer? sharer,
    List<Building> buildings = const [],
  }) {
    return ProviderScope(
      overrides: [
        expenseRepositoryProvider.overrideWithValue(repo),
        buildingRepositoryProvider
            .overrideWithValue(_FakeBuildingRepo(buildings)),
        if (sharer != null)
          expenseCsvSharerProvider.overrideWithValue(sharer),
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
        home: const ExpensesScreen(),
      ),
    );
  }

  testWidgets('renders the total, a row per expense, and source chips',
      (tester) async {
    await tester.pumpWidget(harness(repo: _FakeExpenseRepo(expenses: expenses)));
    await tester.pumpAndSettle();

    // Total is the sum of the amounts (3,500 + 12,000 = 15,500).
    expect(find.text(l10n.expenses_total_amount('15,500')), findsOneWidget);
    expect(find.byKey(const ValueKey('expense-e-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('expense-e-2')), findsOneWidget);
    // Both sources are tagged.
    expect(find.text(l10n.expenses_source_manual), findsOneWidget);
    expect(find.text(l10n.expenses_source_request), findsOneWidget);
  });

  testWidgets('shows the empty state when there are no expenses',
      (tester) async {
    await tester.pumpWidget(harness(repo: _FakeExpenseRepo(expenses: const [])));
    await tester.pumpAndSettle();

    expect(find.text(l10n.expenses_empty), findsOneWidget);
    expect(find.byKey(const ValueKey('expense-e-1')), findsNothing);
  });

  testWidgets('shows the error state with a retry affordance', (tester) async {
    await tester.pumpWidget(harness(repo: _FakeExpenseRepo(fail: true)));
    await tester.pumpAndSettle();

    expect(find.text(l10n.common_network_error), findsOneWidget);
    expect(find.text(l10n.common_retry), findsOneWidget);
  });

  testWidgets('tapping a building filter re-queries with that building id',
      (tester) async {
    final repo = _FakeExpenseRepo(expenses: expenses);
    await tester.pumpWidget(harness(
      repo: repo,
      buildings: const [
        Building(id: 'b-1', name: 'Karim Manzil', address: 'Dhaka'),
        Building(id: 'b-2', name: 'Rahim Tower', address: 'Dhaka'),
      ],
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('expensesFilter-b-1')));
    await tester.pumpAndSettle();

    expect(repo.lastListFilter?.buildingId, 'b-1');
    // Only the b-1 expense remains after the filter narrows the list.
    expect(find.byKey(const ValueKey('expense-e-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('expense-e-2')), findsNothing);
  });

  testWidgets('export fetches the CSV and hands it to the sharer',
      (tester) async {
    final repo = _FakeExpenseRepo(expenses: expenses);
    final sharer = _FakeCsvSharer();
    await tester.pumpWidget(harness(repo: repo, sharer: sharer));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('expensesExport')));
    await tester.pumpAndSettle();

    expect(repo.exportCalls, 1);
    expect(sharer.sharedCsv, contains('id,amount'));
    expect(sharer.sharedFileName, 'expenses.csv');
  });

  testWidgets('the add action fires its callback', (tester) async {
    var added = false;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          expenseRepositoryProvider
              .overrideWithValue(_FakeExpenseRepo(expenses: expenses)),
          buildingRepositoryProvider
              .overrideWithValue(_FakeBuildingRepo(const [])),
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
          home: ExpensesScreen(onAdd: () => added = true),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('expensesAdd')));
    await tester.pumpAndSettle();

    expect(added, isTrue);
  });
}
