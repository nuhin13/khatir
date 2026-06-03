import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:khatir_tokens/khatir_tokens.dart';

import '../../core/widgets/k_bottom_nav.dart';
import '../../l10n/app_localizations.dart';

/// Tenant role shell. Four bottom-nav branches (home, maintenance, receipts,
/// more) in an indexed stack. Tenants have no center Add action, so every nav
/// slot maps 1:1 to a branch. Branch bodies are stubbed until EPIC-19 fills the
/// tenant experience.
class TenantShell extends StatelessWidget {
  const TenantShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: KhatirColors.cream,
      body: navigationShell,
      bottomNavigationBar: KBottomNav(
        currentIndex: navigationShell.currentIndex,
        onTap: _onTap,
        items: [
          KBottomNavItem(icon: Icons.home_outlined, label: l10n.nav_home),
          KBottomNavItem(
            icon: Icons.build_outlined,
            label: l10n.nav_maintenance,
          ),
          KBottomNavItem(
            icon: Icons.receipt_long_outlined,
            label: l10n.nav_receipts,
          ),
          KBottomNavItem(icon: Icons.menu, label: l10n.nav_more),
        ],
      ),
    );
  }
}
