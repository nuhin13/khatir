import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khatir_mobile/features/properties/data/models/building.dart';
import 'package:khatir_mobile/features/properties/data/models/portfolio_summary.dart';
import 'package:khatir_mobile/features/properties/data/models/property_enums.dart';
import 'package:khatir_mobile/features/properties/data/models/unit.dart';
import 'package:khatir_mobile/features/properties/data/properties_providers.dart';
import 'package:khatir_mobile/features/properties/presentation/wizard/add_building_controller.dart';
import 'package:khatir_mobile/features/properties/presentation/wizard/step3_units.dart';
import 'package:khatir_mobile/features/properties/presentation/wizard/step4_review.dart';
import 'package:khatir_mobile/features/properties/presentation/wizard/unit_label_gen.dart';
import 'package:khatir_mobile/l10n/app_localizations.dart';

void main() {
  // ── Pure label generation (mirrors backend generate_unit_labels) ───────────
  group('generateUnitLabels', () {
    test('letter scheme: 3 floors × 2 → 1A,1B,2A,2B,3A,3B', () {
      expect(
        generateUnitLabels(
          floors: 3,
          perFloor: 2,
          scheme: UnitScheme.letter,
        ),
        ['1A', '1B', '2A', '2B', '3A', '3B'],
      );
    });

    test('number scheme: 2 floors × 2 → 101,102,201,202', () {
      expect(
        generateUnitLabels(
          floors: 2,
          perFloor: 2,
          scheme: UnitScheme.number,
        ),
        ['101', '102', '201', '202'],
      );
    });

    test('removed labels are filtered out', () {
      expect(
        generateUnitLabels(
          floors: 3,
          perFloor: 2,
          scheme: UnitScheme.letter,
          removed: {'2B'},
        ),
        ['1A', '1B', '2A', '3A', '3B'],
      );
    });

    test('custom labels are appended in order, dedup, after removal', () {
      expect(
        generateUnitLabels(
          floors: 3,
          perFloor: 2,
          scheme: UnitScheme.letter,
          custom: ['8B', '1A'], // 1A already exists → collapses
          removed: {'2B'},
        ),
        ['1A', '1B', '2A', '3A', '3B', '8B'],
      );
    });
  });

  // ── Controller units state ────────────────────────────────────────────────
  group('AddBuildingController units', () {
    test('floors/perFloor clamp to 1..20 and drive labels', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final c = container.read(addBuildingControllerProvider.notifier);

      c.setFloors(3);
      c.setPerFloor(2);
      c.setScheme(UnitScheme.letter);
      expect(
        container.read(addBuildingControllerProvider).unitLabels,
        ['1A', '1B', '2A', '2B', '3A', '3B'],
      );

      c.changeFloors(-10); // clamp at 1
      expect(container.read(addBuildingControllerProvider).floors, 1);
      c.changePerFloor(100); // clamp at 20
      expect(container.read(addBuildingControllerProvider).perFloor, 20);
    });

    test('removeLabel on a generated label hides it; survives regen', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final c = container.read(addBuildingControllerProvider.notifier);

      c.setFloors(3);
      c.setPerFloor(2);
      c.removeLabel('2B');
      expect(
        container.read(addBuildingControllerProvider).unitLabels,
        isNot(contains('2B')),
      );
      // Bumping floors then back still keeps 2B removed.
      c.changeFloors(1);
      c.changeFloors(-1);
      expect(
        container.read(addBuildingControllerProvider).unitLabels,
        isNot(contains('2B')),
      );
    });

    test('addCustomLabel appends, ignores blanks/dupes, un-removes', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final c = container.read(addBuildingControllerProvider.notifier);

      c.setFloors(3);
      c.setPerFloor(2);
      c.addCustomLabel('  '); // blank ignored
      c.addCustomLabel('1A'); // already generated → ignored
      c.addCustomLabel('8B'); // appended
      expect(
        container.read(addBuildingControllerProvider).unitLabels,
        contains('8B'),
      );

      // Removing then re-adding 2B (a generated label) un-removes it.
      c.removeLabel('2B');
      expect(
        container.read(addBuildingControllerProvider).unitLabels,
        isNot(contains('2B')),
      );
      c.addCustomLabel('2B');
      expect(
        container.read(addBuildingControllerProvider).unitLabels,
        contains('2B'),
      );

      // Custom labels are de-duplicated.
      c.addCustomLabel('8B');
      final count = container
          .read(addBuildingControllerProvider)
          .unitLabels
          .where((l) => l == '8B')
          .length;
      expect(count, 1);
    });

    test('removeLabel on a custom label drops it from customLabels', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final c = container.read(addBuildingControllerProvider.notifier);

      c.setFloors(1);
      c.setPerFloor(1);
      c.addCustomLabel('8B');
      expect(container.read(addBuildingControllerProvider).customLabels, ['8B']);
      c.removeLabel('8B');
      expect(container.read(addBuildingControllerProvider).customLabels, isEmpty);
    });
  });

  // ── Step-3 widget ───────────────────────────────────────────────────────--
  testWidgets('step 3 renders live labels and updates on stepper tap',
      (tester) async {
    late AppLocalizations en;
    await tester.pumpWidget(
      _host(child: Step3Units(onNext: () {})),
    );
    await tester.pumpAndSettle();
    en = await AppLocalizations.delegate.load(const Locale('en'));

    // Default 3×2 letter scheme → six chips, including 1A and 3B.
    expect(find.text('1A'), findsOneWidget);
    expect(find.text('3B'), findsOneWidget);
    expect(find.text(en.wizard_units_count(6)), findsOneWidget);
  });

  // ── Step-4 save flow ──────────────────────────────────────────────────────
  testWidgets('step 4 save creates building then generates units → portfolio',
      (tester) async {
    final fakeBuildings = _FakeBuildings();
    final fakeUnits = _FakeUnits();
    final fakePortfolio = _FakePortfolio();

    final router = GoRouter(
      initialLocation: '/add',
      routes: [
        GoRoute(
          path: '/add',
          builder: (context, state) => const Scaffold(body: Step4Review()),
        ),
        GoRoute(
          path: '/properties',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('PORTFOLIO'))),
        ),
      ],
    );

    final en = await AppLocalizations.delegate.load(const Locale('en'));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Seed wizard state: a valid building + 3×2 letter units.
          buildingsProvider.overrideWith(() => fakeBuildings),
          buildingUnitsProvider.overrideWith(() => fakeUnits),
          portfolioProvider.overrideWith(() => fakePortfolio),
        ],
        child: _RouterApp(router: router, seed: (c) {
          c.setName('করিম মঞ্জিল');
          c.setArea(Area.mirpur);
          c.setAddress('House 12, Mirpur');
          c.setFloors(3);
          c.setPerFloor(2);
          c.setScheme(UnitScheme.letter);
        }),
      ),
    );
    await tester.pumpAndSettle();

    // Review card shows building, area and the unit count summary.
    expect(find.text('করিম মঞ্জিল'), findsOneWidget);
    expect(find.text(en.area_mirpur), findsWidgets);

    await tester.tap(find.text(en.wizard_save));
    await tester.pumpAndSettle();

    // Building created with the wizard fields, then units generated for it.
    expect(fakeBuildings.lastName, 'করিম মঞ্জিল');
    expect(fakeBuildings.lastArea, Area.mirpur);
    expect(fakeUnits.lastBuildingId, 'b1');
    expect(fakeUnits.lastFloors, 3);
    expect(fakeUnits.lastPerFloor, 2);
    expect(fakeUnits.lastScheme, UnitScheme.letter);

    // Routed to portfolio.
    expect(find.text('PORTFOLIO'), findsOneWidget);
  });
}

/// Mounts [child] under a minimal localized app with a fresh provider scope.
Widget _host({required Widget child}) {
  return ProviderScope(
    child: MaterialApp(
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Scaffold(body: child),
    ),
  );
}

/// App that seeds the wizard controller before painting the router.
class _RouterApp extends ConsumerStatefulWidget {
  const _RouterApp({required this.router, required this.seed});

  final GoRouter router;
  final void Function(AddBuildingController) seed;

  @override
  ConsumerState<_RouterApp> createState() => _RouterAppState();
}

class _RouterAppState extends ConsumerState<_RouterApp> {
  @override
  void initState() {
    super.initState();
    // Seed after the first frame: mutating the wizard provider synchronously
    // inside initState marks the enclosing ProviderScope dirty mid-build, which
    // trips a `!_dirty` framework assertion. Deferring to a post-frame callback
    // applies the seed once the build phase has settled.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.seed(ref.read(addBuildingControllerProvider.notifier));
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: widget.router,
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}

/// Records the create() call and returns a fixed building.
class _FakeBuildings extends BuildingsController {
  String? lastName;
  Area? lastArea;
  String? lastAddress;

  @override
  Future<List<Building>> build() async => const [];

  @override
  Future<Building> create({
    required String name,
    required Area area,
    required String address,
    double? lat,
    double? lng,
  }) async {
    lastName = name;
    lastArea = area;
    lastAddress = address;
    return Building(id: 'b1', name: name, area: area, address: address);
  }
}

/// Records the generate() call and returns fixed units.
class _FakeUnits extends BuildingUnitsController {
  String? lastBuildingId;
  int? lastFloors;
  int? lastPerFloor;
  UnitScheme? lastScheme;

  @override
  Future<List<Unit>> build(String buildingId) async => const [];

  @override
  Future<List<Unit>> generate({
    required int floors,
    required int perFloor,
    required UnitScheme scheme,
    List<String>? custom,
    List<String>? removed,
  }) async {
    lastBuildingId = arg;
    lastFloors = floors;
    lastPerFloor = perFloor;
    lastScheme = scheme;
    return const [Unit(id: 'u1', label: '1A')];
  }
}

/// Portfolio controller whose refresh is a no-op.
class _FakePortfolio extends PortfolioController {
  @override
  Future<PortfolioSummary> build() async => const PortfolioSummary();

  @override
  Future<void> refresh() async {}
}
