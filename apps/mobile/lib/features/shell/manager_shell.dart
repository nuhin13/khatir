import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:khatir_tokens/khatir_tokens.dart';

import '../../core/widgets/k_bottom_nav.dart';
import '../../l10n/app_localizations.dart';
import 'shell_nav_config.dart';

/// Manager role shell. Same 5-slot nav structure as the landlord shell (home,
/// dashboard, Add, rent, more) via [ShellNavConfig.manager]; branch bodies are
/// stubbed until EPIC-22 fills the manager experience.
class ManagerShell extends StatelessWidget {
  const ManagerShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static final ShellNavConfig _config = ShellNavConfig.manager;

  void _onSlotTap(BuildContext context, int slot) {
    final branch = _config.branchForSlot(slot);
    if (branch == null) {
      // TODO(EPIC-04) point at the real /tenants/add wizard entry.
      context.pushNamed(_config.fabRouteName!);
      return;
    }
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
