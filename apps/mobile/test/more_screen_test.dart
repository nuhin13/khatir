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
import 'package:khatir_mobile/features/profile/presentation/screens/more_screen.dart';
import 'package:khatir_mobile/features/profile/presentation/widgets/more_row.dart';
import 'package:khatir_mobile/l10n/app_localizations.dart';

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

/// Auth controller test double: seeds an authenticated [SessionUser] without a
/// network round-trip and records whether [logout] ran (clearing the session)
/// so the More screen can be exercised in isolation.
class _FakeAuthController extends AuthController {
  _FakeAuthController(this._seed);

  final SessionUser _seed;
  bool didLogout = false;

  @override
  Future<AuthState> build() async =>
      AuthState(status: AuthStatus.authenticated, user: _seed);

  @override
  Future<void> logout() async {
    didLogout = true;
    state = const AsyncValue.data(AuthState.unauthenticated);
  }
}

void main() {
  late _FakeAuthController auth;

  const seedUser = SessionUser(
    id: 'u1',
    name: 'করিম সাহেব',
    phone: '+8801711000111',
    role: Role.landlord,
  );

  Widget harness({Role role = Role.landlord, SessionUser? user}) {
    auth = _FakeAuthController(user ?? seedUser);
    final router = GoRouter(
      initialLocation: '/more',
      routes: [
        GoRoute(
          path: '/more',
          builder: (context, state) => MoreScreen.forRole(role),
        ),
        GoRoute(
          path: '/role',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('ROLE_CHOOSER'))),
        ),
        GoRoute(
          path: '/onboarding',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('ONBOARDING'))),
        ),
        GoRoute(
          path: '/auth/phone',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('PHONE_ENTRY'))),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        localeStorageProvider.overrideWithValue(_FakeSecureStorage()),
        authControllerProvider.overrideWith(() => auth),
      ],
      // Re-read the active locale so a language toggle rebuilds the subtree.
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
  late AppLocalizations en;

  setUp(() async {
    bn = await AppLocalizations.delegate.load(kLocaleBn);
    en = await AppLocalizations.delegate.load(kLocaleEn);
  });

  testWidgets('landlord more renders the full row set + profile header',
      (tester) async {
    await tester.pumpWidget(harness(role: Role.landlord));
    await tester.pumpAndSettle();

    // Profile header: name + plan chip.
    expect(find.text('করিম সাহেব'), findsOneWidget);
    expect(find.text(bn.more_plan_chip), findsOneWidget);

    // Landlord sees all rows including the landlord-only lease + warnings.
    expect(find.byType(MoreRow), findsNWidgets(7));
    expect(find.text(bn.more_profile), findsOneWidget);
    expect(find.text(bn.more_plan), findsOneWidget);
    expect(find.text(bn.more_lease), findsOneWidget);
    expect(find.text(bn.more_warnings), findsOneWidget);
    expect(find.text(bn.more_language), findsOneWidget);
    expect(find.text(bn.more_switch_role), findsOneWidget);
    expect(find.text(bn.more_about), findsOneWidget);
    expect(find.text(bn.more_logout), findsOneWidget);
  });

  testWidgets('tenant more omits the landlord-only lease + warnings rows',
      (tester) async {
    await tester.pumpWidget(harness(
      role: Role.tenant,
      user: const SessionUser(id: 't1', name: 'রিয়া', role: Role.tenant),
    ));
    await tester.pumpAndSettle();

    expect(find.byType(MoreRow), findsNWidgets(5));
    expect(find.text(bn.more_lease), findsNothing);
    expect(find.text(bn.more_warnings), findsNothing);
    // Still has the common rows.
    expect(find.text(bn.more_profile), findsOneWidget);
    expect(find.text(bn.more_language), findsOneWidget);
  });

  testWidgets('tapping language toggles the locale in place (bn → en)',
      (tester) async {
    await tester.pumpWidget(harness(role: Role.landlord));
    await tester.pumpAndSettle();

    // Starts in Bangla.
    expect(find.text(bn.more_logout), findsOneWidget);

    await tester.tap(find.text(bn.more_language));
    await tester.pumpAndSettle();

    // Locale flipped to English in place — no route change, English copy shows.
    expect(find.text(en.more_logout), findsOneWidget);
    expect(find.text(en.more_warnings), findsOneWidget);
  });

  testWidgets('tapping logout clears the session and routes to phone entry',
      (tester) async {
    await tester.pumpWidget(harness(role: Role.landlord));
    await tester.pumpAndSettle();

    // The logout button sits at the foot of a scrollable column; bring it
    // on-screen before tapping so the hit-test lands on the button.
    await tester.ensureVisible(find.text(bn.more_logout));
    await tester.pumpAndSettle();
    await tester.tap(find.text(bn.more_logout));
    await tester.pumpAndSettle();

    expect(auth.didLogout, isTrue);
    expect(find.text('PHONE_ENTRY'), findsOneWidget);
  });

  testWidgets('switch role routes to the role chooser', (tester) async {
    await tester.pumpWidget(harness(role: Role.landlord));
    await tester.pumpAndSettle();

    await tester.tap(find.text(bn.more_switch_role));
    await tester.pumpAndSettle();

    expect(find.text('ROLE_CHOOSER'), findsOneWidget);
  });
}
