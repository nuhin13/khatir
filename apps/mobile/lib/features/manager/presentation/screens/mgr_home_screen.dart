import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:khatir_tokens/khatir_tokens.dart';

import '../../../../l10n/app_localizations.dart';
import '../../data/manager_providers.dart';
import '../../data/models/manager_models.dart';

/// Manager home screen (EPIC-22 T-006).
///
/// Shows the consolidated portfolio across all actively-linked owners.
/// Only owners with [LinkedOwner.status] == `'active'` are rendered — this is
/// the manager scoping gate (T-012). Pending and revoked links are invisible
/// here; the add-owner screen (T-007) shows pending requests.
///
/// Routes:
/// - FAB / top-right → `/manager/add-owner`
/// - Team chip → `/manager/team`
/// - Reports chip → `/manager/report`
class MgrHomeScreen extends ConsumerWidget {
  const MgrHomeScreen({super.key});

  static const routePath = '/manager/home';
  static const routeName = 'managerHome';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final ownersAsync = ref.watch(managerOwnersProvider);

    return Scaffold(
      backgroundColor: KhatirColors.cream,
      appBar: AppBar(
        backgroundColor: KhatirColors.cream,
        elevation: 0,
        title: Text(
          l10n.mgr_home_title,
          style: TextStyle(
            color: KhatirColors.ink,
            fontFamily: KhatirFonts.title,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          // Add-owner action
          Padding(
            padding: const EdgeInsets.only(right: KhatirSpacing.s3),
            child: TextButton.icon(
              onPressed: () => context.pushNamed('managerAddOwner'),
              icon: Icon(Icons.add, color: KhatirColors.sage, size: 18),
              label: Text(
                l10n.mgr_home_add_owner,
                style: TextStyle(
                  color: KhatirColors.sage,
                  fontFamily: KhatirFonts.body,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
      body: ownersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                e.toString(),
                style: TextStyle(color: KhatirColors.danger, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: KhatirSpacing.s3),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: KhatirColors.sage,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(KhatirRadius.button),
                  ),
                ),
                onPressed: () => ref.invalidate(managerOwnersProvider),
                child: Text(
                  l10n.common_retry,
                  style: TextStyle(
                    fontFamily: KhatirFonts.body,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        data: (owners) {
          // SCOPING GATE: only active owners are shown on the home screen.
          final activeOwners = owners.where((o) => o.isActive).toList();
          return RefreshIndicator(
            color: KhatirColors.sage,
            onRefresh: () => ref.read(managerOwnersProvider.notifier).refresh(),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: _QuickActions(l10n: l10n),
                ),
                if (activeOwners.isEmpty)
                  SliverFillRemaining(
                    child: _EmptyState(l10n: l10n),
                  )
                else ...[
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      KhatirSpacing.s4,
                      0,
                      KhatirSpacing.s4,
                      KhatirSpacing.s2,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: Text(
                        l10n.mgr_home_owners(activeOwners.length.toString()),
                        style: TextStyle(
                          color: KhatirColors.ink2,
                          fontFamily: KhatirFonts.body,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: KhatirSpacing.s4,
                    ),
                    sliver: SliverList.separated(
                      itemCount: activeOwners.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: KhatirSpacing.s3),
                      itemBuilder: (context, index) =>
                          _OwnerCard(owner: activeOwners[index], l10n: l10n),
                    ),
                  ),
                  const SliverPadding(
                    padding: EdgeInsets.only(bottom: KhatirSpacing.s7),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Quick-action chips ──────────────────────────────────────────────────────

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        KhatirSpacing.s4,
        KhatirSpacing.s4,
        KhatirSpacing.s4,
        KhatirSpacing.s4,
      ),
      child: Row(
        children: [
          _ActionChip(
            icon: Icons.group_outlined,
            label: l10n.mgr_home_team,
            onTap: () => context.pushNamed('managerTeam'),
          ),
          const SizedBox(width: KhatirSpacing.s3),
          _ActionChip(
            icon: Icons.bar_chart_outlined,
            label: l10n.mgr_home_reports,
            onTap: () => context.pushNamed('managerReport'),
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: KhatirSpacing.s3,
          vertical: KhatirSpacing.s2,
        ),
        decoration: BoxDecoration(
          color: KhatirColors.sageBg,
          borderRadius: BorderRadius.circular(KhatirRadius.chip),
          border: Border.all(color: KhatirColors.sage.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: KhatirColors.sageDk),
            const SizedBox(width: KhatirSpacing.s1),
            Text(
              label,
              style: TextStyle(
                color: KhatirColors.sageDk,
                fontFamily: KhatirFonts.body,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Owner card ──────────────────────────────────────────────────────────────

class _OwnerCard extends StatelessWidget {
  const _OwnerCard({required this.owner, required this.l10n});

  final LinkedOwner owner;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0', 'en');
    return Container(
      padding: const EdgeInsets.all(KhatirSpacing.s4),
      decoration: BoxDecoration(
        color: KhatirColors.card,
        borderRadius: BorderRadius.circular(KhatirRadius.card),
        border: Border.all(color: KhatirColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Owner name + avatar initial
          Row(
            children: [
              _Avatar(name: owner.ownerName),
              const SizedBox(width: KhatirSpacing.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      owner.ownerName,
                      style: TextStyle(
                        color: KhatirColors.ink,
                        fontFamily: KhatirFonts.title,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      owner.ownerPhone,
                      style: TextStyle(
                        color: KhatirColors.ink2,
                        fontFamily: KhatirFonts.body,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: KhatirSpacing.s4),
          // Stats row
          Row(
            children: [
              _StatTile(
                label: l10n.mgr_home_stat_units,
                value: owner.unitCount.toString(),
              ),
              const SizedBox(width: KhatirSpacing.s3),
              _StatTile(
                label: l10n.mgr_home_stat_occupied,
                value: owner.occupiedCount.toString(),
              ),
              const SizedBox(width: KhatirSpacing.s3),
              _StatTile(
                label: l10n.mgr_home_stat_rent,
                value: l10n.mgr_home_currency(fmt.format(owner.monthlyRent)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final initial =
        name.isNotEmpty ? name[0].toUpperCase() : '?';
    return CircleAvatar(
      radius: 22,
      backgroundColor: KhatirColors.sageBg,
      child: Text(
        initial,
        style: TextStyle(
          color: KhatirColors.sageDk,
          fontFamily: KhatirFonts.title,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          vertical: KhatirSpacing.s2,
          horizontal: KhatirSpacing.s3,
        ),
        decoration: BoxDecoration(
          color: KhatirColors.cream,
          borderRadius: BorderRadius.circular(KhatirRadius.sm),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                color: KhatirColors.ink,
                fontFamily: KhatirFonts.title,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: KhatirColors.muted,
                fontFamily: KhatirFonts.body,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty state ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(KhatirSpacing.s6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.group_add_outlined, size: 64, color: KhatirColors.muted),
          const SizedBox(height: KhatirSpacing.s4),
          Text(
            l10n.mgr_home_empty,
            style: TextStyle(
              color: KhatirColors.ink,
              fontFamily: KhatirFonts.title,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: KhatirSpacing.s2),
          Text(
            l10n.mgr_home_empty_sub,
            style: TextStyle(
              color: KhatirColors.ink2,
              fontFamily: KhatirFonts.body,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: KhatirSpacing.s5),
          FilledButton.icon(
            onPressed: () => context.pushNamed('managerAddOwner'),
            icon: const Icon(Icons.add),
            label: Text(
              l10n.mgr_home_add_owner,
              style: TextStyle(
                fontFamily: KhatirFonts.body,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: KhatirColors.sage,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(KhatirRadius.button),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: KhatirSpacing.s6,
                vertical: KhatirSpacing.s3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
