import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khatir_tokens/khatir_tokens.dart';

import '../../../../core/i18n/bangla_numerals.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/portfolio_summary.dart';
import '../../data/models/property_enums.dart';
import '../../data/models/unit.dart';
import '../../data/properties_providers.dart';

/// The landlord's property portfolio, mirroring the `portfolio` prototype
/// (`proto/screens-landlord.js` → `reg('portfolio')`).
///
/// Composition, top to bottom:
/// * **Top bar** — title + an add-building action (the `+` icon button).
/// * **Two summary stat boxes** — building count and the occupied/total units
///   ratio, from `/portfolio` totals.
/// * **Building cards** — one per building: name + area header, an expandable
///   strip of unit chips (occupied chips sage-tinted, vacant rose-tinted), and
///   a three-up footer (total units · occupied · monthly rent). Tapping a card
///   header expands it and lazily loads that building's units; tapping a unit
///   chip drills into `/properties/unit/:id` (T-013).
/// * **Add-building CTA** — a soft full-width button → `/properties/add` (the
///   wizard, T-010/T-011).
///
/// States: loading (spinner), error (retry), empty (no buildings → friendly
/// empty state with an add-building CTA), and data. All colors/spacing/radii
/// come from the design tokens; numerals are localised via [BanglaNumerals].
class PortfolioScreen extends ConsumerWidget {
  const PortfolioScreen({super.key});

  /// Top-level route for the portfolio list (reached from the landlord home).
  static const String routePath = '/properties';
  static const String routeName = 'portfolio';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final portfolio = ref.watch(portfolioProvider);

    return Scaffold(
      backgroundColor: KhatirColors.cream,
      appBar: AppBar(
        backgroundColor: KhatirColors.cream,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          l10n.portfolio_title,
          style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: KhatirColors.ink),
            tooltip: l10n.portfolio_add_building,
            onPressed: () => _addBuilding(context, l10n),
          ),
          const SizedBox(width: KhatirSpacing.s1),
        ],
      ),
      body: SafeArea(
        top: false,
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
                onAddBuilding: () => _addBuilding(context, l10n),
              );
            }
            return _PortfolioBody(summary: summary);
          },
        ),
      ),
    );
  }

  /// Add-building CTA. The wizard route (`/properties/add`) is registered by
  /// T-010/T-011; until then this falls back to a friendly coming-soon
  /// snackbar so the action is never a dead end.
  // TODO(EPIC-03) route to the /properties/add wizard once registered.
  static void _addBuilding(BuildContext context, AppLocalizations l10n) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.portfolio_add_building)));
  }

  /// Drills into a unit's detail screen, registered as `/properties/unit/:id`
  /// by T-013.
  static void _openUnit(BuildContext context, String unitId) {
    GoRouter.of(context).push('/properties/unit/$unitId');
  }
}

/// The populated portfolio content (summary stats + building cards + CTA).
class _PortfolioBody extends ConsumerWidget {
  const _PortfolioBody({required this.summary});

  final PortfolioSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final localeCode = Localizations.localeOf(context).languageCode;
    final totals = summary.totals;

    return RefreshIndicator(
      onRefresh: () => ref.read(portfolioProvider.notifier).refresh(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          KhatirSpacing.s5,
          KhatirSpacing.s4,
          KhatirSpacing.s5,
          KhatirSpacing.s6,
        ),
        children: [
          _SummaryRow(totals: totals, localeCode: localeCode),
          const SizedBox(height: KhatirSpacing.s4 - 2),
          for (final building in summary.buildings) ...[
            _BuildingCard(building: building, localeCode: localeCode),
            const SizedBox(height: KhatirSpacing.s3),
          ],
          const SizedBox(height: KhatirSpacing.s1),
          _AddBuildingButton(
            label: l10n.portfolio_add_building,
            onTap: () => PortfolioScreen._addBuilding(context, l10n),
          ),
        ],
      ),
    );
  }
}

/// The two top summary boxes: building count and occupied/total units.
class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.totals, required this.localeCode});

  final PortfolioTotals totals;
  final String localeCode;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final occupancy = l10n.portfolio_occupancy(
      BanglaNumerals.format(totals.occupied, localeCode),
      BanglaNumerals.format(totals.totalUnits, localeCode),
    );
    return Row(
      children: [
        Expanded(
          child: _StatBox(
            icon: Icons.apartment_outlined,
            value: BanglaNumerals.format(totals.buildings, localeCode),
            label: l10n.portfolio_stat_buildings,
          ),
        ),
        const SizedBox(width: KhatirSpacing.s3 - 2),
        Expanded(
          child: _StatBox(
            icon: Icons.meeting_room_outlined,
            value: occupancy,
            label: l10n.portfolio_stat_occupied,
          ),
        ),
      ],
    );
  }
}

/// A single rounded summary box (icon badge, big number, caption).
class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: KhatirSpacing.s4,
        horizontal: KhatirSpacing.s3,
      ),
      decoration: BoxDecoration(
        color: KhatirColors.card,
        borderRadius: BorderRadius.circular(KhatirRadius.card),
      ),
      child: Column(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: KhatirColors.sageBg,
              borderRadius: BorderRadius.circular(KhatirRadius.tile),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 18, color: KhatirColors.sageDk),
          ),
          const SizedBox(height: KhatirSpacing.s2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.titleLarge.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(color: KhatirColors.muted),
          ),
        ],
      ),
    );
  }
}

/// One building card: header (icon + name/area + chevron), an expandable strip
/// of unit chips (lazily loaded on first expand), and a three-up stat footer.
class _BuildingCard extends ConsumerStatefulWidget {
  const _BuildingCard({required this.building, required this.localeCode});

  final BuildingSummary building;
  final String localeCode;

  @override
  ConsumerState<_BuildingCard> createState() => _BuildingCardState();
}

class _BuildingCardState extends ConsumerState<_BuildingCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final b = widget.building;
    final code = widget.localeCode;
    final radius = BorderRadius.circular(KhatirRadius.card);

    return Container(
      decoration: BoxDecoration(
        color: KhatirColors.card,
        borderRadius: radius,
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.all(KhatirSpacing.s4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(building: b),
                if (_expanded) ...[
                  const SizedBox(height: KhatirSpacing.s3 - 1),
                  _UnitChips(buildingId: b.id),
                ],
                const SizedBox(height: KhatirSpacing.s3),
                const Divider(height: 1, thickness: 1, color: KhatirColors.line),
                const SizedBox(height: KhatirSpacing.s3),
                _Footer(building: b, localeCode: code),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Building-card header: square icon badge, name + area, expand chevron.
class _Header extends StatelessWidget {
  const _Header({required this.building});

  final BuildingSummary building;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final area = building.area;
    final subtitle = area == null ? null : areaLabel(l10n, area);
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: KhatirColors.sageBg,
            borderRadius: BorderRadius.circular(KhatirRadius.tile),
          ),
          alignment: Alignment.center,
          child: const Icon(
            Icons.apartment_outlined,
            size: 22,
            color: KhatirColors.sageDk,
          ),
        ),
        const SizedBox(width: KhatirSpacing.s3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                building.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 1),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: KhatirColors.muted),
                ),
              ],
            ],
          ),
        ),
        const Icon(Icons.chevron_right, size: 20, color: KhatirColors.muted),
      ],
    );
  }
}

/// The expandable strip of unit chips for one building, loaded lazily from
/// `GET /buildings/{id}/units`. Occupied chips are sage-tinted, others
/// rose-tinted; tapping a chip drills into `/properties/unit/:id` (T-013).
class _UnitChips extends ConsumerWidget {
  const _UnitChips({required this.buildingId});

  final String buildingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final units = ref.watch(buildingUnitsProvider(buildingId));
    return units.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: KhatirSpacing.s2),
        child: SizedBox(
          height: 18,
          width: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (list) {
        if (list.isEmpty) return const SizedBox.shrink();
        return Wrap(
          spacing: KhatirSpacing.s1 + 1,
          runSpacing: KhatirSpacing.s1 + 1,
          children: [
            for (final unit in list)
              _UnitChip(
                unit: unit,
                onTap: () => PortfolioScreen._openUnit(context, unit.id),
              ),
          ],
        );
      },
    );
  }
}

/// One unit chip: sage when occupied, rose otherwise.
class _UnitChip extends StatelessWidget {
  const _UnitChip({required this.unit, required this.onTap});

  final Unit unit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final occupied = unit.status == UnitStatus.occupied;
    final bg = occupied ? KhatirColors.sageBg : KhatirColors.roseBg;
    final fg = occupied ? KhatirColors.sageDk : KhatirColors.roseDk;
    final radius = BorderRadius.circular(KhatirRadius.xs - 3);
    return Material(
      color: bg,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: KhatirSpacing.s2,
            vertical: KhatirSpacing.s1 - 1,
          ),
          child: Text(
            unit.label,
            style: AppTextStyles.bodySmall.copyWith(
              fontFamily: KhatirFonts.title,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ),
      ),
    );
  }
}

/// Three-up footer: total units, occupied, monthly rent.
class _Footer extends StatelessWidget {
  const _Footer({required this.building, required this.localeCode});

  final BuildingSummary building;
  final String localeCode;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final rent = l10n.home_currency_amount(
      BanglaNumerals.format(building.totalRent.round(), localeCode),
    );
    return Row(
      children: [
        Expanded(
          child: _FooterStat(
            value: BanglaNumerals.format(building.totalUnits, localeCode),
            label: l10n.portfolio_units,
          ),
        ),
        Expanded(
          child: _FooterStat(
            value: BanglaNumerals.format(building.occupied, localeCode),
            label: l10n.portfolio_occupied,
            color: KhatirColors.sageDk,
          ),
        ),
        Expanded(
          child: _FooterStat(
            value: rent,
            label: l10n.portfolio_monthly,
            color: KhatirColors.roseDk,
          ),
        ),
      ],
    );
  }
}

/// A single centered footer stat (big value + tiny caption).
class _FooterStat extends StatelessWidget {
  const _FooterStat({
    required this.value,
    required this.label,
    this.color,
  });

  final String value;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 17,
            color: color ?? KhatirColors.ink,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.bodySmall.copyWith(
            color: KhatirColors.muted,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

/// Soft full-width "Add building" button (sage-tinted, leading plus icon).
class _AddBuildingButton extends StatelessWidget {
  const _AddBuildingButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(KhatirRadius.button);
    return Material(
      color: KhatirColors.sageBg,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: KhatirSpacing.s4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add, size: 18, color: KhatirColors.sageDk),
              const SizedBox(width: KhatirSpacing.s2),
              Text(
                label,
                style: AppTextStyles.labelLarge.copyWith(
                  color: KhatirColors.sageDk,
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

/// Friendly empty state shown when the landlord has no buildings yet.
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
              l10n.portfolio_empty_title,
              textAlign: TextAlign.center,
              style: AppTextStyles.titleLarge.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: KhatirSpacing.s2),
            Text(
              l10n.portfolio_empty,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: KhatirColors.mutedDk),
            ),
            const SizedBox(height: KhatirSpacing.s5),
            _PrimaryButton(
              label: l10n.portfolio_add_building,
              onTap: onAddBuilding,
            ),
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
              style: AppTextStyles.bodyMedium
                  .copyWith(color: KhatirColors.mutedDk),
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

/// Localized display label for an [Area] enum value. Wire values map 1:1 to
/// `area_*` ARB keys (bn + en). Domain values stay in [property_enums]; only
/// the human label lives in l10n.
String areaLabel(AppLocalizations l10n, Area area) => switch (area) {
      Area.uttara => l10n.area_uttara,
      Area.mirpur => l10n.area_mirpur,
      Area.mohammadpur => l10n.area_mohammadpur,
      Area.dhanmondi => l10n.area_dhanmondi,
      Area.banasree => l10n.area_banasree,
      Area.gulshan => l10n.area_gulshan,
      Area.banani => l10n.area_banani,
      Area.bashundhara => l10n.area_bashundhara,
      Area.oldDhaka => l10n.area_old_dhaka,
      Area.other => l10n.area_other,
    };
