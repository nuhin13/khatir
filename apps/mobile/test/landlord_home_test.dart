import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khatir_mobile/core/auth/auth_controller.dart';
import 'package:khatir_mobile/core/auth/auth_state.dart';
import 'package:khatir_mobile/core/enums/role.dart';
import 'package:khatir_mobile/core/i18n/locale_provider.dart';
import 'package:khatir_mobile/features/properties/data/models/portfolio_summary.dart';
import 'package:khatir_mobile/features/properties/data/properties_providers.dart';
import 'package:khatir_mobile/features/properties/presentation/screens/landlord_home_screen.dart';
import 'package:khatir_mobile/l10n/app_localizations.dart';

/// Portfolio controller test double that resolves to a fixed [PortfolioSummary]
/// (or throws) without a network round-trip, so the home screen's
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

/// Auth controller test double seeding an authenticated landlord so the
/// greeting can render a real name.
class _FakeAuth extends AuthController {
  _FakeAuth(this._seed);

  final SessionUser _seed;

  @override
  Future<AuthState> build() async =>
      AuthState(status: AuthStatus.authenticated, user: _seed);
}

void main() {
  const seedUser = SessionUser(
    id: 'u1',
    name: 'করিম সাহেব',
    phone: '+8801711000111',
    role: Role.landlord,
  );

  const populated = PortfolioSummary(
    buildings: [
      BuildingSummary(id: 'b1', name: 'করিম মঞ্জিল', totalUnits: 8, occupied: 7),
    ],
    totals: PortfolioTotals(
      buildings: 2,
      totalUnits: 14,
      occupied: 11,
      totalRent: 97000,
    ),
  );

  const empty = PortfolioSummary();

  Widget harness({required Object portfolioResult}) {
    final router = GoRouter(
      initialLocation: '/landlord/home',
      routes: [
        GoRoute(
          path: '/landlord/home',
          builder: (context, state) => const LandlordHomeScreen(),
        ),
        GoRoute(
          path: '/tenants/add',
          name: 'tenantsAdd',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('ADD_TENANT'))),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        localeStorageProvider.overrideWithValue(_FakeSecureStorage()),
        authControllerProvider.overrideWith(() => _FakeAuth(seedUser)),
        portfolioProvider.overrideWith(() => _FakePortfolio(portfolioResult)),
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

  testWidgets('data state renders greeting, DMP CTA and stat tiles',
      (tester) async {
    await tester.pumpWidget(harness(portfolioResult: populated));
    await tester.pumpAndSettle();

    // Greeting with the signed-in name.
    expect(find.text(bn.home_greeting), findsOneWidget);
    expect(find.text('করিম সাহেব'), findsOneWidget);

    // Hero DMP CTA.
    expect(find.text(bn.home_dmp_cta), findsOneWidget);
    expect(find.text(bn.home_dmp_cta_action), findsOneWidget);

    // Quick stat tiles + collection card heading.
    expect(find.text(bn.home_stat_buildings), findsOneWidget);
    expect(find.text(bn.home_stat_units), findsOneWidget);
    expect(find.text(bn.home_stat_monthly), findsOneWidget);
    expect(find.text(bn.home_collected), findsOneWidget);
  });

  testWidgets('tapping the DMP CTA routes to add-tenant', (tester) async {
    await tester.pumpWidget(harness(portfolioResult: populated));
    await tester.pumpAndSettle();

    await tester.tap(find.text(bn.home_dmp_cta_action));
    await tester.pumpAndSettle();

    expect(find.text('ADD_TENANT'), findsOneWidget);
  });

  testWidgets('empty state shows add-building CTA when no buildings',
      (tester) async {
    await tester.pumpWidget(harness(portfolioResult: empty));
    await tester.pumpAndSettle();

    expect(find.text(bn.home_empty_title), findsOneWidget);
    expect(find.text(bn.home_add_building), findsOneWidget);
    // The hero CTA is not shown in the empty state.
    expect(find.text(bn.home_dmp_cta), findsNothing);
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
