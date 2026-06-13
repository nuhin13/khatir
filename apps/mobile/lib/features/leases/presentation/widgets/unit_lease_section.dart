import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khatir_tokens/khatir_tokens.dart';

import '../../../../core/i18n/bangla_numerals.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../rent/presentation/screens/rent_request_screen.dart';
import '../../../tenants/data/models/tenant_enums.dart';
import '../../../verification/presentation/screens/verify_screen.dart';
import '../../../verification/presentation/widgets/verification_badge.dart';
import '../../data/models/lease_enums.dart';
import '../../data/models/models.dart';
import '../../data/providers.dart';
import '../screens/lease_detail_screen.dart';
import '../screens/lease_form_screen.dart';
import '../screens/lease_list_screen.dart';

/// The live lease/tenant region on the unit-detail screen (EPIC-06 T-009),
/// filling the placeholder EPIC-03 T-013 left under the tenant-section heading.
///
/// It reads the unit's current (active) lease via [unitLeaseProvider]. The
/// backend returns the active lease + an embedded tenant summary, or a 404 when
/// the unit has no active lease; that 404 (and any other error) surfaces via
/// [AsyncValue.error] and is treated as the **no-lease** empty state, which
/// shows a friendly card and a "Create lease" CTA → `/lease/new?unit=<id>`.
///
/// When a lease is present it renders a summary card — tenant name + verification,
/// the status chip, the monthly rent, the term range, and the next upcoming
/// (unpaid) rent period from the schedule ([leaseScheduleProvider]) — tappable
/// to the lease detail ([LeaseListScreen]/[LeaseDetailScreen] route), plus a
/// "Request rent" CTA → the rent-request screen (EPIC-07) carrying the lease id.
///
/// Every colour/spacing/radius/font comes from the design tokens; numerals are
/// localised via [BanglaNumerals].
class UnitLeaseSection extends ConsumerWidget {
  const UnitLeaseSection({required this.unitId, super.key});

  /// The unit whose active lease (if any) is summarised.
  final String unitId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final leaseAsync = ref.watch(unitLeaseProvider(unitId));

    return leaseAsync.when(
      loading: () => const _LeaseLoadingCard(),
      // A 404 (no active lease) and any other read error both land here; the
      // unit-detail seam treats "no lease" as the create-lease empty state.
      error: (_, _) => _NoLeaseCard(
        onCreate: () => _createLease(context),
      ),
      data: (unitLease) => _ActiveLeaseCard(
        unitLease: unitLease,
        localeCode: Localizations.localeOf(context).languageCode,
        onOpen: () => _openLease(context, unitLease.lease.id),
        onRequestRent: () => _requestRent(context, unitLease.lease.id),
      ),
    ).withHeading(l10n.unit_lease_active);
  }

  /// Create-lease CTA → the lease form in unit context (`?unit=<id>`). The form
  /// pops back here on save, so the section re-fetches the freshly created
  /// (and, if activated, scheduled) lease.
  void _createLease(BuildContext context) {
    GoRouter.of(context).pushNamed(
      LeaseFormScreen.routeName,
      queryParameters: {'unit': unitId},
    );
  }

  /// Opens the lease detail for [leaseId].
  void _openLease(BuildContext context, String leaseId) {
    GoRouter.of(context).pushNamed(
      LeaseDetailScreen.routeName,
      pathParameters: {'id': leaseId},
    );
  }

  /// Request-rent CTA → the rent-request screen (EPIC-07), carrying the active
  /// lease id as the `?lease=` target.
  void _requestRent(BuildContext context, String leaseId) {
    GoRouter.of(context).pushNamed(
      RentRequestScreen.routeName,
      queryParameters: {'lease': leaseId},
    );
  }
}

/// Wraps a lease-region body in the shared section heading so the heading is
/// rendered exactly once regardless of which state ([_ActiveLeaseCard] /
/// [_NoLeaseCard] / [_LeaseLoadingCard]) is shown.
extension on Widget {
  Widget withHeading(String heading) => Builder(
        builder: (context) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              heading,
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: KhatirSpacing.s3),
            this,
          ],
        ),
      );
}

/// The active-lease summary: a tappable soft card with the tenant, status chip,
/// rent, term, the next-due period, and a request-rent CTA.
class _ActiveLeaseCard extends ConsumerWidget {
  const _ActiveLeaseCard({
    required this.unitLease,
    required this.localeCode,
    required this.onOpen,
    required this.onRequestRent,
  });

  final UnitLease unitLease;
  final String localeCode;
  final VoidCallback onOpen;
  final VoidCallback onRequestRent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final lease = unitLease.lease;
    final tenant = unitLease.tenant;
    final radius = BorderRadius.circular(KhatirRadius.card);

    final scheduleAsync = ref.watch(leaseScheduleProvider(lease.id));
    final nextDue = scheduleAsync.maybeWhen(
      data: _nextUpcoming,
      orElse: () => null,
    );

    return Material(
      color: KhatirColors.card,
      borderRadius: radius,
      child: InkWell(
        onTap: onOpen,
        borderRadius: radius,
        child: Padding(
          padding: const EdgeInsets.all(KhatirSpacing.s4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _TenantAvatar(name: tenant?.name ?? ''),
                  const SizedBox(width: KhatirSpacing.s3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (tenant?.name.isNotEmpty ?? false)
                              ? tenant!.name
                              : '—',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodyLarge.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (tenant != null) ...[
                          const SizedBox(height: KhatirSpacing.s1),
                          VerificationBadge(
                            key: ValueKey('verificationBadge_${tenant.id}'),
                            status: tenant.verificationStatus,
                            onTap: tenant.verificationStatus !=
                                    VerificationStatus.matched
                                ? () => context.pushNamed(
                                      VerifyScreen.routeName,
                                      pathParameters: {'id': tenant.id},
                                    )
                                : null,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: KhatirSpacing.s2),
                  _LeaseStatusChip(status: lease.status),
                ],
              ),
              const SizedBox(height: KhatirSpacing.s3),
              _LeaseFactRow(
                label: l10n.lease_rent_amount,
                value: l10n.unit_rent_per_month(
                  BanglaNumerals.format(lease.rent.round(), localeCode),
                ),
              ),
              const SizedBox(height: KhatirSpacing.s1 + 2),
              _LeaseFactRow(
                label: l10n.unit_lease_term,
                value: termRange(context, lease),
              ),
              const SizedBox(height: KhatirSpacing.s1 + 2),
              _LeaseFactRow(
                label: l10n.unit_next_due,
                value: nextDue == null
                    ? l10n.unit_next_due_none
                    : l10n.unit_next_due_value(
                        BanglaNumerals.format(nextDue.amount.round(), localeCode),
                        nextDue.period,
                      ),
              ),
              const SizedBox(height: KhatirSpacing.s4),
              _RequestRentButton(
                label: l10n.unit_lease_request_rent,
                onTap: onRequestRent,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The next upcoming (unpaid) period: the earliest pending/requested/overdue
  /// row by due date, or null when every period is settled.
  static RentSchedule? _nextUpcoming(List<RentSchedule> schedule) {
    final upcoming = schedule
        .where((r) => r.status != RentScheduleStatus.paid)
        .toList(growable: false)
      ..sort((a, b) {
        final ad = a.dueDate;
        final bd = b.dueDate;
        if (ad == null && bd == null) return a.period.compareTo(b.period);
        if (ad == null) return 1;
        if (bd == null) return -1;
        return ad.compareTo(bd);
      });
    return upcoming.isEmpty ? null : upcoming.first;
  }
}

/// A circular tenant initial avatar (rose-tinted), matching the prototype's
/// tenant row card.
class _TenantAvatar extends StatelessWidget {
  const _TenantAvatar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        color: KhatirColors.roseBg,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: AppTextStyles.bodyLarge.copyWith(
          color: KhatirColors.roseDk,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

/// A label/value row inside the lease summary card (label muted on the left,
/// value bold on the right).
class _LeaseFactRow extends StatelessWidget {
  const _LeaseFactRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: KhatirColors.mutedDk,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: KhatirSpacing.s3),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w700,
              color: KhatirColors.ink,
            ),
          ),
        ),
      ],
    );
  }
}

/// The lease status chip (sage for active, muted otherwise).
class _LeaseStatusChip extends StatelessWidget {
  const _LeaseStatusChip({required this.status});

  final LeaseStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final active = status == LeaseStatus.active;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: KhatirSpacing.s2,
        vertical: KhatirSpacing.s1 - 1,
      ),
      decoration: BoxDecoration(
        color: active ? KhatirColors.sageBg : KhatirColors.line,
        borderRadius: BorderRadius.circular(KhatirRadius.chip),
      ),
      child: Text(
        leaseStatusLabel(l10n, status),
        style: AppTextStyles.bodySmall.copyWith(
          color: active ? KhatirColors.sageDk : KhatirColors.mutedDk,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Soft full-width "Request rent" button (sage-tinted, leading send icon).
class _RequestRentButton extends StatelessWidget {
  const _RequestRentButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(KhatirRadius.button);
    return Material(
      color: KhatirColors.sage,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: KhatirSpacing.s3),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.send_outlined, size: 16, color: KhatirColors.card),
              const SizedBox(width: KhatirSpacing.s2),
              Text(
                label,
                style: AppTextStyles.labelLarge.copyWith(
                  color: KhatirColors.card,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The no-active-lease empty state: a friendly card + "Create lease" CTA.
class _NoLeaseCard extends StatelessWidget {
  const _NoLeaseCard({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(KhatirSpacing.s5),
      decoration: BoxDecoration(
        color: KhatirColors.card,
        borderRadius: BorderRadius.circular(KhatirRadius.card),
      ),
      child: Column(
        children: [
          const Text('📄', style: TextStyle(fontSize: 40)),
          const SizedBox(height: KhatirSpacing.s3),
          Text(
            l10n.unit_lease_none,
            textAlign: TextAlign.center,
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: KhatirSpacing.s1),
          Text(
            l10n.unit_lease_none_body,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(color: KhatirColors.mutedDk),
          ),
          const SizedBox(height: KhatirSpacing.s4),
          _CreateLeaseButton(label: l10n.unit_create_lease, onTap: onCreate),
        ],
      ),
    );
  }
}

/// Soft full-width "Create lease" button (sage-tinted, leading doc icon).
class _CreateLeaseButton extends StatelessWidget {
  const _CreateLeaseButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(KhatirRadius.button);
    return Material(
      color: KhatirColors.sage,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: KhatirSpacing.s4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.note_add_outlined,
                  size: 18, color: KhatirColors.card),
              const SizedBox(width: KhatirSpacing.s2),
              Text(
                label,
                style: AppTextStyles.labelLarge.copyWith(
                  color: KhatirColors.card,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A short inline loading card while the unit's lease is pending.
class _LeaseLoadingCard extends StatelessWidget {
  const _LeaseLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(KhatirSpacing.s5),
      decoration: BoxDecoration(
        color: KhatirColors.card,
        borderRadius: BorderRadius.circular(KhatirRadius.card),
      ),
      alignment: Alignment.center,
      child: const SizedBox(
        height: 18,
        width: 18,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }
}

// _verificationLabel removed — replaced by VerificationBadge (T-007).
