import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khatir_tokens/khatir_tokens.dart';

import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/tenant_providers.dart';

/// Tenant lease view screen (EPIC-19 T-006), per the `tenLease` prototype
/// (`proto/screens-other.js` → `reg('tenLease')`).
///
/// Read-only view of the tenant's current lease: rent, advance, dates,
/// landlord contact, notice period. Links to the AI lease PDF (EPIC-18)
/// when [leaseDocumentRef] is non-null.
///
/// States: loading / error / empty (no lease) / data.
class TenLeaseScreen extends ConsumerWidget {
  const TenLeaseScreen({super.key});

  static const String routePath = '/tenant/lease';
  static const String routeName = 'tenantLease';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final leaseAsync = ref.watch(myLeaseProvider);

    return Scaffold(
      backgroundColor: KhatirColors.cream,
      appBar: AppBar(
        backgroundColor: KhatirColors.cream,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(l10n.ten_home_lease, style: AppTextStyles.titleLarge),
      ),
      body: leaseAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorBody(error: e.toString()),
        data: (lease) => lease == null
            ? _EmptyBody(l10n: l10n)
            : _LeaseBody(lease: lease, l10n: l10n),
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(KhatirSpacing.s6),
        child: Text(error, style: AppTextStyles.bodyMedium),
      ),
    );
  }
}

class _EmptyBody extends StatelessWidget {
  const _EmptyBody({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(KhatirSpacing.s6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.description_outlined,
              size: 48,
              color: KhatirColors.muted,
            ),
            const SizedBox(height: KhatirSpacing.s4),
            Text(l10n.ten_lease_no_lease, style: AppTextStyles.bodyMedium),
          ],
        ),
      ),
    );
  }
}

class _LeaseBody extends StatelessWidget {
  const _LeaseBody({required this.lease, required this.l10n});

  final dynamic lease; // TenantLease
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final startStr = lease.startDate != null
        ? '${lease.startDate!.day}/${lease.startDate!.month}/${lease.startDate!.year}'
        : '—';
    final endStr = lease.endDate != null
        ? '${lease.endDate!.day}/${lease.endDate!.month}/${lease.endDate!.year}'
        : 'চলমান';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(KhatirSpacing.s5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero gradient card.
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(KhatirSpacing.s5),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [KhatirColors.sage, KhatirColors.sageDk],
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
                  child: Text(
                    l10n.ten_lease_active,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: KhatirSpacing.s2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '৳${lease.monthlyRent.toStringAsFixed(0)}',
                      style: AppTextStyles.displayLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 28,
                      ),
                    ),
                    Text(
                      '/মাস',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: KhatirSpacing.s1),
                Text(
                  '${lease.unitLabel} · ${lease.buildingLabel}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: KhatirSpacing.s3),

          // Details card.
          Container(
            decoration: BoxDecoration(
              color: KhatirColors.card,
              borderRadius: BorderRadius.circular(KhatirRadius.card),
              border: Border.all(color: KhatirColors.line),
            ),
            child: Column(
              children: [
                _DetailRow(
                  label: l10n.ten_lease_landlord,
                  value: lease.landlordName.isNotEmpty
                      ? lease.landlordName
                      : '—',
                  showDivider: true,
                ),
                _DetailRow(
                  label: 'শুরু · Start',
                  value: startStr,
                  showDivider: true,
                ),
                _DetailRow(
                  label: l10n.ten_lease_dates,
                  value: '$startStr — $endStr',
                  showDivider: true,
                ),
                _DetailRow(
                  label: l10n.ten_lease_advance,
                  value: '৳${lease.advanceAmount.toStringAsFixed(0)}',
                  showDivider: true,
                ),
                _DetailRow(
                  label: l10n.ten_lease_notice,
                  value: lease.noticePeriod.isNotEmpty
                      ? lease.noticePeriod
                      : '—',
                  showDivider: false,
                ),
              ],
            ),
          ),

          // AI lease PDF button (only when document exists).
          if (lease.leaseDocumentRef != null &&
              (lease.leaseDocumentRef as String).isNotEmpty) ...[
            const SizedBox(height: KhatirSpacing.s3),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  // EPIC-18 will wire the PDF viewer; stub for now.
                },
                icon: const Icon(
                  Icons.download_outlined,
                  size: 16,
                  color: KhatirColors.sageDk,
                ),
                label: Text(
                  l10n.ten_lease_document,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: KhatirColors.sageDk,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: KhatirColors.sageDk),
                  padding: const EdgeInsets.symmetric(
                    vertical: KhatirSpacing.s3,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(KhatirRadius.button),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    required this.showDivider,
  });

  final String label;
  final String value;
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: AppTextStyles.bodySmall),
              Text(value, style: AppTextStyles.labelLarge),
            ],
          ),
        ),
        if (showDivider)
          const Divider(
            height: 1,
            color: KhatirColors.line,
            indent: KhatirSpacing.s4,
            endIndent: KhatirSpacing.s4,
          ),
      ],
    );
  }
}
