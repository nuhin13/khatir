import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khatir_mobile/core/i18n/locale_provider.dart';
import 'package:khatir_mobile/core/theme/app_theme.dart';
import 'package:khatir_mobile/core/widgets/k_bottom_nav.dart';
import 'package:khatir_mobile/features/shell/shell_nav_config.dart';
import 'package:khatir_mobile/l10n/app_localizations.dart';
import 'package:khatir_tokens/khatir_tokens.dart';

/// Wraps a widget with the localization delegates so [AppLocalizations] resolves
/// during the test.
Widget _harness(Widget child) {
  return MaterialApp(
    locale: kLocaleEn,
    supportedLocales: kSupportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: Scaffold(bottomNavigationBar: child),
  );
}

/// Finds the indicator [Container] sitting behind [icon] inside a nav tile.
Container _indicatorFor(WidgetTester tester, IconData icon) {
  final iconFinder = find.widgetWithIcon(Container, icon);
  expect(iconFinder, findsOneWidget);
  return tester.widget<Container>(iconFinder);
}

void main() {
  late AppLocalizations l10n;

  setUp(() async {
    l10n = await AppLocalizations.delegate.load(kLocaleEn);
  });

  testWidgets('renders all 5 landlord slots with their labels',
      (tester) async {
    final config = ShellNavConfig.landlord;
    await tester.pumpWidget(
      _harness(
        KBottomNav(
          currentIndex: config.slotForBranch(0),
          onTap: (_) {},
          items: [
            for (final s in config.slots)
              KBottomNavItem(icon: s.icon, label: s.label(l10n), fab: s.fab),
          ],
        ),
      ),
    );

    expect(find.text(l10n.nav_home), findsOneWidget);
    expect(find.text(l10n.nav_charts), findsOneWidget);
    expect(find.text(l10n.nav_add), findsOneWidget);
    expect(find.text(l10n.nav_rent), findsOneWidget);
    expect(find.text(l10n.nav_more), findsOneWidget);
  });

  testWidgets('active slot shows a sage-bg highlight; others do not',
      (tester) async {
    final config = ShellNavConfig.landlord;
    await tester.pumpWidget(
      _harness(
        KBottomNav(
          // Home branch active → its visual slot highlighted.
          currentIndex: config.slotForBranch(0),
          onTap: (_) {},
          items: [
            for (final s in config.slots)
              KBottomNavItem(icon: s.icon, label: s.label(l10n), fab: s.fab),
          ],
        ),
      ),
    );

    final homeIndicator = _indicatorFor(tester, Icons.home_outlined);
    final homeDecoration = homeIndicator.decoration! as BoxDecoration;
    expect(homeDecoration.color, KhatirColors.sageBg);

    final rentIndicator = _indicatorFor(tester, Icons.payments_outlined);
    final rentDecoration = rentIndicator.decoration! as BoxDecoration;
    expect(rentDecoration.color, Colors.transparent);
  });

  testWidgets('center FAB renders filled sage and fires its onTap slot',
      (tester) async {
    final config = ShellNavConfig.landlord;
    int? tappedSlot;
    await tester.pumpWidget(
      _harness(
        KBottomNav(
          currentIndex: config.slotForBranch(0),
          onTap: (slot) => tappedSlot = slot,
          items: [
            for (final s in config.slots)
              KBottomNavItem(icon: s.icon, label: s.label(l10n), fab: s.fab),
          ],
        ),
      ),
    );

    // The Add slot renders as a filled-sage FAB.
    final fabIndicator = _indicatorFor(tester, Icons.add);
    final fabDecoration = fabIndicator.decoration! as BoxDecoration;
    expect(fabDecoration.color, KhatirColors.sage);
    expect(fabDecoration.boxShadow, AppTheme.sageShadow);

    await tester.tap(find.text(l10n.nav_add));
    expect(tappedSlot, config.fabSlot);
  });

  testWidgets('tenant config is a 4-slot layout with no FAB action',
      (tester) async {
    final config = ShellNavConfig.tenant;
    expect(config.slots.length, 4);
    expect(config.fabSlot, isNull);
    expect(config.fabRouteName, isNull);
    expect(config.branchForSlot(0), 0);

    await tester.pumpWidget(
      _harness(
        KBottomNav(
          currentIndex: config.slotForBranch(0),
          onTap: (_) {},
          items: [
            for (final s in config.slots)
              KBottomNavItem(icon: s.icon, label: s.label(l10n), fab: s.fab),
          ],
        ),
      ),
    );

    expect(find.text(l10n.nav_home), findsOneWidget);
    expect(find.text(l10n.nav_maintenance), findsOneWidget);
    expect(find.text(l10n.nav_receipts), findsOneWidget);
    expect(find.text(l10n.nav_more), findsOneWidget);
    expect(find.text(l10n.nav_add), findsNothing);
  });

  test('landlord branch↔slot mapping leaves the FAB slot free', () {
    final config = ShellNavConfig.landlord;
    expect(config.fabSlot, 2);
    expect(config.fabRouteName, 'tenantsAdd');
    // Branch 0,1,2,3 → slots 0,1,3,4 (slot 2 reserved for the FAB).
    expect(config.branchToSlot, [0, 1, 3, 4]);
    expect(config.branchForSlot(2), isNull); // FAB slot is not a branch.
    expect(config.branchForSlot(3), 2); // rent slot → rent branch.
  });
}
