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
import 'package:khatir_mobile/features/manager/data/manager_providers.dart';
import 'package:khatir_mobile/features/manager/data/manager_repository.dart';
import 'package:khatir_mobile/features/manager/data/models/manager_models.dart';
import 'package:khatir_mobile/features/manager/presentation/screens/mgr_add_owner_screen.dart';
import 'package:khatir_mobile/features/manager/presentation/screens/mgr_home_screen.dart';
import 'package:khatir_mobile/features/manager/presentation/screens/mgr_team_screen.dart';
import 'package:khatir_mobile/l10n/app_localizations.dart';

// ── Fake repositories ────────────────────────────────────────────────────────

class _FakeManagerRepository extends ManagerRepository {
  _FakeManagerRepository({
    required this.owners,
    required this.team,
    this.failRequest = false,
  }) : super(Dio());

  final List<LinkedOwner> owners;
  final List<TeamMember> team;
  final bool failRequest;

  @override
  Future<List<LinkedOwner>> listOwners() async => owners;

  @override
  Future<void> requestOwner({
    required String ownerPhone,
    required String ownerName,
    required List<String> permissions,
  }) async {
    if (failRequest) throw Exception('network error');
  }

  @override
  Future<List<TeamMember>> listTeam() async => team;

  @override
  Future<TeamMember> addTeamMember({
    required String phone,
    required String name,
    required String role,
    List<String>? scopeOwnerIds,
  }) async =>
      TeamMember(
        id: 'new_m',
        name: name,
        phone: phone,
        role: role,
      );

  @override
  Future<void> removeTeamMember(String memberId) async {
    if (failRequest) throw Exception('network error');
  }
}

// ── Fake auth controller ─────────────────────────────────────────────────────

class _FakeAuth extends AuthController {
  _FakeAuth(this._user);
  final SessionUser _user;

  @override
  Future<AuthState> build() async =>
      AuthState(status: AuthStatus.authenticated, user: _user);
}

// ── Fake secure storage ──────────────────────────────────────────────────────

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

// ── Fake owners controller ───────────────────────────────────────────────────

class _FakeOwnersController extends ManagerOwnersController {
  _FakeOwnersController(this._result);
  final Object _result;

  @override
  Future<List<LinkedOwner>> build() async {
    if (_result is Exception) throw _result;
    return _result as List<LinkedOwner>;
  }
}

// ── Fake team controller ─────────────────────────────────────────────────────

class _FakeTeamController extends ManagerTeamController {
  _FakeTeamController(this._result);
  final Object _result;

  @override
  Future<List<TeamMember>> build() async {
    if (_result is Exception) throw _result;
    return _result as List<TeamMember>;
  }
}

// ── Test data ────────────────────────────────────────────────────────────────

const _seedUser = SessionUser(
  id: 'u1',
  name: 'Manager User',
  phone: '+8801711000000',
  role: Role.manager,
);

const _active1 = LinkedOwner(
  id: 'o1',
  ownerName: 'Karim Saheb',
  ownerPhone: '01711000001',
  status: 'active',
  unitCount: 8,
  occupiedCount: 6,
  monthlyRent: 40000,
);

const _active2 = LinkedOwner(
  id: 'o2',
  ownerName: 'Rahim Bhai',
  ownerPhone: '01711000002',
  status: 'active',
  unitCount: 4,
  occupiedCount: 3,
  monthlyRent: 20000,
);

const _pending = LinkedOwner(
  id: 'op',
  ownerName: 'Pending Owner',
  ownerPhone: '01811000003',
  status: 'pending',
);

const _member1 = TeamMember(
  id: 'm1',
  name: 'Abir Hasan',
  phone: '01611000001',
  role: 'accountant',
  scopeOwnerIds: ['o1'],
);

// ── Harness builder ──────────────────────────────────────────────────────────

Widget _harness({
  required String initialLocation,
  required List<RouteBase> routes,
  required List<Override> overrides,
}) {
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: routes,
  );
  return ProviderScope(
    overrides: [
      localeStorageProvider.overrideWithValue(_FakeSecureStorage()),
      authControllerProvider.overrideWith(() => _FakeAuth(_seedUser)),
      ...overrides,
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

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  late AppLocalizations l10n;

  setUp(() async {
    l10n = await AppLocalizations.delegate.load(kLocaleBn);
  });

  // ── MgrHomeScreen ──────────────────────────────────────────────────────────

  group('MgrHomeScreen', () {
    Widget homeHarness(Object ownersResult) => _harness(
          initialLocation: '/manager/home',
          routes: [
            GoRoute(
              path: '/manager/home',
              builder: (_, __) => const MgrHomeScreen(),
            ),
            GoRoute(
              path: '/manager/home/add-owner',
              name: 'managerAddOwner',
              builder: (_, __) => const Scaffold(
                body: Center(child: Text('ADD_OWNER')),
              ),
            ),
            GoRoute(
              path: '/manager/home/team',
              name: 'managerTeam',
              builder: (_, __) => const Scaffold(
                body: Center(child: Text('TEAM')),
              ),
            ),
            GoRoute(
              path: '/manager/home/report',
              name: 'managerReport',
              builder: (_, __) => const Scaffold(
                body: Center(child: Text('REPORT')),
              ),
            ),
          ],
          overrides: [
            managerOwnersProvider.overrideWith(
              () => _FakeOwnersController(ownersResult),
            ),
          ],
        );

    testWidgets('data state renders only active owner cards', (tester) async {
      // SCOPING: pending owners must NOT appear on the home screen.
      await tester.pumpWidget(
        homeHarness([_active1, _active2, _pending]),
      );
      await tester.pumpAndSettle();

      // Active owners are visible.
      expect(find.text('Karim Saheb'), findsOneWidget);
      expect(find.text('Rahim Bhai'), findsOneWidget);

      // Pending owner is NOT shown (scoping gate).
      expect(find.text('Pending Owner'), findsNothing);
    });

    testWidgets('empty state shown when no active owners', (tester) async {
      // Only pending — active list is empty → empty state.
      await tester.pumpWidget(homeHarness([_pending]));
      await tester.pumpAndSettle();

      expect(find.text(l10n.mgr_home_empty), findsOneWidget);
    });

    testWidgets('error state shows retry', (tester) async {
      await tester.pumpWidget(homeHarness(Exception('boom')));
      await tester.pumpAndSettle();

      expect(find.text(l10n.common_retry), findsOneWidget);
    });

    testWidgets('quick-action chips route to team and report screens',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(homeHarness([_active1]));
      await tester.pumpAndSettle();

      await tester.tap(find.text(l10n.mgr_home_team));
      await tester.pumpAndSettle();
      expect(find.text('TEAM'), findsOneWidget);
    });
  });

  // ── MgrAddOwnerScreen ──────────────────────────────────────────────────────

  group('MgrAddOwnerScreen', () {
    Widget addOwnerHarness(List<LinkedOwner> owners) => _harness(
          initialLocation: '/manager/add-owner',
          routes: [
            GoRoute(
              path: '/manager/add-owner',
              builder: (_, __) => const MgrAddOwnerScreen(),
            ),
          ],
          overrides: [
            managerOwnersProvider.overrideWith(
              () => _FakeOwnersController(owners),
            ),
            managerRepositoryProvider.overrideWithValue(
              _FakeManagerRepository(owners: owners, team: const []),
            ),
          ],
        );

    testWidgets('renders phone and name fields with send button', (tester) async {
      await tester.pumpWidget(addOwnerHarness(const []));
      await tester.pumpAndSettle();

      expect(find.text(l10n.mgr_add_owner_hero), findsOneWidget);
      expect(find.text(l10n.mgr_add_owner_request), findsOneWidget);
    });

    testWidgets('pending section visible; active section visible', (tester) async {
      await tester.pumpWidget(addOwnerHarness([_active1, _pending]));
      await tester.pumpAndSettle();

      expect(find.text(l10n.mgr_add_owner_pending), findsOneWidget);
      expect(find.text(l10n.mgr_add_owner_active), findsOneWidget);
      // Pending owner shown in the pending section.
      expect(find.text('Pending Owner'), findsOneWidget);
      // Active owner shown in the active section.
      expect(find.text('Karim Saheb'), findsOneWidget);
    });
  });

  // ── MgrTeamScreen ──────────────────────────────────────────────────────────

  group('MgrTeamScreen', () {
    Widget teamHarness(Object teamResult) => _harness(
          initialLocation: '/manager/team',
          routes: [
            GoRoute(
              path: '/manager/team',
              builder: (_, __) => const MgrTeamScreen(),
            ),
          ],
          overrides: [
            managerTeamProvider.overrideWith(
              () => _FakeTeamController(teamResult),
            ),
            managerRepositoryProvider.overrideWithValue(
              _FakeManagerRepository(owners: const [], team: const []),
            ),
          ],
        );

    testWidgets('renders team member with role and scope', (tester) async {
      await tester.pumpWidget(teamHarness([_member1]));
      await tester.pumpAndSettle();

      expect(find.text('Abir Hasan'), findsOneWidget);
    });

    testWidgets('empty state shown when no team members', (tester) async {
      await tester.pumpWidget(teamHarness(const <TeamMember>[]));
      await tester.pumpAndSettle();

      expect(find.text(l10n.mgr_team_empty), findsOneWidget);
    });

    testWidgets('error state shows retry', (tester) async {
      await tester.pumpWidget(teamHarness(Exception('boom')));
      await tester.pumpAndSettle();

      expect(find.text(l10n.common_retry), findsOneWidget);
    });
  });
}
