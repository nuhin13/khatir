import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// One slot in a role's bottom-nav, resolved against the live [AppLocalizations]
/// so labels stay i18n-driven (bn/en via ARB).
class ShellNavSlot {
  const ShellNavSlot({
    required this.icon,
    required this.label,
    this.fab = false,
  });

  /// Icon from the Material design set used by the shell.
  final IconData icon;

  /// Resolves the slot label from localizations (e.g. `(l) => l.nav_home`).
  final String Function(AppLocalizations l10n) label;

  /// True for the center accent action (push, not a branch).
  final bool fab;
}

/// Per-role bottom-nav layout, mirroring `bottomnav()` in `proto/ui.js`.
///
/// Landlord and manager share the 5-slot layout (Home · Charts · ➕ · Rent ·
/// More) where the center ➕ is an action, not a branch. Tenant uses a 4-slot
/// layout (Home · Maintenance · Receipts · More) with no center action — its
/// `tenHome` design has no add-FAB.
///
/// [branchToSlot] maps a `StatefulShellRoute` branch index to its visual nav
/// slot, leaving the FAB slot (if any) free.
class ShellNavConfig {
  const ShellNavConfig({
    required this.slots,
    required this.branchToSlot,
    this.fabSlot,
    this.fabRouteName,
  });

  /// Ordered visual slots, left to right.
  final List<ShellNavSlot> slots;

  /// Maps branch index → visual slot index.
  final List<int> branchToSlot;

  /// Visual slot index of the center FAB, or null when the role has none.
  final int? fabSlot;

  /// Named route the FAB pushes (the add action), or null when there is no FAB.
  final String? fabRouteName;

  /// Landlord/manager FAB action: open the add-tenant flow (EPIC-04 builds the
  /// real wizard; for now the route is a placeholder push).
  static const String _addTenantRoute = 'tenantsAdd';

  /// Landlord nav: Home · Charts · ➕ Add · Rent · More.
  static final ShellNavConfig landlord = ShellNavConfig(
    slots: [
      ShellNavSlot(icon: Icons.home_outlined, label: (l) => l.nav_home),
      ShellNavSlot(icon: Icons.bar_chart_outlined, label: (l) => l.nav_charts),
      ShellNavSlot(icon: Icons.add, label: (l) => l.nav_add, fab: true),
      ShellNavSlot(icon: Icons.payments_outlined, label: (l) => l.nav_rent),
      ShellNavSlot(icon: Icons.menu, label: (l) => l.nav_more),
    ],
    branchToSlot: const [0, 1, 3, 4],
    fabSlot: 2,
    fabRouteName: _addTenantRoute,
  );

  /// Manager nav: identical 5-slot structure to landlord.
  static final ShellNavConfig manager = landlord;

  /// Tenant nav: Home · Maintenance · Receipts · More (no center action).
  static final ShellNavConfig tenant = ShellNavConfig(
    slots: [
      ShellNavSlot(icon: Icons.home_outlined, label: (l) => l.nav_home),
      ShellNavSlot(
        icon: Icons.build_outlined,
        label: (l) => l.nav_maintenance,
      ),
      ShellNavSlot(
        icon: Icons.receipt_long_outlined,
        label: (l) => l.nav_receipts,
      ),
      ShellNavSlot(icon: Icons.menu, label: (l) => l.nav_more),
    ],
    branchToSlot: const [0, 1, 2, 3],
  );

  /// Visual slot for the given branch index.
  int slotForBranch(int branchIndex) => branchToSlot[branchIndex];

  /// Branch index for a tapped slot, or null when the slot is the FAB action.
  int? branchForSlot(int slot) {
    if (slot == fabSlot) return null;
    return branchToSlot.indexOf(slot);
  }
}
