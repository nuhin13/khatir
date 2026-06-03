import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:khatir_tokens/khatir_tokens.dart';

import '../../core/widgets/k_bottom_nav.dart';
import '../../l10n/app_localizations.dart';
import 'shell_nav_config.dart';

/// Landlord role shell. Hosts four bottom-nav branches (home, dashboard, rent,
/// more) in an indexed stack so each tab keeps its own navigation history, plus
/// a center "Add" action that is NOT a branch — it pushes the add-tenant flow.
///
/// Nav layout + FAB action come from [ShellNavConfig.landlord]; branch bodies
/// are placeholders until their epics land (see [app_router]).
class LandlordShell extends StatelessWidget {
  const LandlordShell({super.key, required this.navigationShell});

  /// The go_router shell driving the indexed stack of branches.
  final StatefulNavigationShell navigationShell;

  static final ShellNavConfig _config = ShellNavConfig.landlord;

  void _onSlotTap(BuildContext context, int slot) {
    final branch = _config.branchForSlot(slot);
    if (branch == null) {
      // Center Add → push the add-tenant flow (EPIC-04). Until that route
      // exists, app_router maps it to a placeholder push.
      // TODO(EPIC-04) point at the real /tenants/add wizard entry.
      context.pushNamed(_config.fabRouteName!);
      return;
    }
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
        currentIndex: _config.slotForBranch(navigationShell.currentIndex),
        onTap: (slot) => _onSlotTap(context, slot),
        items: [
          for (final slot in _config.slots)
            KBottomNavItem(
              icon: slot.icon,
              label: slot.label(l10n),
              fab: slot.fab,
            ),
        ],
      ),
    );
  }
}
