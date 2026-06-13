import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khatir_tokens/khatir_tokens.dart';

import '../../../../core/config/flags_provider.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/tenant_enums.dart';
import '../../data/tenant_providers.dart';

/// Tenant role home screen (EPIC-19 T-005), per the `tenHome` prototype
/// (`proto/screens-other.js` → `reg('tenHome')`).
///
/// Shows: current rent status card (paid/due/overdue), quick action grid
/// (Pay, Maintenance, Receipts, Record), lease summary card, recent receipts,
/// and the good-tenant star record promo. Gate: `tenant_app_enabled` flag.
///
/// States: loading / error / empty (no lease) / data. All colors/spacing from
/// [KhatirColors] / [KhatirSpacing] — no inline hex/px.
class TenHomeScreen extends ConsumerWidget {
  const TenHomeScreen({super.key});

  static const String routePath = '/tenant/home';
  static const String routeName = 'tenantHome';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final flags = ref.watch(flagsProvider);

    // Feature-flag gate.
    if (!flags.isEnabled('tenant_app_enabled', orElse: true)) {
      return const _TenantFlagGate();
    }

    final rentAsync = ref.watch(myRentProvider);
    final leaseAsync = ref.watch(myLeaseProvider);
    final receiptsAsync = ref.watch(myReceiptsProvider);

    return Scaffold(
      backgroundColor: KhatirColors.cream,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Top-bar: brand logo + bell.
            SliverAppBar(
              backgroundColor: KhatirColors.cream,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              floating: true,
              title: Text(
                l10n.common_app_name,
                style: AppTextStyles.titleLarge,
              ),
              actions: const [
                Padding(
                  padding: EdgeInsets.only(right: KhatirSpacing.s4),
                  child: Icon(
                    Icons.notifications_outlined,
                    color: KhatirColors.ink,
                  ),
                ),
              ],
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: KhatirSpacing.s5,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tenant chip.
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: KhatirSpacing.s3,
                        vertical: KhatirSpacing.s1,
                      ),
                      decoration: BoxDecoration(
                        color: KhatirColors.roseBg,
                        borderRadius: BorderRadius.circular(KhatirRadius.chip),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.person_outline,
                            size: 13,
                            color: KhatirColors.roseDk,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Tenant · ভাড়াটিয়া',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: KhatirColors.roseDk,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: KhatirSpacing.s2),
                    Text(l10n.ten_home_greeting, style: AppTextStyles.accent),
                    const SizedBox(height: KhatirSpacing.s1),
                    leaseAsync.when(
                      loading: () => const SizedBox.shrink(),
                      error: (_, _2) => const SizedBox.shrink(),
                      data: (lease) => Text(
                        lease != null
                            ? '${lease.buildingLabel} · ${lease.unitLabel}'
                            : l10n.ten_home_no_lease,
                        style: AppTextStyles.bodySmall,
                      ),
                    ),
                    const SizedBox(height: KhatirSpacing.s4),
                  ],
                ),
              ),
            ),

            // Rent hero card.
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: KhatirSpacing.s5,
                ),
                child: rentAsync.when(
                  loading: () => const _RentCardLoading(),
                  error: (e, _) => _RentCardError(error: e.toString()),
                  data: (rent) => rent == null
                      ? _RentCardEmpty(l10n: l10n)
                      : _RentCard(rent: rent, l10n: l10n),
                ),
              ),
            ),

            // Lease summary card.
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  KhatirSpacing.s5,
                  KhatirSpacing.s3,
                  KhatirSpacing.s5,
                  0,
                ),
                child: leaseAsync.when(
                  loading: () => const _LoadingCard(),
                  error: (_, _2) => const SizedBox.shrink(),
                  data: (lease) => lease == null
                      ? const SizedBox.shrink()
                      : _LeaseCard(lease: lease, l10n: l10n),
                ),
              ),
            ),

            // Quick actions.
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  KhatirSpacing.s5,
                  KhatirSpacing.s4,
                  KhatirSpacing.s5,
                  0,
                ),
                child: _QuickActionsGrid(l10n: l10n),
              ),
            ),

            // Recent receipts.
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  KhatirSpacing.s5,
                  KhatirSpacing.s4,
                  KhatirSpacing.s5,
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.ten_home_recent_receipts,
                      style: AppTextStyles.titleMedium,
                    ),
                    const SizedBox(height: KhatirSpacing.s2),
                    receiptsAsync.when(
                      loading: () => const _LoadingCard(),
                      error: (_, _2) => const SizedBox.shrink(),
                      data: (receipts) {
                        final recent = receipts.take(3).toList();
                        if (recent.isEmpty) return const SizedBox.shrink();
                        return Container(
                          decoration: BoxDecoration(
                            color: KhatirColors.card,
                            borderRadius:
                                BorderRadius.circular(KhatirRadius.card),
                            border: Border.all(color: KhatirColors.line),
                          ),
                          child: Column(
                            children: [
                              for (int i = 0; i < recent.length; i++)
                                _ReceiptRow(
                                  receipt: recent[i],
                                  showDivider: i < recent.length - 1,
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Star record promo.
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  KhatirSpacing.s5,
                  KhatirSpacing.s3,
                  KhatirSpacing.s5,
                  KhatirSpacing.s6,
                ),
                child: GestureDetector(
                  onTap: () => context.pushNamed('tenantRecord'),
                  child: Container(
                    padding: const EdgeInsets.all(KhatirSpacing.s4),
                    decoration: BoxDecoration(
                      color: KhatirColors.sageBg,
                      borderRadius: BorderRadius.circular(KhatirRadius.card),
                      border: Border.all(color: KhatirColors.line),
                    ),
                    child: Row(
                      children: [
                        const Text('🌟', style: TextStyle(fontSize: 34)),
                        const SizedBox(width: KhatirSpacing.s3),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.ten_home_star_record,
                                style: AppTextStyles.accent
                                    .copyWith(fontSize: 22),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                l10n.ten_home_star_body,
                                style: AppTextStyles.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────--

class _TenantFlagGate extends StatelessWidget {
  const _TenantFlagGate();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KhatirColors.cream,
      body: const Center(
        child: Text('Tenant app coming soon'),
      ),
    );
  }
}

class _RentCardLoading extends StatelessWidget {
  const _RentCardLoading();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: KhatirColors.rose.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(KhatirRadius.card),
      ),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

class _RentCardError extends StatelessWidget {
  const _RentCardError({required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(KhatirSpacing.s4),
      decoration: BoxDecoration(
        color: KhatirColors.dangerBg,
        borderRadius: BorderRadius.circular(KhatirRadius.card),
      ),
      child: Text(error, style: AppTextStyles.bodySmall),
    );
  }
}

class _RentCardEmpty extends StatelessWidget {
  const _RentCardEmpty({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(KhatirSpacing.s5),
      decoration: BoxDecoration(
        color: KhatirColors.sageBg,
        borderRadius: BorderRadius.circular(KhatirRadius.card),
        border: Border.all(color: KhatirColors.line),
      ),
      child: Text(l10n.ten_pay_no_rent, style: AppTextStyles.bodyMedium),
    );
  }
}

class _RentCard extends StatelessWidget {
  const _RentCard({required this.rent, required this.l10n});

  final dynamic rent; // TenantRent
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final isPaid = rent.status == RentStatus.paid;
    return GestureDetector(
      onTap: () => context.pushNamed('tenantPay'),
      child: Container(
        padding: const EdgeInsets.all(KhatirSpacing.s5),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isPaid
                ? [KhatirColors.sage, KhatirColors.sageDk]
                : [KhatirColors.rose, KhatirColors.roseDk],
          ),
          borderRadius: BorderRadius.circular(KhatirRadius.card),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: KhatirSpacing.s3,
                vertical: KhatirSpacing.s1,
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(KhatirRadius.chip),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isPaid ? Icons.check_circle_outline : Icons.schedule,
                    size: 13,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isPaid
                        ? l10n.ten_home_rent_paid
                        : l10n.ten_home_rent_status,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: KhatirSpacing.s2),
            Text(
              '৳${rent.amountDue > 0 ? rent.amountDue.toStringAsFixed(0) : rent.amountPaid.toStringAsFixed(0)}',
              style: AppTextStyles.displayLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 36,
              ),
            ),
            const SizedBox(height: KhatirSpacing.s2),
            if (!isPaid) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: KhatirSpacing.s4,
                  vertical: KhatirSpacing.s3,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(KhatirRadius.button),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.upload_outlined,
                      size: 16,
                      color: KhatirColors.roseDk,
                    ),
                    const SizedBox(width: KhatirSpacing.s2),
                    Text(
                      l10n.ten_home_pay,
                      style: AppTextStyles.labelLarge.copyWith(
                        color: KhatirColors.roseDk,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LeaseCard extends StatelessWidget {
  const _LeaseCard({required this.lease, required this.l10n});

  final dynamic lease; // TenantLease
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(KhatirSpacing.s4),
      decoration: BoxDecoration(
        color: KhatirColors.card,
        borderRadius: BorderRadius.circular(KhatirRadius.card),
        border: Border.all(color: KhatirColors.line),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: KhatirColors.sageBg,
                  borderRadius: BorderRadius.circular(KhatirRadius.sm),
                ),
                child: const Icon(
                  Icons.description_outlined,
                  color: KhatirColors.sageDk,
                  size: 20,
                ),
              ),
              const SizedBox(width: KhatirSpacing.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.ten_home_lease,
                      style: AppTextStyles.titleMedium,
                    ),
                    if (lease.startDate != null)
                      Text(
                        '${lease.startDate!.month}/${lease.startDate!.year} — চলমান',
                        style: AppTextStyles.bodySmall,
                      ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => context.pushNamed('tenantLease'),
                style: TextButton.styleFrom(
                  foregroundColor: KhatirColors.sageDk,
                  backgroundColor: KhatirColors.sageBg,
                  padding: const EdgeInsets.symmetric(
                    horizontal: KhatirSpacing.s3,
                    vertical: KhatirSpacing.s2,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(KhatirRadius.button),
                  ),
                  minimumSize: Size.zero,
                ),
                child: Text(
                  l10n.ten_home_lease_view,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: KhatirColors.sageDk,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: KhatirSpacing.s3),
          const Divider(color: KhatirColors.line, height: 1),
          const SizedBox(height: KhatirSpacing.s3),
          Row(
            children: [
              Expanded(
                child: _LeaseDetailCell(
                  label: l10n.ten_lease_landlord,
                  value: lease.landlordName,
                ),
              ),
              Expanded(
                child: _LeaseDetailCell(
                  label: l10n.ten_lease_advance,
                  value: '৳${lease.advanceAmount.toStringAsFixed(0)}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LeaseDetailCell extends StatelessWidget {
  const _LeaseDetailCell({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.bodySmall),
        Text(
          value,
          style: AppTextStyles.labelLarge,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final actions = [
      _QuickAction(
        icon: Icons.build_outlined,
        labelBn: l10n.ten_home_action_maint,
        labelEn: 'Request fix',
        bg: KhatirColors.butterBg,
        fg: KhatirColors.roseDk,
        onTap: () => context.pushNamed('tenantMaintenance'),
      ),
      _QuickAction(
        icon: Icons.receipt_long_outlined,
        labelBn: l10n.ten_home_action_receipts,
        labelEn: 'Receipts',
        bg: KhatirColors.sageBg,
        fg: KhatirColors.sageDk,
        onTap: () => context.pushNamed('tenantReceipts'),
      ),
      _QuickAction(
        icon: Icons.payments_outlined,
        labelBn: l10n.ten_home_action_pay,
        labelEn: 'Pay rent',
        bg: KhatirColors.roseBg,
        fg: KhatirColors.roseDk,
        onTap: () => context.pushNamed('tenantPay'),
      ),
      _QuickAction(
        icon: Icons.star_outline,
        labelBn: l10n.ten_home_action_record,
        labelEn: 'My record',
        bg: KhatirColors.sageBg,
        fg: KhatirColors.sageDk,
        onTap: () => context.pushNamed('tenantRecord'),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.ten_home_quick_actions, style: AppTextStyles.titleMedium),
        const SizedBox(height: KhatirSpacing.s2),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: KhatirSpacing.s2,
          mainAxisSpacing: KhatirSpacing.s2,
          childAspectRatio: 1.4,
          children: actions
              .map((a) => _QuickActionCard(action: a))
              .toList(growable: false),
        ),
      ],
    );
  }
}

class _QuickAction {
  const _QuickAction({
    required this.icon,
    required this.labelBn,
    required this.labelEn,
    required this.bg,
    required this.fg,
    required this.onTap,
  });

  final IconData icon;
  final String labelBn;
  final String labelEn;
  final Color bg;
  final Color fg;
  final VoidCallback onTap;
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({required this.action});

  final _QuickAction action;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: action.onTap,
      child: Container(
        padding: const EdgeInsets.all(KhatirSpacing.s3),
        decoration: BoxDecoration(
          color: action.bg,
          borderRadius: BorderRadius.circular(KhatirRadius.card),
          border: Border.all(color: KhatirColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.65),
                borderRadius: BorderRadius.circular(KhatirRadius.sm),
              ),
              child: Icon(action.icon, size: 20, color: action.fg),
            ),
            const SizedBox(height: KhatirSpacing.s2),
            Text(
              action.labelBn,
              style: AppTextStyles.labelLarge.copyWith(color: action.fg),
            ),
            Text(
              action.labelEn,
              style: AppTextStyles.bodySmall.copyWith(fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  const _ReceiptRow({required this.receipt, required this.showDivider});

  final dynamic receipt; // TenantReceipt
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: KhatirSpacing.s4,
            vertical: KhatirSpacing.s3,
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: KhatirColors.sageBg,
                  borderRadius: BorderRadius.circular(KhatirRadius.sm),
                ),
                child: const Icon(
                  Icons.receipt_long_outlined,
                  size: 16,
                  color: KhatirColors.sageDk,
                ),
              ),
              const SizedBox(width: KhatirSpacing.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      receipt.period,
                      style: AppTextStyles.labelLarge,
                    ),
                    Text(
                      '✓ পরিশোধিত · Paid',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: KhatirColors.sage,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '৳${receipt.amount.toStringAsFixed(0)}',
                style: AppTextStyles.labelLarge,
              ),
            ],
          ),
        ),
        if (showDivider)
          const Divider(height: 1, color: KhatirColors.line),
      ],
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: KhatirColors.line,
        borderRadius: BorderRadius.circular(KhatirRadius.card),
      ),
    );
  }
}
