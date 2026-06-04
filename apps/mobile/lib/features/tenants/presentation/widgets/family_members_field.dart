import 'package:flutter/material.dart';
import 'package:khatir_tokens/khatir_tokens.dart';

import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../screens/ocr_review_args.dart';

/// Reusable add/edit/remove sub-form for household family members
/// (`{name, relation}`), embedded in all three add-tenant paths — OCR review
/// (T-011), voice review (T-012), and the manual form (T-013). Keeping it a
/// single widget means the family capture that feeds the DMP form is identical
/// everywhere (T-015 §2).
///
/// It owns the per-row [TextEditingController]s (so the typed text survives
/// rebuilds) and disposes them when a row is removed or the field unmounts. On
/// every edit/add/remove it reports the current non-empty rows as a list of
/// [FamilyMemberDraft] through [onChanged] — the seam each host folds into its
/// own draft on proceed (T-016).
///
/// [keyPrefix] namespaces the per-row widget keys (e.g. `'ocr'` →
/// `ocrFamilyName`/`ocrFamilyRelation`, `'manual'` → `manualFamilyName`…) so
/// each host screen keeps stable, host-specific keys for its widget tests.
///
/// All colors/spacing/radii/fonts come from the design tokens.
class FamilyMembersField extends StatefulWidget {
  const FamilyMembersField({
    super.key,
    required this.onChanged,
    this.keyPrefix = '',
  });

  /// Called with the current family rows (empty-name rows dropped) whenever the
  /// list changes. The host folds these into its draft on proceed.
  final ValueChanged<List<FamilyMemberDraft>> onChanged;

  /// Prefix applied to the per-row widget keys so each host keeps unique keys.
  final String keyPrefix;

  @override
  State<FamilyMembersField> createState() => _FamilyMembersFieldState();
}

class _FamilyMembersFieldState extends State<FamilyMembersField> {
  final List<_FamilyDraftRow> _rows = [];

  String get _addKey => '${widget.keyPrefix}FamilyAdd';
  String get _nameKey => '${widget.keyPrefix}FamilyName';
  String get _relationKey => '${widget.keyPrefix}FamilyRelation';

  @override
  void dispose() {
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  /// Reports the current non-empty rows to the host. A row whose name is blank
  /// is treated as not-yet-filled and is omitted from the emitted draft.
  void _emit() {
    widget.onChanged([
      for (final row in _rows)
        if (row.nameCtrl.text.trim().isNotEmpty)
          FamilyMemberDraft(
            name: row.nameCtrl.text.trim(),
            relation: row.relationCtrl.text.trim(),
          ),
    ]);
  }

  void _addRow() {
    final row = _FamilyDraftRow();
    // Re-emit as the user types so the host's draft stays current without a
    // proceed round-trip.
    row.nameCtrl.addListener(_emit);
    row.relationCtrl.addListener(_emit);
    setState(() => _rows.add(row));
    _emit();
  }

  void _removeRow(_FamilyDraftRow row) {
    setState(() => _rows.remove(row));
    row.dispose();
    _emit();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final row in _rows) ...[
          _FamilyRow(
            key: ObjectKey(row),
            row: row,
            nameKey: ValueKey(_nameKey),
            relationKey: ValueKey(_relationKey),
            nameLabel: l10n.family_name,
            relationLabel: l10n.family_relation,
            removeTooltip: l10n.family_remove,
            onRemove: () => _removeRow(row),
          ),
          const SizedBox(height: KhatirSpacing.s3),
        ],
        _AddFamilyButton(
          key: ValueKey(_addKey),
          label: l10n.family_add,
          onTap: _addRow,
        ),
      ],
    );
  }
}

/// Mutable controllers backing one family-member row. Held by the field's state
/// so the row's text survives rebuilds; disposed when the row is removed.
class _FamilyDraftRow {
  _FamilyDraftRow()
      : nameCtrl = TextEditingController(),
        relationCtrl = TextEditingController();

  final TextEditingController nameCtrl;
  final TextEditingController relationCtrl;

  void dispose() {
    nameCtrl.dispose();
    relationCtrl.dispose();
  }
}

/// One editable family-member row (name + relation) with a remove action.
class _FamilyRow extends StatelessWidget {
  const _FamilyRow({
    super.key,
    required this.row,
    required this.nameKey,
    required this.relationKey,
    required this.nameLabel,
    required this.relationLabel,
    required this.removeTooltip,
    required this.onRemove,
  });

  final _FamilyDraftRow row;
  final Key nameKey;
  final Key relationKey;
  final String nameLabel;
  final String relationLabel;
  final String removeTooltip;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 3,
          child: TextField(
            key: nameKey,
            controller: row.nameCtrl,
            style: AppTextStyles.bodyMedium,
            decoration: _familyDecoration(nameLabel),
          ),
        ),
        const SizedBox(width: KhatirSpacing.s2),
        Expanded(
          flex: 2,
          child: TextField(
            key: relationKey,
            controller: row.relationCtrl,
            style: AppTextStyles.bodyMedium,
            decoration: _familyDecoration(relationLabel),
          ),
        ),
        IconButton(
          tooltip: removeTooltip,
          onPressed: onRemove,
          icon: const Icon(Icons.remove_circle_outline,
              color: KhatirColors.roseDk),
        ),
      ],
    );
  }

  InputDecoration _familyDecoration(String label) => InputDecoration(
        labelText: label,
        labelStyle: AppTextStyles.bodySmall.copyWith(
          color: KhatirColors.mutedDk,
          fontWeight: FontWeight.w600,
        ),
        isDense: true,
        filled: true,
        fillColor: KhatirColors.card,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: KhatirSpacing.s3,
          vertical: KhatirSpacing.s3,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(KhatirRadius.sm),
          borderSide: const BorderSide(color: KhatirColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(KhatirRadius.sm),
          borderSide: const BorderSide(color: KhatirColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(KhatirRadius.sm),
          borderSide: const BorderSide(color: KhatirColors.sage, width: 2),
        ),
      );
}

/// The "add family member" affordance.
class _AddFamilyButton extends StatelessWidget {
  const _AddFamilyButton({
    super.key,
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: KhatirColors.sageDk,
          side: const BorderSide(color: KhatirColors.sage, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: KhatirSpacing.s3),
          textStyle: AppTextStyles.labelLarge,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(KhatirRadius.button),
          ),
        ),
        child: Text(label),
      ),
    );
  }
}
