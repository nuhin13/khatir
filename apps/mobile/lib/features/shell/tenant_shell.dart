import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:khatir_tokens/khatir_tokens.dart';

import '../../core/widgets/k_bottom_nav.dart';
import '../../l10n/app_localizations.dart';
import 'shell_nav_config.dart';

/// Tenant role shell. Four bottom-nav branches (home, maintenance, receipts,
/// more) in an indexed stack via [ShellNavConfig.tenant]. Tenants have no
/// center Add action, so every nav slot maps 1:1 to a branch. Branch bodies are
/// stubbed until EPIC-19 fills the tenant experience.
class TenantShell extends StatelessWidget {
  const TenantShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static final ShellNavConfig _config = ShellNavConfig.tenant;

  void _onTap(int slot) {
    final branch = _config.branchForSlot(slot);
    if (branch == null) return;
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
        onTap: _onTap,
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
