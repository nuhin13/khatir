import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khatir_tokens/khatir_tokens.dart';

import '../../../../core/auth/auth_controller.dart';
import '../../../../core/i18n/bangla_numerals.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../rent/presentation/widgets/late_payers_section.dart';
import '../../data/models/portfolio_summary.dart';
import '../../data/properties_providers.dart';

/// The landlord shell's Home tab body, mirroring the `home` prototype
/// (`proto/screens-landlord.js` → `reg('home')`, Direction A "Warm").
///
/// Composition, top to bottom:
/// * **Greeting** — handwritten salaam, the signed-in name, and a portfolio
///   one-liner (building + unit counts from `/portfolio`).
/// * **DMP hero CTA** — the prominent sage gradient card that routes into the
///   add-tenant / DMP flow (EPIC-04; `/tenants/add` placeholder for now). This
///   is the screen's flagship action and keeps the prototype's prominence.
/// * **Quick stat tiles** — buildings, units, and monthly rent total, all from
///   the portfolio totals.
/// * **Collection summary card** — "collected this month" heading with the
///   detailed amount/chart and the late-payer list deferred to EPIC-09/07
///   (regions marked `TODO(EPIC-09)`).
///
/// States: loading (spinner), error (retry), empty (no buildings → friendly
/// empty state with an add-building CTA), and data. All colors/spacing/radii
/// come from the design tokens; numerals are localised via [BanglaNumerals].
class LandlordHomeScreen extends ConsumerWidget {
  const LandlordHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final portfolio = ref.watch(portfolioProvider);

    return Scaffold(
      backgroundColor: KhatirColors.cream,
      body: SafeArea(
        bottom: false,
        child: portfolio.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => _ErrorState(
            l10n: l10n,
            onRetry: () => ref.read(portfolioProvider.notifier).refresh(),
          ),
          data: (summary) {
            if (summary.totals.buildings == 0 && summary.buildings.isEmpty) {
              return _EmptyState(
                l10n: l10n,
                onAddBuilding: () => _addBuilding(context),
              );
            }
            return _HomeBody(summary: summary);
          },
        ),
      ),
    );
  }

  /// Routes the center/hero DMP action into the add-tenant flow. EPIC-04 builds
  /// the real wizard at `/tenants/add`; until then app_router maps it to a
  /// placeholder push.
  // TODO(EPIC-04) point at the real /tenants/add DMP wizard entry.
  static void _startDmp(BuildContext context) => context.pushNamed('tenantsAdd');

  /// Add-building CTA → the 4-step add-building wizard (T-010).
  static void _addBuilding(BuildContext context) {
    context.pushNamed('addBuilding');
  }
}

/// The populated home content (greeting + hero CTA + stats + collection card).
class _HomeBody extends ConsumerWidget {
  const _HomeBody({required this.summary});

  final PortfolioSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final localeCode = Localizations.localeOf(context).languageCode;
    final user = ref.watch(
      authControllerProvider.select((s) => s.valueOrNull?.user),
    );
    final name = (user?.name?.trim().isNotEmpty ?? false)
        ? user!.name!.trim()
        : l10n.home_name_fallback;
    final totals = summary.totals;

    return RefreshIndicator(
      onRefresh: () => ref.read(portfolioProvider.notifier).refresh(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          KhatirSpacing.s5,
          KhatirSpacing.s2,
          KhatirSpacing.s5,
          KhatirSpacing.s6,
        ),
        children: [
          _Greeting(name: name, totals: totals, localeCode: localeCode),
          const SizedBox(height: KhatirSpacing.s4),
          _DmpHeroCard(onTap: () => LandlordHomeScreen._startDmp(context)),
          const SizedBox(height: KhatirSpacing.s4),
          _StatTiles(totals: totals, localeCode: localeCode),
          const SizedBox(height: KhatirSpacing.s3),
          const _CollectionCard(),
        ],
      ),
    );
  }
}

/// Handwritten salaam + name + the building/unit one-liner.
class _Greeting extends StatelessWidget {
  const _Greeting({
    required this.name,
    required this.totals,
    required this.localeCode,
  });

  final String name;
  final PortfolioTotals totals;
  final String localeCode;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final summaryLine = l10n.home_summary_line(
      BanglaNumerals.format(totals.buildings, localeCode),
      BanglaNumerals.format(totals.totalUnits, localeCode),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.home_greeting,
          style: AppTextStyles.accent.copyWith(fontSize: 25, height: 1),
        ),
        const SizedBox(height: KhatirSpacing.s1 / 2),
        Row(
          children: [
            Flexible(
              child: Text(
                name,
                style: AppTextStyles.titleLarge.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 23,
                ),
              ),
            ),
            const SizedBox(width: KhatirSpacing.s2),
            const Text('👋', style: TextStyle(fontSize: 18)),
          ],
        ),
        const SizedBox(height: KhatirSpacing.s1 / 2),
        Text(
          summaryLine,
          style: AppTextStyles.bodySmall.copyWith(color: KhatirColors.muted),
        ),
      ],
    );
  }
}

/// The flagship sage-gradient DMP CTA — the screen's hero. Matches the
/// prototype's prominence (badge chip, big title, explainer, start pill).
class _DmpHeroCard extends StatelessWidget {
  const _DmpHeroCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final radius = BorderRadius.circular(KhatirRadius.xl);
    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [KhatirColors.sage, KhatirColors.sageDk],
            ),
            borderRadius: radius,
            boxShadow: [
              BoxShadow(
                color: KhatirColors.sageDk.withValues(alpha: 0.35),
                blurRadius: 40,
                offset: const Offset(0, 20),
                spreadRadius: -16,
              ),
            ],
          ),
          padding: const EdgeInsets.all(KhatirSpacing.s5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HeroChip(label: l10n.home_dmp_cta_badge),
              const SizedBox(height: KhatirSpacing.s3),
              Text(
                l10n.home_dmp_cta,
                style: AppTextStyles.headlineMedium.copyWith(
                  color: KhatirColors.card,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: KhatirSpacing.s2 - 1),
              Text(
                l10n.home_dmp_cta_sub,
                style: AppTextStyles.bodySmall.copyWith(
                  color: KhatirColors.card.withValues(alpha: 0.92),
                ),
              ),
              const SizedBox(height: KhatirSpacing.s4),
              _HeroActionPill(label: l10n.home_dmp_cta_action),
            ],
          ),
        ),
      ),
    );
  }
}

/// Translucent badge chip on the hero card.
class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: KhatirSpacing.s3,
        vertical: KhatirSpacing.s1 + 1,
      ),
      decoration: BoxDecoration(
        color: KhatirColors.card.withValues(alpha: 0.22),
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

/// "Start" pill with a trailing arrow on the hero card.
class _HeroActionPill extends StatelessWidget {
  const _HeroActionPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: KhatirSpacing.s4,
        vertical: KhatirSpacing.s2 + 1,
      ),
      decoration: BoxDecoration(
        color: KhatirColors.card.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(KhatirRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTextStyles.labelLarge.copyWith(
              color: KhatirColors.card,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: KhatirSpacing.s2),
          const Icon(Icons.arrow_forward, size: 16, color: KhatirColors.card),
        ],
      ),
    );
  }
}

/// Three quick-stat tiles: buildings, units, and monthly rent total.
class _StatTiles extends StatelessWidget {
  const _StatTiles({required this.totals, required this.localeCode});

  final PortfolioTotals totals;
  final String localeCode;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final rent = l10n.home_currency_amount(
      BanglaNumerals.format(totals.totalRent.round(), localeCode),
    );
    // Buildings/units tiles open the portfolio list (T-012).
    void openPortfolio() => context.pushNamed('portfolio');
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            icon: Icons.apartment_outlined,
            value: BanglaNumerals.format(totals.buildings, localeCode),
            label: l10n.home_stat_buildings,
            onTap: openPortfolio,
          ),
        ),
        const SizedBox(width: KhatirSpacing.s3),
        Expanded(
          child: _StatTile(
            icon: Icons.meeting_room_outlined,
            value: BanglaNumerals.format(totals.totalUnits, localeCode),
            label: l10n.home_stat_units,
            onTap: openPortfolio,
          ),
        ),
        const SizedBox(width: KhatirSpacing.s3),
        Expanded(
          child: _StatTile(
            icon: Icons.payments_outlined,
            value: rent,
            label: l10n.home_stat_monthly,
            highlight: true,
          ),
        ),
      ],
    );
  }
}

/// A single rounded stat box (icon badge, big number, small caption).
class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
    this.highlight = false,
    this.onTap,
  });

  final IconData icon;
  final String value;
  final String label;

  /// The monthly-rent tile is butter-tinted with a rose value, mirroring the
  /// prototype's emphasised money box.
  final bool highlight;

  /// Optional tap handler (buildings/units tiles open the portfolio).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bg = highlight ? KhatirColors.butterBg : KhatirColors.card;
    final fg = highlight ? KhatirColors.roseDk : KhatirColors.sageDk;
    final radius = BorderRadius.circular(KhatirRadius.card);
    final tile = Container(
      padding: const EdgeInsets.symmetric(
        vertical: KhatirSpacing.s4,
        horizontal: KhatirSpacing.s2,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: radius,
      ),
      child: Column(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: highlight
                  ? KhatirColors.card.withValues(alpha: 0.6)
                  : KhatirColors.sageBg,
              borderRadius: BorderRadius.circular(KhatirRadius.tile),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 18, color: fg),
          ),
          const SizedBox(height: KhatirSpacing.s2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.titleLarge.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: highlight ? 17 : 20,
              color: highlight ? KhatirColors.roseDk : KhatirColors.ink,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(
              color: highlight ? KhatirColors.mutedDk : KhatirColors.muted,
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return tile;
    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: tile,
      ),
    );
  }
}

/// Collection summary card. The "collected this month" heading is real and the
/// late-payer region is now filled by [LatePayersSection] (EPIC-07 T-014). The
/// collected/expected amount and the progress chart still land in EPIC-09, so
/// that region remains a marked placeholder.
class _CollectionCard extends StatelessWidget {
  const _CollectionCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(KhatirSpacing.s4),
      decoration: BoxDecoration(
        color: KhatirColors.card,
        borderRadius: BorderRadius.circular(KhatirRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.home_collected,
            style: AppTextStyles.bodySmall.copyWith(
              color: KhatirColors.muted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: KhatirSpacing.s3),
          // TODO(EPIC-09) replace with the real collected/expected amount +
          // progress chart. The late-payer list below is real (EPIC-07 T-014).
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              vertical: KhatirSpacing.s5,
              horizontal: KhatirSpacing.s4,
            ),
            decoration: BoxDecoration(
              color: KhatirColors.sageBg,
              borderRadius: BorderRadius.circular(KhatirRadius.tile),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.insights_outlined,
                  size: 20,
                  color: KhatirColors.sageDk,
                ),
                const SizedBox(width: KhatirSpacing.s3),
                Expanded(
                  child: Text(
                    l10n.home_collected_todo,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: KhatirColors.sageDk,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: KhatirSpacing.s3),
          const LatePayersSection(),
        ],
      ),
    );
  }
}

/// Friendly empty state shown when the landlord has no buildings yet: an emoji
/// hero, a prompt, and the add-building CTA.
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.l10n, required this.onAddBuilding});

  final AppLocalizations l10n;
  final VoidCallback onAddBuilding;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(KhatirSpacing.s6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🏢', style: TextStyle(fontSize: 56)),
            const SizedBox(height: KhatirSpacing.s4),
            Text(
              l10n.home_empty_title,
              textAlign: TextAlign.center,
              style: AppTextStyles.titleLarge.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: KhatirSpacing.s2),
            Text(
              l10n.home_empty_body,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: KhatirColors.mutedDk,
              ),
            ),
            const SizedBox(height: KhatirSpacing.s5),
            _PrimaryButton(label: l10n.home_add_building, onTap: onAddBuilding),
          ],
        ),
      ),
    );
  }
}

/// Error state: a friendly message and a retry button (reloads `/portfolio`).
class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.l10n, required this.onRetry});

  final AppLocalizations l10n;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(KhatirSpacing.s6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.common_network_error,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: KhatirColors.mutedDk,
              ),
            ),
            const SizedBox(height: KhatirSpacing.s4),
            _PrimaryButton(label: l10n.common_retry, onTap: onRetry),
          ],
        ),
      ),
    );
  }
}

/// Sage full-width primary button used by the empty/error states.
class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onTap});

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
          padding: const EdgeInsets.symmetric(
            horizontal: KhatirSpacing.s6,
            vertical: KhatirSpacing.s4,
          ),
          child: Text(
            label,
            style: AppTextStyles.labelLarge.copyWith(
              color: KhatirColors.card,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
