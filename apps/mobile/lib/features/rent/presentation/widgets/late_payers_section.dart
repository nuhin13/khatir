import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khatir_tokens/khatir_tokens.dart';

import '../../../../core/i18n/bangla_numerals.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/models.dart';
import '../../data/models/rent_enums.dart';
import '../../data/providers.dart';
import '../screens/rent_request_screen.dart';

/// Home late-payers section (EPIC-07 T-014), filling the late-payer region that
/// the EPIC-03 home placeholder (`landlord_home_screen.dart` → `_CollectionCard`)
/// deferred. Mirrors the `home` prototype's rose overdue rows
/// (`proto/screens-landlord.js` → `reg('home')`): a clock badge, an
/// "N rent overdue" heading, the amount/period sub-line, and a per-row "Ask"
/// pill that routes into the rent-request flow.
///
/// "Late payers" are the unpaid requests in the landlord's rent-collection queue
/// — those still awaiting money, i.e. [RentRequestStatus.sent] (delivered, not
/// paid) or [RentRequestStatus.proofSubmitted] (proof in, not yet verified).
/// Verified/rejected requests are settled and never shown here. The list is read
/// from [rentQueueProvider] (the T-010 data layer); the charts / collected
/// amount stay with EPIC-09.
///
/// States: **loading** (a slim placeholder), **empty** ("all paid" reassurance),
/// **data** (the overdue rows). A load error degrades to the empty state rather
/// than shouting on the home screen. All colours/spacing/radii come from the
/// design tokens; numerals are localised via [BanglaNumerals].
class LatePayersSection extends ConsumerWidget {
  const LatePayersSection({super.key});

  /// Statuses that count as "still owing" — a late payer the landlord can chase.
  static const Set<RentRequestStatus> _unpaid = {
    RentRequestStatus.sent,
    RentRequestStatus.proofSubmitted,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final localeCode = Localizations.localeOf(context).languageCode;
    final queue = ref.watch(rentQueueProvider(null));

    return queue.when(
      loading: () => const _LoadingRow(),
      // A queue read failure should not blow up the home screen — fall back to
      // the calm "all paid" state.
      error: (_, _) => _AllPaidRow(l10n: l10n),
      data: (requests) {
        final overdue = requests
            .where((r) => _unpaid.contains(r.status))
            .toList(growable: false);
        if (overdue.isEmpty) return _AllPaidRow(l10n: l10n);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _OverdueCount(
              count: overdue.length,
              l10n: l10n,
              localeCode: localeCode,
            ),
            const SizedBox(height: KhatirSpacing.s2),
            for (var i = 0; i < overdue.length; i++) ...[
              if (i > 0) const SizedBox(height: KhatirSpacing.s2),
              _LatePayerRow(
                key: ValueKey('latePayer_${overdue[i].id}'),
                request: overdue[i],
                l10n: l10n,
                localeCode: localeCode,
              ),
            ],
          ],
        );
      },
    );
  }
}

/// The rose "N rent overdue" heading above the late-payer rows.
class _OverdueCount extends StatelessWidget {
  const _OverdueCount({
    required this.count,
    required this.l10n,
    required this.localeCode,
  });

  final int count;
  final AppLocalizations l10n;
  final String localeCode;

  @override
  Widget build(BuildContext context) {
    return Text(
      l10n.home_late_payers(BanglaNumerals.format(count, localeCode)),
      style: AppTextStyles.bodySmall.copyWith(
        color: KhatirColors.roseDk,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

/// A single overdue row: rose-tinted card with a clock badge, the amount/period
/// sub-line, and an "Ask" pill that opens the rent-request flow for that lease.
class _LatePayerRow extends StatelessWidget {
  const _LatePayerRow({
    super.key,
    required this.request,
    required this.l10n,
    required this.localeCode,
  });

  final RentRequest request;
  final AppLocalizations l10n;
  final String localeCode;

  void _ask(BuildContext context) {
    context.pushNamed(
      RentRequestScreen.routeName,
      queryParameters: <String, String>{
        'lease': request.leaseId,
        if (request.amount > 0) 'amount': request.amount.round().toString(),
        if (request.period.isNotEmpty) 'period': request.period,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final amount = l10n.home_currency_amount(
      BanglaNumerals.format(request.amount.round(), localeCode),
    );
    // "৳22,000 · 2025-05" — the amount and the billing period are all the queue
    // surfaces today (tenant/unit labels are not on the rent-request payload).
    // The period is a `YYYY-MM` string, so its digits are localised directly.
    final period = localeCode == 'bn'
        ? BanglaNumerals.toBangla(request.period)
        : request.period;
    final detail = request.period.isEmpty ? amount : '$amount · $period';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: KhatirSpacing.s3,
        vertical: KhatirSpacing.s2 + 2,
      ),
      decoration: BoxDecoration(
        color: KhatirColors.roseBg,
        borderRadius: BorderRadius.circular(KhatirRadius.tile),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: KhatirColors.card.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(KhatirRadius.tile),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.schedule_outlined,
              size: 18,
              color: KhatirColors.roseDk,
            ),
          ),
          const SizedBox(width: KhatirSpacing.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.home_late_payers_one,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: KhatirColors.roseDk,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: KhatirColors.mutedDk,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: KhatirSpacing.s2),
          _AskButton(onTap: () => _ask(context), label: l10n.home_quick_request),
        ],
      ),
    );
  }
}

/// The compact rose "Ask" pill that routes to the rent-request screen.
class _AskButton extends StatelessWidget {
  const _AskButton({required this.onTap, required this.label});

  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(KhatirRadius.pill);
    return Material(
      color: KhatirColors.roseDk,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: KhatirSpacing.s3,
            vertical: KhatirSpacing.s1 + 2,
          ),
          child: Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: KhatirColors.card,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

/// Calm "all paid" reassurance shown when no requests are outstanding.
class _AllPaidRow extends StatelessWidget {
  const _AllPaidRow({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: KhatirSpacing.s4,
        horizontal: KhatirSpacing.s4,
      ),
      decoration: BoxDecoration(
        color: KhatirColors.sageBg,
        borderRadius: BorderRadius.circular(KhatirRadius.tile),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.verified_outlined,
            size: 20,
            color: KhatirColors.sageDk,
          ),
          const SizedBox(width: KhatirSpacing.s3),
          Expanded(
            child: Text(
              l10n.home_all_paid,
              style: AppTextStyles.bodySmall.copyWith(
                color: KhatirColors.sageDk,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A slim placeholder while the rent queue loads, keeping the card height stable.
class _LoadingRow extends StatelessWidget {
  const _LoadingRow();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      width: double.infinity,
      decoration: BoxDecoration(
        color: KhatirColors.sageBg,
        borderRadius: BorderRadius.circular(KhatirRadius.tile),
      ),
      alignment: Alignment.center,
      child: const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: KhatirColors.sageDk,
        ),
      ),
    );
  }
}
