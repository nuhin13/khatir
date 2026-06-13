import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khatir_mobile/core/i18n/locale_provider.dart';
import 'package:khatir_mobile/features/maintenance/data/expense_repository.dart';
import 'package:khatir_mobile/features/maintenance/data/models/maintenance_enums.dart';
import 'package:khatir_mobile/features/maintenance/data/models/models.dart';
import 'package:khatir_mobile/features/maintenance/data/providers.dart';
import 'package:khatir_mobile/features/maintenance/presentation/screens/add_expense_screen.dart';
import 'package:khatir_mobile/features/properties/data/building_repository.dart';
import 'package:khatir_mobile/features/properties/data/models/building.dart';
import 'package:khatir_mobile/features/properties/data/models/unit.dart';
import 'package:khatir_mobile/features/properties/data/properties_providers.dart';
import 'package:khatir_mobile/features/properties/data/unit_repository.dart';
import 'package:khatir_mobile/features/tenants/data/tenants_providers.dart';
import 'package:khatir_mobile/l10n/app_localizations.dart';

/// Records the create call (and optionally fails) so the save flow can be driven
/// deterministically without a network.
class _FakeExpenseRepo extends ExpenseRepository {
  _FakeExpenseRepo({this.fail = false}) : super(Dio());

  final bool fail;
  int createCalls = 0;
  String? lastUnitId;
  double? lastAmount;
  ExpenseCategory? lastCategory;
  String? lastNote;
  String? lastReceiptRef;

  @override
  Future<Expense> createExpense({
    required String unitId,
    required double amount,
    required DateTime date,
    ExpenseCategory? category,
    String? note,
    String? receiptRef,
  }) async {
    createCalls++;
    lastUnitId = unitId;
    lastAmount = amount;
    lastCategory = category;
    lastNote = note;
    lastReceiptRef = receiptRef;
    if (fail) throw Exception('boom');
    return Expense(id: 'e-new', unitId: unitId, amount: amount);
  }
}

/// Serves a fixed building list (drives the building dropdown).
class _FakeBuildingRepo extends BuildingRepository {
  _FakeBuildingRepo(this.buildings) : super(Dio());

  final List<Building> buildings;

  @override
  Future<List<Building>> listBuildings() async => buildings;
}

/// Serves a fixed unit list per building (drives the unit dropdown).
class _FakeUnitRepo extends UnitRepository {
  _FakeUnitRepo(this.units) : super(Dio());

  final List<Unit> units;

  @override
  Future<List<Unit>> listUnits(String buildingId) async =>
      units.where((u) => u.buildingId == buildingId).toList(growable: false);
}

/// A picker that returns a fixed image (or null), recording how often it ran.
class _FakeImagePicker implements ImagePickerService {
  _FakeImagePicker({this.image});

  final PickedImage? image;
  int galleryCalls = 0;

  @override
  Future<PickedImage?> pickFromCamera() async => image;

  @override
  Future<PickedImage?> pickFromGallery() async {
    galleryCalls++;
    return image;
  }
}

void main() {
  late AppLocalizations l10n;

  setUp(() async {
    l10n = await AppLocalizations.delegate.load(kLocaleEn);
  });

  const buildings = [Building(id: 'b-1', name: 'Karim Manzil', address: 'Dhaka')];
  const units = [
    Unit(id: 'u-1', buildingId: 'b-1', label: '2C'),
    Unit(id: 'u-2', buildingId: 'b-1', label: '3A'),
  ];

  Widget harness({
    required _FakeExpenseRepo repo,
    _FakeImagePicker? picker,
    Future<void> Function(AddExpenseDraft draft)? onSaved,
  }) {
    return ProviderScope(
      overrides: [
        expenseRepositoryProvider.overrideWithValue(repo),
        buildingRepositoryProvider
            .overrideWithValue(_FakeBuildingRepo(buildings)),
        unitRepositoryProvider.overrideWithValue(_FakeUnitRepo(units)),
        if (picker != null)
          imagePickerServiceProvider.overrideWithValue(picker),
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
        home: AddExpenseScreen(onSaved: onSaved),
      ),
    );
  }

  // Brings a lazily-built ListView descendant into view so it can be tapped.
  // [delta] is positive to scroll down (default), negative to scroll up.
  Future<void> scrollTo(WidgetTester tester, Key key,
      {double delta = 120}) async {
    await tester.scrollUntilVisible(
      find.byKey(key),
      delta,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  Future<void> chooseBuildingAndUnit(WidgetTester tester) async {
    await scrollTo(tester, const ValueKey('expenseBuilding'));
    await tester.tap(find.byKey(const ValueKey('expenseBuilding')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Karim Manzil').last);
    await tester.pumpAndSettle();

    await scrollTo(tester, const ValueKey('expenseUnit'));
    await tester.tap(find.byKey(const ValueKey('expenseUnit')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2C').last);
    await tester.pumpAndSettle();
  }

  Future<void> tapSave(WidgetTester tester) async {
    await scrollTo(tester, const ValueKey('expenseSave'));
    await tester.tap(find.byKey(const ValueKey('expenseSave')));
    await tester.pumpAndSettle();
  }

  testWidgets('renders the amount, category chips, and save CTA',
      (tester) async {
    await tester.pumpWidget(harness(repo: _FakeExpenseRepo()));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('expenseAmount')), findsOneWidget);
    // One chip per ExpenseCategory config value.
    for (final category in ExpenseCategory.values) {
      expect(
        find.byKey(ValueKey('expenseCategory-${category.wire}')),
        findsOneWidget,
      );
    }
    // The save CTA sits below the fold; scrolling brings it in.
    await scrollTo(tester, const ValueKey('expenseSave'));
    expect(find.byKey(const ValueKey('expenseSave')), findsOneWidget);
  });

  testWidgets('blocks save without an amount and without a unit',
      (tester) async {
    final repo = _FakeExpenseRepo();
    await tester.pumpWidget(harness(repo: repo));
    await tester.pumpAndSettle();

    await tapSave(tester);

    // No create call; the unit error is shown near the (now in-view) save CTA.
    expect(repo.createCalls, 0);
    expect(find.text(l10n.expense_err_unit), findsOneWidget);

    // The amount error sits at the top of the lazily-built list; scroll back up.
    await scrollTo(tester, const ValueKey('expenseAmount'), delta: -120);
    expect(find.text(l10n.expense_err_amount), findsOneWidget);
  });

  testWidgets('saves the entered fields via the repository', (tester) async {
    final repo = _FakeExpenseRepo();
    await tester.pumpWidget(harness(repo: repo));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const ValueKey('expenseAmount')), '3500');
    // Default category is plumbing; switch to paint to assert it threads through.
    await tester.tap(find.byKey(
        ValueKey('expenseCategory-${ExpenseCategory.paint.wire}')));
    await tester.pumpAndSettle();
    await chooseBuildingAndUnit(tester);
    await scrollTo(tester, const ValueKey('expenseNote'));
    await tester.enterText(
        find.byKey(const ValueKey('expenseNote')), 'Leaky tap');

    await tapSave(tester);

    expect(repo.createCalls, 1);
    expect(repo.lastUnitId, 'u-1');
    expect(repo.lastAmount, 3500);
    expect(repo.lastCategory, ExpenseCategory.paint);
    expect(repo.lastNote, 'Leaky tap');
    expect(repo.lastReceiptRef, isNull);
  });

  testWidgets('attaching a receipt threads its ref into the save',
      (tester) async {
    final repo = _FakeExpenseRepo();
    final picker = _FakeImagePicker(
      image: PickedImage(
        bytes: Uint8List.fromList(const [1, 2, 3]),
        filename: 'receipt.jpg',
      ),
    );
    await tester.pumpWidget(harness(repo: repo, picker: picker));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const ValueKey('expenseAmount')), '500');
    await chooseBuildingAndUnit(tester);

    await scrollTo(tester, const ValueKey('expenseReceiptAdd'));
    await tester.tap(find.byKey(const ValueKey('expenseReceiptAdd')));
    await tester.pumpAndSettle();
    expect(picker.galleryCalls, 1);
    expect(find.byKey(const ValueKey('expenseReceiptAttached')), findsOneWidget);

    await tapSave(tester);

    expect(repo.lastReceiptRef, 'receipt.jpg');
  });

  testWidgets('fires the onSaved seam instead of routing', (tester) async {
    final repo = _FakeExpenseRepo();
    AddExpenseDraft? captured;
    await tester.pumpWidget(harness(
      repo: repo,
      onSaved: (draft) async => captured = draft,
    ));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const ValueKey('expenseAmount')), '900');
    await chooseBuildingAndUnit(tester);

    await tapSave(tester);

    // The seam intercepts: the real create flow never runs.
    expect(repo.createCalls, 0);
    expect(captured?.unitId, 'u-1');
    expect(captured?.amount, 900);
  });

  testWidgets('a failed save surfaces a friendly snackbar', (tester) async {
    final repo = _FakeExpenseRepo(fail: true);
    await tester.pumpWidget(harness(repo: repo));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const ValueKey('expenseAmount')), '100');
    await chooseBuildingAndUnit(tester);

    await tapSave(tester);

    expect(repo.createCalls, 1);
    expect(find.text(l10n.expense_save_failed), findsOneWidget);
  });
}
