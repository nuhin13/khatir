import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khatir_tokens/khatir_tokens.dart';

import '../../../../core/i18n/bangla_numerals.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../leases/presentation/widgets/unit_lease_section.dart';
import '../../../maintenance/presentation/widgets/unit_maint_expense_section.dart';
import '../../../tenants/presentation/screens/add_tenant_screen.dart';
import '../../data/models/property_enums.dart';
import '../../data/models/unit.dart';
import '../../data/properties_providers.dart';

/// A single unit's detail, mirroring the `unit` prototype
/// (`proto/screens-landlord.js` → `reg('unit')`).
///
/// Composition, top to bottom:
/// * **Top bar** — the unit label as title, a back action, and an edit
///   (pencil) action that opens the [_EditUnitSheet].
/// * **Rent hero** — a sage gradient card with the status chip, the monthly
///   rent (big), and the type as a caption. This is the prototype's gradient
///   header, with all values from the live unit.
/// * **Facts grid** — status / type / amenities, each a soft tile. Status and
///   type are tappable to edit inline (a quick PATCH); amenities are edited via
///   the edit sheet.
/// * **Tenant & lease region** — the live lease summary ([UnitLeaseSection],
///   EPIC-06 T-009): an active-lease card (tenant, rent, term, next due) when
///   the unit has a lease, or a create-lease empty state otherwise, framed by
///   the add-tenant CTA → `/tenants/add`.
///
/// States: loading (spinner), error (retry), data. There is no "empty" state —
/// a unit always exists or the request 404s into the error branch. All
/// colors/spacing/radii come from the design tokens; numerals are localised via
/// [BanglaNumerals].
class UnitDetailScreen extends ConsumerWidget {
  const UnitDetailScreen({required this.unitId, super.key});

  /// The unit id from the `/properties/unit/:id` path parameter.
  final String unitId;

  /// Nested route under the portfolio: `/properties/unit/:id`.
  static const String routeName = 'propertiesUnit';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final unitAsync = ref.watch(unitDetailProvider(unitId));

    return Scaffold(
      backgroundColor: KhatirColors.cream,
      appBar: AppBar(
        backgroundColor: KhatirColors.cream,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          unitAsync.maybeWhen(
            data: (unit) => l10n.unit_title(unit.label),
            orElse: () => l10n.portfolio_title,
          ),
          style:
              AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w700),
        ),
        actions: [
          if (unitAsync.hasValue)
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: KhatirColors.ink),
              tooltip: l10n.unit_edit,
              onPressed: () => _openEditSheet(context, ref, unitAsync.value!),
            ),
          const SizedBox(width: KhatirSpacing.s1),
        ],
      ),
      body: SafeArea(
        top: false,
        child: unitAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => _ErrorState(
            l10n: l10n,
            onRetry: () =>
                ref.read(unitDetailProvider(unitId).notifier).refresh(),
          ),
          data: (unit) => _UnitBody(
            unit: unit,
            onEdit: () => _openEditSheet(context, ref, unit),
            onPatchStatus: (status) => ref
                .read(unitDetailProvider(unitId).notifier)
                .save(status: status),
            onPatchType: (type) =>
                ref.read(unitDetailProvider(unitId).notifier).save(type: type),
            onAddTenant: () => _addTenant(context),
          ),
        ),
      ),
    );
  }

  /// Opens the bottom-sheet editor for rent / status / type / amenities and,
  /// on save, PATCHes via the controller (state updates in place).
  Future<void> _openEditSheet(
    BuildContext context,
    WidgetRef ref,
    Unit unit,
  ) async {
    final result = await showModalBottomSheet<_UnitEdit>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditUnitSheet(unit: unit),
    );
    if (result == null) return;
    await ref.read(unitDetailProvider(unitId).notifier).save(
          rent: result.rent,
          status: result.status,
          type: result.type,
          amenities: result.amenities,
        );
  }

  /// Add-tenant CTA → the add-tenant method chooser (EPIC-04 T-009), carrying
  /// this unit's id as the target so the chosen intake flow onboards into it.
  void _addTenant(BuildContext context) {
    GoRouter.of(context).pushNamed(
      AddTenantScreen.routeName,
      queryParameters: {'unit': unitId},
    );
  }
}

/// The populated unit content: rent hero + facts grid + tenant/lease region.
class _UnitBody extends StatelessWidget {
  const _UnitBody({
    required this.unit,
    required this.onEdit,
    required this.onPatchStatus,
    required this.onPatchType,
    required this.onAddTenant,
  });

  final Unit unit;
  final VoidCallback onEdit;
  final ValueChanged<UnitStatus> onPatchStatus;
  final ValueChanged<UnitType> onPatchType;
  final VoidCallback onAddTenant;

  @override
  Widget build(BuildContext context) {
    final localeCode = Localizations.localeOf(context).languageCode;
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        KhatirSpacing.s5,
        KhatirSpacing.s4,
        KhatirSpacing.s5,
        KhatirSpacing.s6,
      ),
      children: [
        _RentHero(unit: unit, localeCode: localeCode),
        const SizedBox(height: KhatirSpacing.s4 - 4),
        _StatusTile(status: unit.status, onSelected: onPatchStatus),
        const SizedBox(height: KhatirSpacing.s3),
        _TypeTile(type: unit.type, onSelected: onPatchType),
        const SizedBox(height: KhatirSpacing.s3),
        _AmenitiesTile(amenities: unit.amenities, onEdit: onEdit),
        const SizedBox(height: KhatirSpacing.s5),
        _TenantSection(unitId: unit.id, onAddTenant: onAddTenant),
        const SizedBox(height: KhatirSpacing.s5),
        UnitMaintExpenseSection(unitId: unit.id),
      ],
    );
  }
}

/// The sage-gradient rent header: status chip, big monthly rent, type caption.
class _RentHero extends StatelessWidget {
  const _RentHero({required this.unit, required this.localeCode});

  final Unit unit;
  final String localeCode;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final rent = unit.rent ?? 0;
    final amount = l10n.unit_rent_per_month(
      BanglaNumerals.format(rent.round(), localeCode),
    );
    final type = unit.type;
    return Container(
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
          _HeroChip(label: statusLabel(l10n, unit.status)),
          const SizedBox(height: KhatirSpacing.s3 - 2),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: amount,
                  style: AppTextStyles.displayLarge.copyWith(
                    color: KhatirColors.card,
                    fontWeight: FontWeight.w800,
                    fontSize: 28,
                  ),
                ),
                TextSpan(
                  text: l10n.unit_per_month_suffix,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: KhatirColors.card.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (type != null) ...[
            const SizedBox(height: KhatirSpacing.s1),
            Text(
              typeLabel(l10n, type),
              style: AppTextStyles.bodySmall.copyWith(
                color: KhatirColors.card.withValues(alpha: 0.9),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Translucent pill on the gradient hero (the prototype's white-on-sage chip).
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

/// Editable status tile — tapping opens a menu of [UnitStatus] values; the
/// selection fires a PATCH.
class _StatusTile extends StatelessWidget {
  const _StatusTile({required this.status, required this.onSelected});

  final UnitStatus? status;
  final ValueChanged<UnitStatus> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _FactTile(
      icon: Icons.meeting_room_outlined,
      label: l10n.unit_status,
      child: PopupMenuButton<UnitStatus>(
        onSelected: onSelected,
        position: PopupMenuPosition.under,
        itemBuilder: (_) => [
          for (final s in UnitStatus.values)
            PopupMenuItem(value: s, child: Text(statusLabel(l10n, s))),
        ],
        child: _ValuePill(label: statusLabel(l10n, status), editable: true),
      ),
    );
  }
}

/// Editable type tile — tapping opens a menu of [UnitType] values.
class _TypeTile extends StatelessWidget {
  const _TypeTile({required this.type, required this.onSelected});

  final UnitType? type;
  final ValueChanged<UnitType> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _FactTile(
      icon: Icons.home_work_outlined,
      label: l10n.unit_type,
      child: PopupMenuButton<UnitType>(
        onSelected: onSelected,
        position: PopupMenuPosition.under,
        itemBuilder: (_) => [
          for (final t in UnitType.values)
            PopupMenuItem(value: t, child: Text(typeLabel(l10n, t))),
        ],
        child: _ValuePill(
          label: type == null ? '—' : typeLabel(l10n, type!),
          editable: true,
        ),
      ),
    );
  }
}

/// Amenities tile — read-only chips here; edited via the full edit sheet (the
/// pencil), since amenities are free-form text.
class _AmenitiesTile extends StatelessWidget {
  const _AmenitiesTile({required this.amenities, required this.onEdit});

  final List<String> amenities;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _FactTile(
      icon: Icons.local_offer_outlined,
      label: l10n.unit_amenities,
      onTap: onEdit,
      child: amenities.isEmpty
          ? Text(
              l10n.unit_amenities_none,
              style:
                  AppTextStyles.bodySmall.copyWith(color: KhatirColors.muted),
            )
          : Wrap(
              spacing: KhatirSpacing.s1 + 1,
              runSpacing: KhatirSpacing.s1 + 1,
              children: [
                for (final a in amenities) _AmenityChip(label: a),
              ],
            ),
    );
  }
}

/// One amenity chip (sage-tinted).
class _AmenityChip extends StatelessWidget {
  const _AmenityChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: KhatirSpacing.s2,
        vertical: KhatirSpacing.s1 - 1,
      ),
      decoration: BoxDecoration(
        color: KhatirColors.sageBg,
        borderRadius: BorderRadius.circular(KhatirRadius.xs - 3),
      ),
      child: Text(
        label,
        style: AppTextStyles.bodySmall.copyWith(
          color: KhatirColors.sageDk,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// A soft card row: icon badge + label on the left, an arbitrary [child] (a
/// value pill, a chip wrap, …) on the right. Optionally tappable.
class _FactTile extends StatelessWidget {
  const _FactTile({
    required this.icon,
    required this.label,
    required this.child,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(KhatirRadius.card);
    final content = Padding(
      padding: const EdgeInsets.all(KhatirSpacing.s4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
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
          const SizedBox(width: KhatirSpacing.s3),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.labelLarge.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: KhatirSpacing.s3),
          Flexible(child: child),
        ],
      ),
    );
    return Material(
      color: KhatirColors.card,
      borderRadius: radius,
      child: onTap == null
          ? content
          : InkWell(onTap: onTap, borderRadius: radius, child: content),
    );
  }
}

/// A right-aligned value pill, with a trailing chevron when [editable].
class _ValuePill extends StatelessWidget {
  const _ValuePill({required this.label, this.editable = false});

  final String label;
  final bool editable;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            label,
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: KhatirColors.ink,
            ),
          ),
        ),
        if (editable) ...[
          const SizedBox(width: 2),
          const Icon(
            Icons.keyboard_arrow_down,
            size: 18,
            color: KhatirColors.muted,
          ),
        ],
      ],
    );
  }
}

/// The tenant/lease region. The heading and the add-tenant CTA frame the live
/// lease summary ([UnitLeaseSection], EPIC-06 T-009) that fills the former
/// placeholder card: an active-lease summary when the unit has one, or a
/// create-lease empty state otherwise. The add-tenant CTA stays so a unit can
/// always onboard a tenant (a lease needs a tenant first).
class _TenantSection extends StatelessWidget {
  const _TenantSection({required this.unitId, required this.onAddTenant});

  final String unitId;
  final VoidCallback onAddTenant;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.unit_tenant_section,
          style: AppTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: KhatirSpacing.s3),
        UnitLeaseSection(unitId: unitId),
        const SizedBox(height: KhatirSpacing.s4),
        _AddTenantButton(label: l10n.unit_add_tenant, onTap: onAddTenant),
      ],
    );
  }
}

/// Soft full-width "Add tenant" button (sage-tinted, leading person icon).
class _AddTenantButton extends StatelessWidget {
  const _AddTenantButton({required this.label, required this.onTap});

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
              const Icon(Icons.person_add_alt_1,
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

/// The bottom-sheet editor for a unit: rent (number field), status + type
/// (segmented choices), and amenities (comma-separated text). Returns a
/// [_UnitEdit] on save, or null on dismiss.
class _EditUnitSheet extends StatefulWidget {
  const _EditUnitSheet({required this.unit});

  final Unit unit;

  @override
  State<_EditUnitSheet> createState() => _EditUnitSheetState();
}

class _EditUnitSheetState extends State<_EditUnitSheet> {
  late final TextEditingController _rent;
  late final TextEditingController _amenities;
  late UnitStatus _status;
  late UnitType _type;

  @override
  void initState() {
    super.initState();
    final u = widget.unit;
    _rent = TextEditingController(
      text: u.rent == null ? '' : u.rent!.round().toString(),
    );
    _amenities = TextEditingController(text: u.amenities.join(', '));
    _status = u.status ?? UnitStatus.vacant;
    _type = u.type ?? UnitType.apartment;
  }

  @override
  void dispose() {
    _rent.dispose();
    _amenities.dispose();
    super.dispose();
  }

  void _save() {
    final amenities = _amenities.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
    Navigator.of(context).pop(
      _UnitEdit(
        rent: double.tryParse(_rent.text.trim()),
        status: _status,
        type: _type,
        amenities: amenities,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: KhatirColors.cream,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(KhatirRadius.xl),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(
          KhatirSpacing.s5,
          KhatirSpacing.s4,
          KhatirSpacing.s5,
          KhatirSpacing.s6,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: KhatirColors.lineDk,
                  borderRadius: BorderRadius.circular(KhatirRadius.pill),
                ),
              ),
            ),
            const SizedBox(height: KhatirSpacing.s4),
            Text(
              l10n.unit_edit,
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: KhatirSpacing.s4),
            Text(
              l10n.unit_edit_rent_label,
              style: AppTextStyles.bodySmall.copyWith(color: KhatirColors.mutedDk),
            ),
            const SizedBox(height: KhatirSpacing.s1 + 2),
            TextField(
              controller: _rent,
              keyboardType: TextInputType.number,
              style: AppTextStyles.bodyLarge,
              decoration: _fieldDecoration(),
            ),
            const SizedBox(height: KhatirSpacing.s4),
            Text(
              l10n.unit_status,
              style: AppTextStyles.bodySmall.copyWith(color: KhatirColors.mutedDk),
            ),
            const SizedBox(height: KhatirSpacing.s1 + 2),
            _ChoiceRow<UnitStatus>(
              values: UnitStatus.values,
              selected: _status,
              labelOf: (s) => statusLabel(l10n, s),
              onSelected: (s) => setState(() => _status = s),
            ),
            const SizedBox(height: KhatirSpacing.s4),
            Text(
              l10n.unit_type,
              style: AppTextStyles.bodySmall.copyWith(color: KhatirColors.mutedDk),
            ),
            const SizedBox(height: KhatirSpacing.s1 + 2),
            _ChoiceRow<UnitType>(
              values: UnitType.values,
              selected: _type,
              labelOf: (t) => typeLabel(l10n, t),
              onSelected: (t) => setState(() => _type = t),
            ),
            const SizedBox(height: KhatirSpacing.s4),
            Text(
              l10n.unit_amenities,
              style: AppTextStyles.bodySmall.copyWith(color: KhatirColors.mutedDk),
            ),
            const SizedBox(height: KhatirSpacing.s1 + 2),
            TextField(
              controller: _amenities,
              style: AppTextStyles.bodyMedium,
              decoration: _fieldDecoration(),
            ),
            const SizedBox(height: KhatirSpacing.s5),
            SizedBox(
              width: double.infinity,
              child: Material(
                color: KhatirColors.sage,
                borderRadius: BorderRadius.circular(KhatirRadius.button),
                child: InkWell(
                  onTap: _save,
                  borderRadius: BorderRadius.circular(KhatirRadius.button),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: KhatirSpacing.s4),
                    child: Center(
                      child: Text(
                        l10n.unit_save,
                        style: AppTextStyles.labelLarge.copyWith(
                          color: KhatirColors.card,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
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

  InputDecoration _fieldDecoration() {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(KhatirRadius.md),
      borderSide: const BorderSide(color: KhatirColors.line),
    );
    return InputDecoration(
      filled: true,
      fillColor: KhatirColors.card,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: KhatirSpacing.s4,
        vertical: KhatirSpacing.s3,
      ),
      border: border,
      enabledBorder: border,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(KhatirRadius.md),
        borderSide: const BorderSide(color: KhatirColors.sage, width: 1.5),
      ),
    );
  }
}

/// A wrap of selectable choice chips for an enum, single-select.
class _ChoiceRow<T> extends StatelessWidget {
  const _ChoiceRow({
    required this.values,
    required this.selected,
    required this.labelOf,
    required this.onSelected,
  });

  final List<T> values;
  final T selected;
  final String Function(T) labelOf;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: KhatirSpacing.s2,
      runSpacing: KhatirSpacing.s2,
      children: [
        for (final v in values)
          _ChoiceChip(
            label: labelOf(v),
            selected: v == selected,
            onTap: () => onSelected(v),
          ),
      ],
    );
  }
}

/// One selectable choice chip (sage when selected, card otherwise).
class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(KhatirRadius.chip);
    return Material(
      color: selected ? KhatirColors.sage : KhatirColors.card,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: KhatirSpacing.s3,
            vertical: KhatirSpacing.s2,
          ),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(
              color: selected ? KhatirColors.sage : KhatirColors.line,
            ),
          ),
          child: Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: selected ? KhatirColors.card : KhatirColors.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

/// The result of the edit sheet — the fields to PATCH.
class _UnitEdit {
  const _UnitEdit({
    required this.rent,
    required this.status,
    required this.type,
    required this.amenities,
  });

  final double? rent;
  final UnitStatus status;
  final UnitType type;
  final List<String> amenities;
}

/// Error state: a friendly message and a retry button (reloads `/units/{id}`).
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

/// Localized display label for a [UnitStatus]. Null → vacant copy as a safe
/// default so the chip is never blank.
String statusLabel(AppLocalizations l10n, UnitStatus? status) =>
    switch (status) {
      UnitStatus.occupied => l10n.unit_status_occupied,
      UnitStatus.vacant => l10n.unit_status_vacant,
      UnitStatus.maintenance => l10n.unit_status_maintenance,
      null => l10n.unit_status_vacant,
    };

/// Localized display label for a [UnitType].
String typeLabel(AppLocalizations l10n, UnitType type) => switch (type) {
      UnitType.apartment => l10n.unit_type_apartment,
      UnitType.room => l10n.unit_type_room,
      UnitType.commercial => l10n.unit_type_commercial,
      UnitType.garage => l10n.unit_type_garage,
      UnitType.other => l10n.unit_type_other,
    };
