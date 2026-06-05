import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khatir_tokens/khatir_tokens.dart';

import '../../../../core/i18n/bangla_numerals.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/lease_enums.dart';
import '../../data/models/models.dart';
import '../../data/providers.dart';
import 'lease_list_screen.dart';

/// The lease detail screen (EPIC-06 T-010), reached from the lease list at
/// `/lease/:id`. Shows the lease status, monetary terms, term range, and a
/// summary of the rent schedule, plus a terminate action for an active lease.
///
/// The leases screens are "derived" in the design map (no dedicated prototype),
/// so this follows the shared Khatir composition (the portfolio/unit screens): a
/// cream scaffold, white cards, sage accents. Every colour/spacing/radius/font
/// comes from the design tokens; numerals are localised via [BanglaNumerals].
///
/// The lease itself ([leaseControllerProvider]) and its schedule
/// ([leaseScheduleProvider]) load independently — the lease body renders as soon
/// as the lease resolves; the schedule summary fills in (or shows its own
/// empty/loading state) underneath. Both are scoped server-side, so an unknown
/// id resolves to a 404 surfaced as the error state.
///
/// States: loading (spinner), error (retry → re-fetch), data (the detail).
class LeaseDetailScreen extends ConsumerWidget {
  const LeaseDetailScreen({super.key, required this.leaseId});

  /// The lease id from the route path (`/lease/:id`).
  final String leaseId;

  static const String routePath = '/lease/:id';
  static const String routeName = 'leaseDetail';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final leaseAsync = ref.watch(leaseControllerProvider(leaseId));

    return Scaffold(
      backgroundColor: KhatirColors.cream,
      appBar: AppBar(
        backgroundColor: KhatirColors.cream,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          l10n.lease_detail_title,
          style:
              AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        top: false,
        child: leaseAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => _ErrorState(
            l10n: l10n,
            onRetry: () =>
                ref.read(leaseControllerProvider(leaseId).notifier).refresh(),
          ),
          data: (lease) => _LeaseDetail(leaseId: leaseId, lease: lease),
        ),
      ),
    );
  }
}

/// The populated detail body: a status header card, the terms card, the
/// schedule summary card, and (for an active lease) the terminate action.
class _LeaseDetail extends ConsumerWidget {
  const _LeaseDetail({required this.leaseId, required this.lease});

  final String leaseId;
  final Lease lease;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final localeCode = Localizations.localeOf(context).languageCode;
    final scheduleAsync = ref.watch(leaseScheduleProvider(leaseId));
    final isActive = lease.status == LeaseStatus.active;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        KhatirSpacing.s5,
        KhatirSpacing.s4,
        KhatirSpacing.s5,
        KhatirSpacing.s6,
      ),
      children: [
        // ── Status + rent header ──────────────────────────────────────────
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StatusChip(status: lease.status),
              const SizedBox(height: KhatirSpacing.s3),
              Text(
                l10n.unit_rent_per_month(
                  BanglaNumerals.format(lease.rent.round(), localeCode),
                ),
                style: AppTextStyles.titleLarge.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: KhatirSpacing.s1),
              Text(
                termRange(context, lease),
                style: AppTextStyles.bodySmall
                    .copyWith(color: KhatirColors.mutedDk),
              ),
            ],
          ),
        ),
        const SizedBox(height: KhatirSpacing.s4),

        // ── Terms ─────────────────────────────────────────────────────────
        _SectionLabel(text: l10n.lease_section_terms),
        const SizedBox(height: KhatirSpacing.s3),
        _Card(
          child: Column(
            children: [
              _Row(
                label: l10n.lease_rent,
                value: l10n.unit_rent_per_month(
                  BanglaNumerals.format(lease.rent.round(), localeCode),
                ),
              ),
              if (lease.advance > 0)
                _Row(
                  label: l10n.lease_advance,
                  value: l10n.unit_rent_per_month(
                    BanglaNumerals.format(lease.advance.round(), localeCode),
                  ),
                ),
              _Row(
                label: l10n.lease_start,
                value: _date(context, lease.startDate),
              ),
              _Row(
                label: l10n.lease_end,
                value: _date(context, lease.endDate),
                last: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: KhatirSpacing.s4),

        // ── Rent schedule summary ─────────────────────────────────────────
        _SectionLabel(text: l10n.lease_section_schedule),
        const SizedBox(height: KhatirSpacing.s3),
        _Card(
          child: scheduleAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: KhatirSpacing.s2),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, _) => Text(
              l10n.common_network_error,
              style:
                  AppTextStyles.bodySmall.copyWith(color: KhatirColors.mutedDk),
            ),
            data: (rows) => rows.isEmpty
                ? Text(
                    l10n.lease_schedule_empty,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: KhatirColors.mutedDk),
                  )
                : _ScheduleSummary(rows: rows),
          ),
        ),

        // ── Terminate (only for an active lease) ──────────────────────────
        if (isActive) ...[
          const SizedBox(height: KhatirSpacing.s6),
          _TerminateButton(
            key: const ValueKey('leaseTerminate'),
            label: l10n.lease_terminate,
            onPressed: () => _confirmTerminate(context, ref),
          ),
        ],
      ],
    );
  }

  /// Shows the terminate confirmation dialog; on confirm, terminates the lease
  /// and reports the outcome via a snackbar (the controller writes the closed
  /// lease back into state, hiding the action).
  Future<void> _confirmTerminate(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    // Captured before the await so the snackbar never reaches across an async
    // gap into a possibly-unmounted context.
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: KhatirColors.card,
        title: Text(
          l10n.lease_terminate_confirm_title,
          style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w700),
        ),
        content: Text(
          l10n.lease_terminate_confirm_body,
          style: AppTextStyles.bodyMedium.copyWith(color: KhatirColors.mutedDk),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(
              l10n.lease_terminate_cancel,
              style: AppTextStyles.labelLarge
                  .copyWith(color: KhatirColors.mutedDk),
            ),
          ),
          TextButton(
            key: const ValueKey('leaseTerminateConfirm'),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              l10n.lease_terminate,
              style: AppTextStyles.labelLarge.copyWith(
                color: KhatirColors.danger,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref
          .read(leaseControllerProvider(leaseId).notifier)
          .terminate(status: LeaseStatus.terminated);
      // Keep the list in sync so the closed lease shows its new status.
      ref.invalidate(leasesListProvider);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.lease_terminated_ok)));
    } on ApiException {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.lease_terminate_error)));
    } catch (_) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.lease_terminate_error)));
    }
  }

  /// A localised `YYYY-MM-DD` (em dash for an absent date), reusing the list
  /// screen's date part formatting via [termRange] semantics.
  static String _date(BuildContext context, DateTime? d) {
    final localeCode = Localizations.localeOf(context).languageCode;
    if (d == null) return '—';
    String part(int v, {bool pad = false}) {
      final s = BanglaNumerals.format(v, localeCode, grouped: false);
      return pad ? s.padLeft(2, '0') : s;
    }

    return '${part(d.year)}-${part(d.month, pad: true)}-${part(d.day, pad: true)}';
  }
}

/// The rent-schedule summary: a count line plus a small per-status breakdown.
class _ScheduleSummary extends StatelessWidget {
  const _ScheduleSummary({required this.rows});

  final List<RentSchedule> rows;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final localeCode = Localizations.localeOf(context).languageCode;

    final counts = <RentScheduleStatus, int>{};
    for (final r in rows) {
      counts[r.status] = (counts[r.status] ?? 0) + 1;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.lease_schedule_summary(
            BanglaNumerals.format(rows.length, localeCode),
          ),
          style:
              AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: KhatirSpacing.s2),
        Wrap(
          spacing: KhatirSpacing.s2,
          runSpacing: KhatirSpacing.s2,
          children: [
            for (final status in RentScheduleStatus.values)
              if ((counts[status] ?? 0) > 0)
                _CountChip(
                  label: _schedStatusLabel(l10n, status),
                  count: BanglaNumerals.format(counts[status]!, localeCode),
                ),
          ],
        ),
      ],
    );
  }
}

/// A subtle pill that pairs a schedule status with its count.
class _CountChip extends StatelessWidget {
  const _CountChip({required this.label, required this.count});

  final String label;
  final String count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: KhatirSpacing.s3,
        vertical: KhatirSpacing.s1,
      ),
      decoration: BoxDecoration(
        color: KhatirColors.cream,
        borderRadius: BorderRadius.circular(KhatirRadius.chip),
        border: Border.all(color: KhatirColors.line),
      ),
      child: Text(
        '$label · $count',
        style: AppTextStyles.bodySmall.copyWith(
          color: KhatirColors.mutedDk,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// A label/value row inside a terms card; [last] drops the trailing divider.
class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, this.last = false});

  final String label;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.bodySmall
                    .copyWith(color: KhatirColors.mutedDk),
              ),
            ),
            const SizedBox(width: KhatirSpacing.s3),
            Text(
              value,
              textAlign: TextAlign.end,
              style:
                  AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        if (!last) ...[
          const SizedBox(height: KhatirSpacing.s3),
          const Divider(height: 1, color: KhatirColors.line),
          const SizedBox(height: KhatirSpacing.s3),
        ],
      ],
    );
  }
}

/// A soft white card wrapper shared by the detail sections.
class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(KhatirSpacing.s4),
      decoration: BoxDecoration(
        color: KhatirColors.card,
        borderRadius: BorderRadius.circular(KhatirRadius.card),
      ),
      child: child,
    );
  }
}

/// A small status pill (sage-tinted) for a [LeaseStatus]. Mirrors the list
/// screen's chip so the status reads identically across the two screens.
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

/// A small uppercase section heading (matches the shared form section style).
class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: AppTextStyles.labelLarge.copyWith(
        color: KhatirColors.sageDk,
        fontWeight: FontWeight.w800,
        fontSize: 12,
        letterSpacing: 0.5,
      ),
    );
  }
}

/// The full-width danger-outlined terminate action.
class _TerminateButton extends StatelessWidget {
  const _TerminateButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(KhatirRadius.button),
    );
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: KhatirColors.danger,
          padding: const EdgeInsets.symmetric(vertical: KhatirSpacing.s4),
          textStyle: AppTextStyles.labelLarge,
          side: const BorderSide(color: KhatirColors.danger),
          shape: shape,
        ),
        child: Text(label),
      ),
    );
  }
}

/// Error state: a friendly message and a retry button (reloads the lease).
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

/// Localised display label for a [RentScheduleStatus].
String _schedStatusLabel(AppLocalizations l10n, RentScheduleStatus status) =>
    switch (status) {
      RentScheduleStatus.pending => l10n.lease_sched_status_pending,
      RentScheduleStatus.requested => l10n.lease_sched_status_requested,
      RentScheduleStatus.paid => l10n.lease_sched_status_paid,
      RentScheduleStatus.overdue => l10n.lease_sched_status_overdue,
    };
