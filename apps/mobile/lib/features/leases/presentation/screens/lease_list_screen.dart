import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khatir_tokens/khatir_tokens.dart';

import '../../../../core/i18n/bangla_numerals.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/lease_enums.dart';
import '../../data/models/models.dart';
import '../../data/providers.dart';
import 'lease_detail_screen.dart';

/// The landlord's lease list (EPIC-06 T-010). Lists the caller's leases
/// (scoped server-side via [leasesListProvider]) as soft cards — status chip,
/// monthly rent, and the term range — each tapping through to the lease detail
/// screen (`/lease/:id`).
///
/// The leases screens are "derived" in the design map (no dedicated prototype),
/// so this follows the shared Khatir list composition (the portfolio/unit
/// screens): a cream scaffold, white cards, sage accents. Every
/// colour/spacing/radius/font comes from the design tokens; numerals are
/// localised via [BanglaNumerals].
///
/// States: loading (spinner), error (retry → re-fetch), empty (friendly card),
/// data (the list). Reachable from More / portfolio at `/leases`.
class LeaseListScreen extends ConsumerWidget {
  const LeaseListScreen({super.key});

  static const String routePath = '/leases';
  static const String routeName = 'leases';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final leasesAsync = ref.watch(leasesListProvider);

    return Scaffold(
      backgroundColor: KhatirColors.cream,
      appBar: AppBar(
        backgroundColor: KhatirColors.cream,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          l10n.leases_title,
          style:
              AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        top: false,
        child: leasesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => _ErrorState(
            l10n: l10n,
            onRetry: () => ref.read(leasesListProvider.notifier).refresh(),
          ),
          data: (leases) => leases.isEmpty
              ? _EmptyState(l10n: l10n)
              : _LeaseList(leases: leases),
        ),
      ),
    );
  }
}

/// The populated lease list — a scrollable column of [_LeaseCard]s.
class _LeaseList extends StatelessWidget {
  const _LeaseList({required this.leases});

  final List<Lease> leases;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        KhatirSpacing.s5,
        KhatirSpacing.s4,
        KhatirSpacing.s5,
        KhatirSpacing.s6,
      ),
      itemCount: leases.length,
      separatorBuilder: (_, _) => const SizedBox(height: KhatirSpacing.s3),
      itemBuilder: (context, i) {
        final lease = leases[i];
        return _LeaseCard(
          key: ValueKey('lease-${lease.id}'),
          lease: lease,
          onTap: () => context.pushNamed(
            LeaseDetailScreen.routeName,
            pathParameters: {'id': lease.id},
          ),
        );
      },
    );
  }
}

/// One lease as a soft card: a status chip + monthly rent on top, the term
/// range underneath, and a trailing chevron.
class _LeaseCard extends StatelessWidget {
  const _LeaseCard({super.key, required this.lease, required this.onTap});

  final Lease lease;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final localeCode = Localizations.localeOf(context).languageCode;
    final radius = BorderRadius.circular(KhatirRadius.card);
    return Material(
      color: KhatirColors.card,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Padding(
          padding: const EdgeInsets.all(KhatirSpacing.s4),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _StatusChip(status: lease.status),
                        const SizedBox(width: KhatirSpacing.s2),
                        Expanded(
                          child: Text(
                            l10n.unit_rent_per_month(
                              BanglaNumerals.format(
                                lease.rent.round(),
                                localeCode,
                              ),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.titleMedium.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: KhatirSpacing.s2),
                    Text(
                      termRange(context, lease),
                      style: AppTextStyles.bodySmall
                          .copyWith(color: KhatirColors.mutedDk),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: KhatirSpacing.s2),
              const Icon(
                Icons.chevron_right,
                color: KhatirColors.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A small status pill (sage-tinted) for a [LeaseStatus].
class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final LeaseStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: KhatirSpacing.s2,
        vertical: KhatirSpacing.s1 - 1,
      ),
      decoration: BoxDecoration(
        color: KhatirColors.sageBg,
        borderRadius: BorderRadius.circular(KhatirRadius.chip),
      ),
      child: Text(
        leaseStatusLabel(l10n, status),
        style: AppTextStyles.bodySmall.copyWith(
          color: KhatirColors.sageDk,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Friendly empty-state when the landlord has no leases yet.
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(KhatirSpacing.s6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('📄', style: TextStyle(fontSize: 40)),
            const SizedBox(height: KhatirSpacing.s3),
            Text(
              l10n.leases_empty_title,
              textAlign: TextAlign.center,
              style: AppTextStyles.titleMedium
                  .copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: KhatirSpacing.s1),
            Text(
              l10n.leases_empty,
              textAlign: TextAlign.center,
              style:
                  AppTextStyles.bodySmall.copyWith(color: KhatirColors.mutedDk),
            ),
          ],
        ),
      ),
    );
  }
}

/// Error state: a friendly message and a retry button (reloads `/leases`).
class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.l10n, required this.onRetry});

  final AppLocalizations l10n;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(KhatirRadius.button);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(KhatirSpacing.s6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.common_network_error,
              textAlign: TextAlign.center,
              style:
                  AppTextStyles.bodyMedium.copyWith(color: KhatirColors.mutedDk),
            ),
            const SizedBox(height: KhatirSpacing.s4),
            Material(
              color: KhatirColors.sage,
              borderRadius: radius,
              child: InkWell(
                onTap: onRetry,
                borderRadius: radius,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: KhatirSpacing.s6,
                    vertical: KhatirSpacing.s4,
                  ),
                  child: Text(
                    l10n.common_retry,
                    style: AppTextStyles.labelLarge.copyWith(
                      color: KhatirColors.card,
                      fontWeight: FontWeight.w700,
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

/// Localised display label for a [LeaseStatus].
String leaseStatusLabel(AppLocalizations l10n, LeaseStatus status) =>
    switch (status) {
      LeaseStatus.draft => l10n.lease_status_draft,
      LeaseStatus.active => l10n.lease_status_active,
      LeaseStatus.ended => l10n.lease_status_ended,
      LeaseStatus.terminated => l10n.lease_status_terminated,
    };

/// Formats a lease's term as `start – end`, with localised numerals. Falls back
/// to an em dash for an absent endpoint so the row is never blank.
String termRange(BuildContext context, Lease lease) {
  final l10n = AppLocalizations.of(context);
  final localeCode = Localizations.localeOf(context).languageCode;
  String part(int v, {bool pad = false}) {
    final s = BanglaNumerals.format(v, localeCode, grouped: false);
    return pad ? s.padLeft(2, '0') : s;
  }

  String fmt(DateTime? d) => d == null
      ? '—'
      : '${part(d.year)}-${part(d.month, pad: true)}-${part(d.day, pad: true)}';
  return l10n.lease_term_range(fmt(lease.startDate), fmt(lease.endDate));
}
