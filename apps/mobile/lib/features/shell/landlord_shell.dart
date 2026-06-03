import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:khatir_tokens/khatir_tokens.dart';

import '../../core/widgets/k_bottom_nav.dart';
import '../../l10n/app_localizations.dart';

/// Landlord role shell. Hosts four bottom-nav branches (home, dashboard, rent,
/// more) in an indexed stack so each tab keeps its own navigation history, plus
/// a center "Add" action that is NOT a branch — it pushes the add-tenant flow.
///
/// Branch bodies are placeholders until their epics land (see [app_router]).
class LandlordShell extends StatelessWidget {
  const LandlordShell({super.key, required this.navigationShell});

  /// The go_router shell driving the indexed stack of branches.
  final StatefulNavigationShell navigationShell;

  /// Visual nav slot of the center Add action. Branch slots sit either side; the
  /// 4 branches occupy nav slots 0,1,3,4 while slot 2 is the Add action.
  static const int _addSlot = 2;

  /// Maps a branch index (0..3) to its nav slot (0,1,3,4) so the Add action can
  /// live in the middle without being a navigation branch.
  static const List<int> _branchToSlot = [0, 1, 3, 4];

  int get _currentSlot => _branchToSlot[navigationShell.currentIndex];

  void _onSlotTap(BuildContext context, int slot) {
    if (slot == _addSlot) {
      // Center Add → push the add-tenant flow (EPIC-04). Until that route
      // exists, app_router maps it to a placeholder push.
      // TODO(EPIC-04) point at the real /tenants/add wizard entry.
      context.pushNamed('tenantsAdd');
      return;
    }
    final branch = _branchToSlot.indexOf(slot);
    navigationShell.goBranch(
      branch,
      // Re-tapping the active tab pops to its branch root.
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
