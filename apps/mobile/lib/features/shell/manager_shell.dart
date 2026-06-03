import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:khatir_tokens/khatir_tokens.dart';

import '../../core/widgets/k_bottom_nav.dart';
import '../../l10n/app_localizations.dart';

/// Manager role shell. Same 5-slot nav structure as the landlord shell (home,
/// dashboard, Add, rent, more); branch bodies are stubbed until EPIC-22 fills
/// the manager experience.
class ManagerShell extends StatelessWidget {
  const ManagerShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const int _addSlot = 2;
  static const List<int> _branchToSlot = [0, 1, 3, 4];

  int get _currentSlot => _branchToSlot[navigationShell.currentIndex];

  void _onSlotTap(BuildContext context, int slot) {
    if (slot == _addSlot) {
      // TODO(EPIC-04) point at the real /tenants/add wizard entry.
      context.pushNamed('tenantsAdd');
      return;
    }
    final branch = _branchToSlot.indexOf(slot);
    navigationShell.goBranch(
      branch,
      initialLocation: branch == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: KhatirColors.cream,
      body: navigationShell,
      bottomNavigationBar: KBottomNav(
        currentIndex: _currentSlot,
        onTap: (slot) => _onSlotTap(context, slot),
        items: [
          KBottomNavItem(icon: Icons.home_outlined, label: l10n.nav_home),
          KBottomNavItem(
            icon: Icons.bar_chart_outlined,
            label: l10n.nav_charts,
          ),
          KBottomNavItem(icon: Icons.add, label: l10n.nav_add),
          KBottomNavItem(
            icon: Icons.payments_outlined,
            label: l10n.nav_rent,
          ),
          KBottomNavItem(icon: Icons.menu, label: l10n.nav_more),
        ],
      ),
    );
  }
}
