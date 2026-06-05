import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khatir_mobile/core/i18n/locale_provider.dart';
import 'package:khatir_mobile/features/leases/presentation/screens/lease_form_screen.dart';
import 'package:khatir_mobile/features/properties/data/models/unit.dart';
import 'package:khatir_mobile/features/properties/data/properties_providers.dart';
import 'package:khatir_mobile/features/properties/data/unit_repository.dart';
import 'package:khatir_mobile/features/tenants/data/models/tenant.dart';
import 'package:khatir_mobile/features/tenants/data/tenant_repository.dart';
import 'package:khatir_mobile/features/tenants/data/tenants_providers.dart';
import 'package:khatir_mobile/l10n/app_localizations.dart';

/// A tenant repository that serves a fixed unit-tenants list without a network.
class _FakeTenantRepo extends TenantRepository {
  _FakeTenantRepo(this._tenants) : super(Dio());

  final List<Tenant> _tenants;

  @override
  Future<List<Tenant>> listUnitTenants(String unitId) async => _tenants;
}

/// A unit repository that serves a fixed unit (for the rent default).
class _FakeUnitRepo extends UnitRepository {
  _FakeUnitRepo(this._unit) : super(Dio());

  final Unit _unit;

  @override
  Future<Unit> getUnit(String id) async => _unit;
}

void main() {
  late AppLocalizations l10n;

  // English locale → the Material date picker exposes predictable
  // "OK"/"Next month" affordances, and our l10n strings carry the `· en` half.
  setUp(() async {
    l10n = await AppLocalizations.delegate.load(kLocaleEn);
  });

  void tallView(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 3200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  /// Opens the date field [fieldKey]'s picker, accepts today (start) via OK.
  Future<void> pickToday(WidgetTester tester, Key fieldKey) async {
    await tester.tap(find.byKey(fieldKey));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
  }

  /// Opens the date field [fieldKey]'s picker, advances to next month and taps
  /// day [day] (so the chosen date is comfortably after today), then OK.
  Future<void> pickNextMonthDay(
    WidgetTester tester,
    Key fieldKey,
    String day,
  ) async {
    await tester.tap(find.byKey(fieldKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Next month'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(day));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
  }

  const tenants = [
    Tenant(id: 't-1', name: 'Rahim Uddin'),
    Tenant(id: 't-2', name: 'Karim Mia'),
  ];

  Widget harness({
    String unitId = 'unit-9',
    double? unitRent = 26000,
    List<Tenant> tenantList = tenants,
    void Function(LeaseFormDraft draft)? onProceed,
  }) {
    return ProviderScope(
      overrides: [
        tenantRepositoryProvider.overrideWithValue(
          _FakeTenantRepo(tenantList),
        ),
        unitRepositoryProvider.overrideWithValue(
          _FakeUnitRepo(Unit(id: unitId, label: 'A-1', rent: unitRent)),
        ),
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
        home: LeaseFormScreen(unitId: unitId, onProceed: onProceed),
      ),
    );
  }

  testWidgets('renders both save actions and the rent default', (tester) async {
    tallView(tester);
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('leaseTenant')), findsOneWidget);
    expect(find.byKey(const ValueKey('leaseSave')), findsOneWidget);
    expect(find.byKey(const ValueKey('leaseActivate')), findsOneWidget);

    // Rent is prefilled from the unit (26000).
    final rent = tester.widget<EditableText>(
      find.descendant(
        of: find.byKey(const ValueKey('leaseRent')),
        matching: find.byType(EditableText),
      ),
    );
    expect(rent.controller.text, '26000');
  });

  testWidgets('blocks save when no tenant is selected', (tester) async {
    LeaseFormDraft? captured;
    tallView(tester);
    await tester.pumpWidget(harness(onProceed: (d) => captured = d));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('leaseActivate')));
    await tester.pumpAndSettle();

    expect(captured, isNull);
    expect(find.text(l10n.lease_err_tenant), findsOneWidget);
  });

  testWidgets('blocks save when dates are missing/invalid', (tester) async {
    LeaseFormDraft? captured;
    tallView(tester);
    await tester.pumpWidget(harness(onProceed: (d) => captured = d));
    await tester.pumpAndSettle();

    // Pick a tenant so we get past the tenant guard onto the date guard.
    await tester.tap(find.byKey(const ValueKey('leaseTenant')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rahim Uddin').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('leaseSave')));
    await tester.pumpAndSettle();

    expect(captured, isNull);
    expect(find.text(l10n.lease_err_dates), findsOneWidget);
  });

  testWidgets('save & activate emits the entered terms when valid',
      (tester) async {
    LeaseFormDraft? captured;
    tallView(tester);
    await tester.pumpWidget(harness(onProceed: (d) => captured = d));
    await tester.pumpAndSettle();

    // Tenant.
    await tester.tap(find.byKey(const ValueKey('leaseTenant')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Karim Mia').last);
    await tester.pumpAndSettle();

    // Rent (overwrite the default) + advance.
    await tester.enterText(find.byKey(const ValueKey('leaseRent')), '30000');
    await tester.enterText(find.byKey(const ValueKey('leaseAdvance')), '60000');

    // Start = today; end = a day in next month so end > start.
    await pickToday(tester, const ValueKey('leaseStart'));
    await pickNextMonthDay(tester, const ValueKey('leaseEnd'), '20');

    // Bump the due day once (default 5 → 6).
    await tester.tap(find.byKey(const ValueKey('leaseDueDayUp')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('leaseActivate')));
    await tester.pumpAndSettle();

    expect(captured, isNotNull);
    expect(captured!.unitId, 'unit-9');
    expect(captured!.tenantId, 't-2');
    expect(captured!.rent, 30000);
    expect(captured!.advance, 60000);
    expect(captured!.dueDay, 6);
    expect(captured!.activate, isTrue);
    expect(captured!.endDate.isAfter(captured!.startDate), isTrue);
  });

  testWidgets('save draft sets activate=false on the emitted draft',
      (tester) async {
    LeaseFormDraft? captured;
    tallView(tester);
    await tester.pumpWidget(harness(onProceed: (d) => captured = d));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('leaseTenant')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rahim Uddin').last);
    await tester.pumpAndSettle();

    await pickToday(tester, const ValueKey('leaseStart'));
    await pickNextMonthDay(tester, const ValueKey('leaseEnd'), '20');

    await tester.tap(find.byKey(const ValueKey('leaseSave')));
    await tester.pumpAndSettle();

    expect(captured, isNotNull);
    expect(captured!.activate, isFalse);
    expect(captured!.tenantId, 't-1');
  });

  testWidgets('shows the empty-tenant helper when the unit has no tenants',
      (tester) async {
    tallView(tester);
    await tester.pumpWidget(harness(tenantList: const []));
    await tester.pumpAndSettle();

    expect(find.text(l10n.lease_tenant_empty), findsOneWidget);
    expect(find.byKey(const ValueKey('leaseTenant')), findsNothing);
  });
}
