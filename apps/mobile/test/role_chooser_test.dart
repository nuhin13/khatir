import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khatir_mobile/core/enums/role.dart';
import 'package:khatir_mobile/core/i18n/locale_provider.dart';
import 'package:khatir_mobile/core/network/api_exception.dart';
import 'package:khatir_mobile/features/profile/data/models/profile.dart';
import 'package:khatir_mobile/features/profile/data/profile_providers.dart';
import 'package:khatir_mobile/features/role/presentation/screens/role_chooser_screen.dart';
import 'package:khatir_mobile/features/role/presentation/widgets/role_card.dart';
import 'package:khatir_mobile/l10n/app_localizations.dart';

/// Test double for the profile controller: records the role passed to
/// [setRole] without touching the network or auth state, so the role chooser
/// can be exercised in isolation. When [shouldFail] is set, [setRole] throws an
/// [ApiException] to drive the error path.
class _FakeProfileController extends ProfileController {
  _FakeProfileController({this.shouldFail = false});

  final bool shouldFail;
  Role? capturedRole;

  static const _profile = Profile(id: 'u1');

  @override
  Future<Profile> build() async => _profile;

  @override
  Future<Profile> setRole(Role role) async {
    capturedRole = role;
    if (shouldFail) {
      throw const ApiException(message: 'boom', statusCode: 500);
    }
    state = const AsyncValue.data(_profile);
    return _profile;
  }
}

void main() {
  late _FakeProfileController controller;
  late GoRouter router;

  Widget harness({bool shouldFail = false}) {
    controller = _FakeProfileController(shouldFail: shouldFail);
    router = GoRouter(
      initialLocation: RoleChooserScreen.routePath,
      routes: [
        GoRoute(
          path: RoleChooserScreen.routePath,
          builder: (context, state) => const RoleChooserScreen(),
        ),
        GoRoute(
          path: '/landlord/home',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('LANDLORD_HOME'))),
        ),
        GoRoute(
          path: '/manager/home',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('MANAGER_HOME'))),
        ),
        GoRoute(
          path: '/tenant/home',
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('TENANT_HOME'))),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        profileProvider.overrideWith(() => controller),
      ],
      child: MaterialApp.router(
        routerConfig: router,
        locale: kLocaleBn,
        supportedLocales: kSupportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
      ),
    );
  }

  late AppLocalizations l10n;

  setUp(() async {
    l10n = await AppLocalizations.delegate.load(kLocaleBn);
  });

  testWidgets('renders three role cards with the most-common badge',
      (tester) async {
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    expect(find.byType(RoleCard), findsNWidgets(3));
    expect(find.text(l10n.role_landlord_bn), findsOneWidget);
    expect(find.text(l10n.role_manager_bn), findsOneWidget);
    expect(find.text(l10n.role_tenant_bn), findsOneWidget);
    // Recommended badge on the landlord card.
    expect(find.text(l10n.role_most_common), findsOneWidget);
  });

  testWidgets('tapping landlord persists the role and routes to its shell',
      (tester) async {
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    await tester.tap(find.text(l10n.role_landlord_bn));
    await tester.pumpAndSettle();

    expect(controller.capturedRole, Role.landlord);
    expect(find.text('LANDLORD_HOME'), findsOneWidget);
  });

  testWidgets('tapping manager persists manager and routes to manager shell',
      (tester) async {
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    await tester.tap(find.text(l10n.role_manager_bn));
    await tester.pumpAndSettle();

    expect(controller.capturedRole, Role.manager);
    expect(find.text('MANAGER_HOME'), findsOneWidget);
  });

  testWidgets('a failed persist surfaces an error and stays on the chooser',
      (tester) async {
    await tester.pumpWidget(harness(shouldFail: true));
    await tester.pumpAndSettle();

    await tester.tap(find.text(l10n.role_tenant_bn));
    await tester.pumpAndSettle();

    expect(controller.capturedRole, Role.tenant);
    // Did not navigate away.
    expect(find.byType(RoleCard), findsNWidgets(3));
    expect(find.text('TENANT_HOME'), findsNothing);
    // Error feedback shown.
    expect(find.text(l10n.common_network_error), findsOneWidget);
  });
}
