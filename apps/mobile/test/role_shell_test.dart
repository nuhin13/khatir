import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:khatir_mobile/core/i18n/locale_provider.dart';
import 'package:khatir_mobile/core/widgets/k_bottom_nav.dart';
import 'package:khatir_mobile/features/shell/landlord_shell.dart';
import 'package:khatir_mobile/features/shell/manager_shell.dart';
import 'package:khatir_mobile/features/shell/tenant_shell.dart';
import 'package:khatir_mobile/features/shell/widgets/shell_placeholder.dart';
import 'package:khatir_mobile/l10n/app_localizations.dart';

/// Builds a [KShellPlaceholder] branch with a single route so tab switching can
/// be observed by the localized body text.
StatefulShellBranch _branch({
  required String path,
  required String name,
  required String Function(AppLocalizations) label,
}) {
  return StatefulShellBranch(
    routes: [
      GoRoute(
        path: path,
        name: name,
        builder: (context, state) =>
            KShellPlaceholder(tabLabel: label(AppLocalizations.of(context))),
      ),
    ],
  );
}

void main() {
  Widget harness(GoRouter router) {
    return MaterialApp.router(
      routerConfig: router,
      locale: kLocaleBn,
      supportedLocales: kSupportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }

  late AppLocalizations l10n;

  setUp(() async {
    l10n = await AppLocalizations.delegate.load(kLocaleBn);
  });

  testWidgets('landlord shell builds with its 5-slot nav and home branch',
      (tester) async {
    final router = GoRouter(
      initialLocation: '/landlord/home',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, shell) =>
              LandlordShell(navigationShell: shell),
          branches: [
            _branch(
              path: '/landlord/home',
              name: 'lHome',
              label: (l) => l.nav_home,
            ),
            _branch(
              path: '/landlord/dashboard',
              name: 'lDash',
              label: (l) => l.nav_charts,
            ),
            _branch(
              path: '/landlord/rent',
              name: 'lRent',
              label: (l) => l.nav_rent,
            ),
            _branch(
              path: '/landlord/more',
              name: 'lMore',
              label: (l) => l.nav_more,
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(harness(router));
    await tester.pumpAndSettle();

    expect(find.byType(LandlordShell), findsOneWidget);
    expect(find.byType(KBottomNav), findsOneWidget);
    // Home branch is the initial body.
    expect(
      find.text(l10n.shell_placeholder_coming_soon(l10n.nav_home)),
      findsOneWidget,
    );

    // Tap the Rent tab (nav slot 3) → branch body switches to rent.
    await tester.tap(find.text(l10n.nav_rent));
    await tester.pumpAndSettle();
    expect(
      find.text(l10n.shell_placeholder_coming_soon(l10n.nav_rent)),
      findsOneWidget,
    );
    expect(
      find.text(l10n.shell_placeholder_coming_soon(l10n.nav_home)),
      findsNothing,
    );
  });

  testWidgets('landlord center Add pushes /tenants/add (not a branch)',
      (tester) async {
    final router = GoRouter(
      initialLocation: '/landlord/home',
      routes: [
        GoRoute(
          path: '/tenants/add',
          name: 'tenantsAdd',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('ADD_TENANT')),
          ),
        ),
        StatefulShellRoute.indexedStack(
          builder: (context, state, shell) =>
              LandlordShell(navigationShell: shell),
          branches: [
            _branch(
              path: '/landlord/home',
              name: 'lHome',
              label: (l) => l.nav_home,
            ),
            _branch(
              path: '/landlord/dashboard',
              name: 'lDash',
              label: (l) => l.nav_charts,
            ),
            _branch(
              path: '/landlord/rent',
              name: 'lRent',
              label: (l) => l.nav_rent,
            ),
            _branch(
              path: '/landlord/more',
              name: 'lMore',
              label: (l) => l.nav_more,
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(harness(router));
    await tester.pumpAndSettle();

    await tester.tap(find.text(l10n.nav_add));
    await tester.pumpAndSettle();
    expect(find.text('ADD_TENANT'), findsOneWidget);
  });

  testWidgets('manager shell builds and switches branches', (tester) async {
    final router = GoRouter(
      initialLocation: '/manager/home',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, shell) =>
              ManagerShell(navigationShell: shell),
          branches: [
            _branch(
              path: '/manager/home',
              name: 'mHome',
              label: (l) => l.nav_home,
            ),
            _branch(
              path: '/manager/dashboard',
              name: 'mDash',
              label: (l) => l.nav_charts,
            ),
            _branch(
              path: '/manager/rent',
              name: 'mRent',
              label: (l) => l.nav_rent,
            ),
            _branch(
              path: '/manager/more',
              name: 'mMore',
              label: (l) => l.nav_more,
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(harness(router));
    await tester.pumpAndSettle();

    expect(find.byType(ManagerShell), findsOneWidget);
    expect(
      find.text(l10n.shell_placeholder_coming_soon(l10n.nav_home)),
      findsOneWidget,
    );

    await tester.tap(find.text(l10n.nav_more));
    await tester.pumpAndSettle();
    expect(
      find.text(l10n.shell_placeholder_coming_soon(l10n.nav_more)),
      findsOneWidget,
    );
  });

  testWidgets('tenant shell builds with 4 branches and switches tabs',
      (tester) async {
    final router = GoRouter(
      initialLocation: '/tenant/home',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, shell) =>
              TenantShell(navigationShell: shell),
          branches: [
            _branch(
              path: '/tenant/home',
              name: 'tHome',
              label: (l) => l.nav_home,
            ),
            _branch(
              path: '/tenant/maintenance',
              name: 'tMaint',
              label: (l) => l.nav_maintenance,
            ),
            _branch(
              path: '/tenant/receipts',
              name: 'tRcpt',
              label: (l) => l.nav_receipts,
            ),
            _branch(
              path: '/tenant/more',
              name: 'tMore',
              label: (l) => l.nav_more,
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(harness(router));
    await tester.pumpAndSettle();

    expect(find.byType(TenantShell), findsOneWidget);
    expect(
      find.text(l10n.shell_placeholder_coming_soon(l10n.nav_home)),
      findsOneWidget,
    );

    // Switch to the maintenance branch.
    await tester.tap(find.text(l10n.nav_maintenance));
    await tester.pumpAndSettle();
    expect(
      find.text(l10n.shell_placeholder_coming_soon(l10n.nav_maintenance)),
      findsOneWidget,
    );

    // And the receipts branch.
    await tester.tap(find.text(l10n.nav_receipts));
    await tester.pumpAndSettle();
    expect(
      find.text(l10n.shell_placeholder_coming_soon(l10n.nav_receipts)),
      findsOneWidget,
    );
  });
}
