import 'package:dio/dio.dart';
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
import 'package:khatir_mobile/features/rent/data/models/models.dart';
import 'package:khatir_mobile/features/rent/data/models/rent_enums.dart';
import 'package:khatir_mobile/features/rent/data/providers.dart';
import 'package:khatir_mobile/features/rent/data/rent_repository.dart';
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

/// Rent repository test double returning a fixed queue (no network), so the
/// home late-payers section settles deterministically.
class _FakeRentRepo extends RentRepository {
  _FakeRentRepo(this._queue) : super(Dio());

  final List<RentRequest> _queue;

  @override
  Future<List<RentRequest>> listQueue({RentRequestStatus? status}) async =>
      _queue;
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

  Widget harness({
    required Object portfolioResult,
    List<RentRequest> queue = const [],
  }) {
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
        GoRoute(
          path: '/rent/request',
          name: 'rentRequest',
          builder: (context, state) => Scaffold(
            body: Center(
              child: Text('RENT_REQUEST:${state.uri.queryParameters['lease']}'),
            ),
          ),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        localeStorageProvider.overrideWithValue(_FakeSecureStorage()),
        authControllerProvider.overrideWith(() => _FakeAuth(seedUser)),
        portfolioProvider.overrideWith(() => _FakePortfolio(portfolioResult)),
        rentRepositoryProvider.overrideWithValue(_FakeRentRepo(queue)),
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

  void tallView(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 3200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('late-payers section lists overdue requests', (tester) async {
    tallView(tester);
    const queue = [
      RentRequest(
        id: 'r1',
        leaseId: 'l1',
        amount: 22000,
        period: '2025-05',
      ),
      RentRequest(
        id: 'r2',
        leaseId: 'l2',
        amount: 18000,
        period: '2025-05',
        status: RentRequestStatus.proofSubmitted,
      ),
      // Settled requests must NOT show as late payers.
      RentRequest(
        id: 'r3',
        leaseId: 'l3',
        amount: 9000,
        status: RentRequestStatus.verified,
      ),
    ];
    await tester
        .pumpWidget(harness(portfolioResult: populated, queue: queue));
    await tester.pumpAndSettle();

    // Heading shows the unpaid count (2), not all three.
    expect(find.text(bn.home_late_payers('২')), findsOneWidget);
    // Two overdue rows, one per unpaid request.
    expect(find.byKey(const ValueKey('latePayer_r1')), findsOneWidget);
    expect(find.byKey(const ValueKey('latePayer_r2')), findsOneWidget);
    expect(find.byKey(const ValueKey('latePayer_r3')), findsNothing);
    expect(find.text(bn.home_quick_request), findsNWidgets(2));
    // The "all paid" reassurance is not shown when there are late payers.
    expect(find.text(bn.home_all_paid), findsNothing);
  });

  testWidgets('quick-request routes to the rent-request flow', (tester) async {
    tallView(tester);
    const queue = [
      RentRequest(id: 'r1', leaseId: 'l1', amount: 22000, period: '2025-05'),
    ];
    await tester
        .pumpWidget(harness(portfolioResult: populated, queue: queue));
    await tester.pumpAndSettle();

    // The row's "Ask" pill carries the lease into the rent-request route.
    await tester.tap(find.text(bn.home_quick_request));
    await tester.pumpAndSettle();

    expect(find.text('RENT_REQUEST:l1'), findsOneWidget);
  });

  testWidgets('late-payers section shows all-paid when queue is empty',
      (tester) async {
    await tester.pumpWidget(
      harness(portfolioResult: populated, queue: const []),
    );
    await tester.pumpAndSettle();

    expect(find.text(bn.home_all_paid), findsOneWidget);
    expect(find.text(bn.home_quick_request), findsNothing);
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
