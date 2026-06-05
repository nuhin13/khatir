import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khatir_tokens/khatir_tokens.dart';

import '../../../../core/i18n/bangla_numerals.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/billing_providers.dart';
import '../../data/models/plan_models.dart';

/// The landlord **Plan & billing** screen (EPIC-10 T-007), per the `plan`
/// prototype (`proto/screens-landlord2.js` → `reg('plan')`): a butter "you're
/// on X" banner with the current tenant usage, the active tier catalogue as
/// upgrade cards (current tier highlighted; the best-value tier ringed), and a
/// subscribe action per card.
///
/// Every value comes from one authenticated `GET /config/public` read via
/// [planConfigProvider] (the active `pricing.tiers` + the caller's
/// `subscription` block) — tier prices are never fetched separately. Tapping a
/// non-current tier posts to `/billing/subscribe` ([subscribeControllerProvider]);
/// payment is stubbed server-side, so the screen shows a "we'll confirm" message
/// and re-reads the config to refresh the usage + current-plan highlight.
///
/// States: loading (spinner), error (retry → re-fetch), empty (no tiers), data
/// (the full layout). Reachable at `/settings/plan` from the More menu. Colours,
/// spacing, radii and fonts all come from the shared design tokens.
class PlanScreen extends ConsumerWidget {
  const PlanScreen({super.key});

  static const String routePath = '/settings/plan';
  static const String routeName = 'plan';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(planConfigProvider);
    final subscribing = ref.watch(subscribeControllerProvider).isLoading;

    return Scaffold(
      backgroundColor: KhatirColors.cream,
      appBar: AppBar(
        backgroundColor: KhatirColors.cream,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          l10n.plan_title,
          style:
              AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        top: false,
        child: async.when(
          loading: () => const Center(
            key: ValueKey('planLoading'),
            child: CircularProgressIndicator(color: KhatirColors.sage),
          ),
          error: (_, _) => _ErrorState(
            l10n: l10n,
            onRetry: () => ref.read(planConfigProvider.notifier).refresh(),
          ),
          data: (config) {
            if (config.tiers.isEmpty) {
              return _EmptyState(l10n: l10n);
            }
            return _PlanBody(
              config: config,
              subscribing: subscribing,
              l10n: l10n,
              onSubscribe: (tier) => _subscribe(context, ref, tier),
            );
          },
        ),
      ),
    );
  }

  Future<void> _subscribe(
    BuildContext context,
    WidgetRef ref,
    PlanTier tier,
  ) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final ok = await ref
        .read(subscribeControllerProvider.notifier)
        .subscribe(tier.key);
    if (!context.mounted) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            ok ? l10n.plan_billing_confirm_pending : l10n.plan_billing_error,
          ),
        ),
      );
  }
}

/// The populated plan layout: the current-plan banner, the tier cards, and the
/// footer note.
class _PlanBody extends StatelessWidget {
  const _PlanBody({
    required this.config,
    required this.subscribing,
    required this.l10n,
    required this.onSubscribe,
  });

  final PlanConfig config;
  final bool subscribing;
  final AppLocalizations l10n;
  final ValueChanged<PlanTier> onSubscribe;

  @override
  Widget build(BuildContext context) {
    final localeCode = Localizations.localeOf(context).languageCode;
    final sub = config.subscription;
    final currentKey = sub?.tierKey ?? 'free';
    // The best-value tier is the unlimited (top) plan, mirroring the prototype's
    // single ringed card. Falls back to none when no unlimited tier exists.
    final bestKey = config.tiers
        .where((t) => t.isUnlimited)
        .map((t) => t.key)
        .lastOrNull;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        KhatirSpacing.s5,
        KhatirSpacing.s4,
        KhatirSpacing.s5,
        KhatirSpacing.s6,
      ),
      children: [
        if (sub != null)
          _CurrentBanner(
            subscription: sub,
            tiers: config.tiers,
            localeCode: localeCode,
            l10n: l10n,
          ),
        const SizedBox(height: KhatirSpacing.s4),
        for (final tier in config.tiers) ...[
          _TierCard(
            tier: tier,
            isCurrent: tier.key == currentKey,
            isBest: tier.key == bestKey,
            disabled: subscribing,
            localeCode: localeCode,
            l10n: l10n,
            onSubscribe: () => onSubscribe(tier),
          ),
          const SizedBox(height: KhatirSpacing.s3),
        ],
        const SizedBox(height: KhatirSpacing.s1),
        Text(
          l10n.plan_billing_note,
          textAlign: TextAlign.center,
          style: AppTextStyles.bodySmall.copyWith(
            color: KhatirColors.muted,
            fontFamily: KhatirFonts.mono,
          ),
        ),
      ],
    );
  }
}

/// The butter "you're on X" banner with the current tenant usage line.
class _CurrentBanner extends StatelessWidget {
  const _CurrentBanner({
    required this.subscription,
    required this.tiers,
    required this.localeCode,
    required this.l10n,
  });

  final PlanSubscription subscription;
  final List<PlanTier> tiers;
  final String localeCode;
  final AppLocalizations l10n;

  /// The display label for the current tier, preferring the catalogue's
  /// localized label and falling back to the raw key.
  String _currentLabel() {
    for (final t in tiers) {
      if (t.key == subscription.tierKey) {
        return localeCode == 'bn' ? t.labelBn : t.label;
      }
    }
    return subscription.tierKey;
  }

  @override
  Widget build(BuildContext context) {
    String fmt(int v) => BanglaNumerals.format(v, localeCode, grouped: false);
    final used = fmt(subscription.tenantsUsed);
    final limit = subscription.tenantLimit;
    final usageText = limit == null
        ? l10n.plan_usage_unlimited(used)
        : l10n.plan_usage(used, fmt(limit));

    return Container(
      key: const ValueKey('planCurrentBanner'),
      padding: const EdgeInsets.all(KhatirSpacing.s4),
      decoration: BoxDecoration(
        color: KhatirColors.butterBg,
        borderRadius: BorderRadius.circular(KhatirRadius.card),
      ),
      child: Row(
        children: [
          const Text('🎁', style: TextStyle(fontSize: 28)),
          const SizedBox(width: KhatirSpacing.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.plan_current_banner(_currentLabel()),
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  usageText,
                  key: const ValueKey('planUsage'),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: KhatirColors.mutedDk,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One tier card: label (+ "now" chip on the current tier), tenant band, price,
/// feature note, the best-value ribbon, and a subscribe action. The current
/// tier shows no action (it cannot be re-subscribed); others show "choose".
class _TierCard extends StatelessWidget {
  const _TierCard({
    required this.tier,
    required this.isCurrent,
    required this.isBest,
    required this.disabled,
    required this.localeCode,
    required this.l10n,
    required this.onSubscribe,
  });

  final PlanTier tier;
  final bool isCurrent;
  final bool isBest;
  final bool disabled;
  final String localeCode;
  final AppLocalizations l10n;
  final VoidCallback onSubscribe;

  String _band() {
    String fmt(int v) => BanglaNumerals.format(v, localeCode, grouped: false);
    if (tier.isUnlimited) return l10n.plan_band_unlimited;
    final max = tier.tenantMax!;
    final min = tier.tenantMin;
    if (min == null) return l10n.plan_band_min(fmt(max));
    return l10n.plan_band(fmt(min), fmt(max));
  }

  /// The headline price, localized. Free tiers read "Free"; others render the
  /// monthly price (falling back to annual) with the currency symbol.
  String _price() {
    if (tier.isFree) return l10n.plan_free;
    final amount = (tier.monthlyPrice ?? 0) > 0
        ? tier.monthlyPrice!
        : (tier.annualPrice ?? 0);
    return '৳${BanglaNumerals.format(amount.round(), localeCode)}';
  }

  String _priceSuffix() {
    if (tier.isFree) return '';
    // The per-tenant tier prices per tenant; everything else is per month.
    return tier.key.contains('tenant')
        ? l10n.plan_per_tenant_month
        : l10n.plan_per_month;
  }

  @override
  Widget build(BuildContext context) {
    final label = localeCode == 'bn' ? tier.labelBn : tier.label;
    final suffix = _priceSuffix();

    return Container(
      key: ValueKey('planTier-${tier.key}'),
      padding: const EdgeInsets.all(KhatirSpacing.s4),
      decoration: BoxDecoration(
        color: isCurrent ? KhatirColors.sageBg : KhatirColors.card,
        borderRadius: BorderRadius.circular(KhatirRadius.card),
        border: isBest
            ? Border.all(color: KhatirColors.sage, width: 2)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isBest) ...[
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                key: const ValueKey('planBestValue'),
                padding: const EdgeInsets.symmetric(
                  horizontal: KhatirSpacing.s2,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: KhatirColors.sageDk,
                  borderRadius: BorderRadius.circular(KhatirRadius.pill),
                ),
                child: Text(
                  l10n.plan_best_value,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: KhatirColors.card,
                    fontWeight: FontWeight.w800,
                    fontFamily: KhatirFonts.title,
                  ),
                ),
              ),
            ),
            const SizedBox(height: KhatirSpacing.s2),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            label,
                            style: AppTextStyles.titleMedium.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (isCurrent) ...[
                          const SizedBox(width: KhatirSpacing.s2),
                          _NowChip(label: l10n.plan_current),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _band(),
                      style: AppTextStyles.bodySmall.copyWith(
                        color: KhatirColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: KhatirSpacing.s2),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _price(),
                    style: AppTextStyles.titleLarge.copyWith(
                      fontWeight: FontWeight.w800,
                      color: KhatirColors.sageDk,
                    ),
                  ),
                  if (suffix.isNotEmpty)
                    Text(
                      suffix,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: KhatirColors.muted,
                      ),
                    ),
                ],
              ),
            ],
          ),
          if (tier.includesVerification) ...[
            const SizedBox(height: KhatirSpacing.s2),
            Text(
              l10n.plan_includes_verification,
              style: AppTextStyles.bodySmall.copyWith(
                color: KhatirColors.mutedDk,
              ),
            ),
          ],
          if (!isCurrent) ...[
            const SizedBox(height: KhatirSpacing.s3),
            _SubscribeButton(
              tierKey: tier.key,
              label: l10n.plan_choose,
              disabled: disabled,
              onTap: onSubscribe,
            ),
          ],
        ],
      ),
    );
  }
}

/// The small "now" chip marking the caller's current tier.
class _NowChip extends StatelessWidget {
  const _NowChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: KhatirSpacing.s2,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: KhatirColors.sage,
        borderRadius: BorderRadius.circular(KhatirRadius.chip),
      ),
      child: Text(
        label,
        style: AppTextStyles.bodySmall.copyWith(
          color: KhatirColors.card,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// The subscribe action on a non-current tier card. Disabled (greyed) while any
/// subscribe request is in flight so the user can't double-fire.
class _SubscribeButton extends StatelessWidget {
  const _SubscribeButton({
    required this.tierKey,
    required this.label,
    required this.disabled,
    required this.onTap,
  });

  final String tierKey;
  final String label;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(KhatirRadius.button);
    return Material(
      color: disabled ? KhatirColors.line : KhatirColors.sage,
      borderRadius: radius,
      child: InkWell(
        key: ValueKey('planSubscribe-$tierKey'),
        onTap: disabled ? null : onTap,
        borderRadius: radius,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: KhatirSpacing.s3),
          child: Center(
            child: Text(
              label,
              style: AppTextStyles.labelLarge.copyWith(
                color: disabled ? KhatirColors.mutedDk : KhatirColors.card,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Empty state shown when no tiers are configured (an unseeded environment).
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(KhatirSpacing.s6),
        child: Text(
          l10n.plan_empty,
          key: const ValueKey('planEmpty'),
          textAlign: TextAlign.center,
          style: AppTextStyles.bodyMedium.copyWith(color: KhatirColors.mutedDk),
        ),
      ),
    );
  }
}

/// Error state: a friendly message and a retry button (reloads `/config/public`).
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
                key: const ValueKey('planRetry'),
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
