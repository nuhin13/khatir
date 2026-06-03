import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khatir_mobile/core/i18n/locale_provider.dart';
import 'package:khatir_mobile/features/properties/data/models/portfolio_summary.dart';
import 'package:khatir_mobile/features/properties/data/models/property_enums.dart';
import 'package:khatir_mobile/features/properties/data/models/unit.dart';
import 'package:khatir_mobile/features/properties/data/properties_providers.dart';
import 'package:khatir_mobile/features/properties/presentation/screens/portfolio_screen.dart';
import 'package:khatir_mobile/l10n/app_localizations.dart';

/// Portfolio controller test double that resolves to a fixed [PortfolioSummary]
/// (or throws) without a network round-trip, so the portfolio screen's
/// loading/data/empty/error branches can be exercised in isolation.
class _FakePortfolio extends PortfolioController {
  _FakePortfolio(this._result);

  final Object _result;

  @override
  Future<PortfolioSummary> build() async {
    if (_result is PortfolioSummary) return _result;
    throw _result;
  }
}

/// Building-units test double returning a fixed list for any building id, so
/// expanding a card and tapping a unit chip can be exercised offline.
class _FakeUnits extends BuildingUnitsController {
  _FakeUnits(this._units);

  final List<Unit> _units;

  @override
  Future<List<Unit>> build(String buildingId) async => _units;
}

void main() {
  const populated = PortfolioSummary(
    buildings: [
      BuildingSummary(
        id: 'b1',
        name: 'করিম মঞ্জিল',
        area: Area.mirpur,
        totalUnits: 8,
        occupied: 7,
        totalRent: 57000,
      ),
      BuildingSummary(
        id: 'b2',
        name: 'রহিম ভিলা',
        area: Area.uttara,
        totalUnits: 6,
        occupied: 4,
        totalRent: 40000,
      ),
    ],
    totals: PortfolioTotals(
      buildings: 2,
      totalUnits: 14,
      occupied: 11,
      totalRent: 97000,
    ),
  );

  const empty = PortfolioSummary();

  const units = [
    Unit(id: 'u1', label: '1A', status: UnitStatus.occupied),
    Unit(id: 'u2', label: '1B', status: UnitStatus.vacant),
  ];

  Widget harness({required Object portfolioResult}) {
    final router = GoRouter(
      initialLocation: '/properties',
      routes: [
        GoRoute(
          path: '/properties',
          name: 'portfolio',
          builder: (context, state) => const PortfolioScreen(),
          routes: [
            GoRoute(
              path: 'unit/:id',
              name: 'propertiesUnit',
              builder: (context, state) => Scaffold(
                body: Center(
                  child: Text('UNIT_${state.pathParameters['id']}'),
                ),
              ),
            ),
          ],
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        localeStorageProvider.overrideWithValue(_FakeSecureStorage()),
        portfolioProvider.overrideWith(() => _FakePortfolio(portfolioResult)),
        buildingUnitsProvider.overrideWith(() => _FakeUnits(units)),
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

  testWidgets('data state renders building cards with counts', (tester) async {
    await tester.pumpWidget(harness(portfolioResult: populated));
    await tester.pumpAndSettle();

    // Both buildings render by name.
    expect(find.text('করিম মঞ্জিল'), findsOneWidget);
    expect(find.text('রহিম ভিলা'), findsOneWidget);

    // Summary stat labels + per-building footer labels.
    expect(find.text(bn.portfolio_stat_buildings), findsOneWidget);
    expect(find.text(bn.portfolio_stat_occupied), findsOneWidget);
    expect(find.text(bn.portfolio_units), findsNWidgets(2));
    expect(find.text(bn.portfolio_add_building), findsWidgets);
  });

  testWidgets('expanding a card loads units and tapping a chip navigates',
      (tester) async {
    await tester.pumpWidget(harness(portfolioResult: populated));
    await tester.pumpAndSettle();

    // Units are hidden until the card is expanded.
    expect(find.text('1A'), findsNothing);

    await tester.tap(find.text('করিম মঞ্জিল'));
    await tester.pumpAndSettle();

    expect(find.text('1A'), findsOneWidget);
    expect(find.text('1B'), findsOneWidget);

    await tester.tap(find.text('1A'));
    await tester.pumpAndSettle();

    expect(find.text('UNIT_u1'), findsOneWidget);
  });

  testWidgets('empty state shows add-building CTA when no buildings',
      (tester) async {
    await tester.pumpWidget(harness(portfolioResult: empty));
    await tester.pumpAndSettle();

    expect(find.text(bn.portfolio_empty_title), findsOneWidget);
    expect(find.text(bn.portfolio_add_building), findsWidgets);
    // No building cards in the empty state.
    expect(find.text('করিম মঞ্জিল'), findsNothing);
  });

  testWidgets('error state shows retry', (tester) async {
    await tester.pumpWidget(harness(portfolioResult: Exception('boom')));
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
