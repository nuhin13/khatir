import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khatir_mobile/core/i18n/locale_provider.dart';
import 'package:khatir_mobile/features/properties/data/models/property_enums.dart';
import 'package:khatir_mobile/features/properties/data/models/unit.dart';
import 'package:khatir_mobile/features/properties/data/properties_providers.dart';
import 'package:khatir_mobile/features/properties/presentation/screens/unit_detail_screen.dart';
import 'package:khatir_mobile/l10n/app_localizations.dart';

/// Unit-detail controller test double: builds to a fixed [Unit] (or throws),
/// and records the last [update] call so the PATCH path can be asserted without
/// a network round-trip. On update it applies the patch to its own state, so
/// the screen re-renders the new value (mirroring the real controller, which
/// replaces state with the server response).
class _FakeUnitDetail extends UnitDetailController {
  _FakeUnitDetail(this._result);

  final Object _result;
  UnitStatus? lastStatus;
  UnitType? lastType;
  double? lastRent;
  List<String>? lastAmenities;

  @override
  Future<Unit> build(String unitId) async {
    if (_result is Unit) return _result;
    throw _result;
  }

  @override
  Future<Unit> update({
    String? label,
    UnitType? type,
    double? rent,
    List<String>? amenities,
    UnitStatus? status,
    DateTime? availableFrom,
  }) async {
    lastStatus = status;
    lastType = type;
    lastRent = rent;
    lastAmenities = amenities;
    final current = state.value ?? (_result as Unit);
    final next = current.copyWith(
      type: type ?? current.type,
      rent: rent ?? current.rent,
      amenities: amenities ?? current.amenities,
      status: status ?? current.status,
    );
    state = AsyncValue.data(next);
    return next;
  }
}

void main() {
  const unit = Unit(
    id: 'u1',
    label: '2C',
    type: UnitType.apartment,
    rent: 22000,
    amenities: ['2 bed', '1 bath'],
    status: UnitStatus.vacant,
  );

  Widget harness({required Object unitResult, String? addTenantProbe}) {
    final router = GoRouter(
      initialLocation: '/properties/unit/u1',
      routes: [
        GoRoute(
          path: '/properties/unit/:id',
          name: UnitDetailScreen.routeName,
          builder: (context, state) =>
              UnitDetailScreen(unitId: state.pathParameters['id'] ?? ''),
        ),
        GoRoute(
          path: '/tenants/add',
          name: 'tenantsAdd',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('ADD_TENANT_ROUTE')),
          ),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        localeStorageProvider.overrideWithValue(_FakeSecureStorage()),
        unitDetailProvider.overrideWith(() => _FakeUnitDetail(unitResult)),
      ],
      child: Consumer(
        builder: (context, ref, _) {
          final locale = ref.watch(localeProvider);
          return MaterialApp.router(
            routerConfig: router,
            locale: locale,
            supportedLocales: kSupportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
          );
        },
      ),
    );
  }

  late AppLocalizations bn;

  setUp(() async {
    bn = await AppLocalizations.delegate.load(kLocaleBn);
  });

  testWidgets('data state renders rent, status, type and amenities',
      (tester) async {
    await tester.pumpWidget(harness(unitResult: unit));
    await tester.pumpAndSettle();

    // Section labels.
    expect(find.text(bn.unit_status), findsOneWidget);
    expect(find.text(bn.unit_type), findsOneWidget);
    expect(find.text(bn.unit_amenities), findsOneWidget);

    // Amenities chips and the type/status display labels.
    expect(find.text('2 bed'), findsOneWidget);
    expect(find.text('1 bath'), findsOneWidget);
    expect(find.text(bn.unit_type_apartment), findsWidgets);
    expect(find.text(bn.unit_status_vacant), findsWidgets);

    // Tenant section empty-state + add-tenant CTA.
    expect(find.text(bn.unit_no_tenant), findsOneWidget);
    expect(find.text(bn.unit_add_tenant), findsOneWidget);
  });

  testWidgets('changing status vacant→occupied persists via PATCH',
      (tester) async {
    await tester.pumpWidget(harness(unitResult: unit));
    await tester.pumpAndSettle();

    // Open the status menu (the value pill in the status tile) and pick Occupied.
    await tester.tap(find.text(bn.unit_status_vacant).first);
    await tester.pumpAndSettle();

    await tester.tap(find.text(bn.unit_status_occupied).last);
    await tester.pumpAndSettle();

    // The controller saw a PATCH with the new status, and the hero re-rendered.
    final container = ProviderScope.containerOf(
      tester.element(find.byType(UnitDetailScreen)),
    );
    final fake =
        container.read(unitDetailProvider('u1').notifier) as _FakeUnitDetail;
    expect(fake.lastStatus, UnitStatus.occupied);
    expect(find.text(bn.unit_status_occupied), findsWidgets);
  });

  testWidgets('add-tenant CTA routes to /tenants/add', (tester) async {
    await tester.pumpWidget(harness(unitResult: unit));
    await tester.pumpAndSettle();

    await tester.tap(find.text(bn.unit_add_tenant));
    await tester.pumpAndSettle();

    expect(find.text('ADD_TENANT_ROUTE'), findsOneWidget);
  });

  testWidgets('error state shows retry', (tester) async {
    await tester.pumpWidget(harness(unitResult: Exception('boom')));
    await tester.pumpAndSettle();

    expect(find.text(bn.common_retry), findsOneWidget);
  });
}

/// In-memory secure storage so the locale controller never touches the
/// platform keychain in tests.
class _FakeSecureStorage extends FlutterSecureStorage {
  _FakeSecureStorage() : super();
  final Map<String, String> _store = {};

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async =>
      _store[key];

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value == null) {
      _store.remove(key);
    } else {
      _store[key] = value;
    }
  }
}
