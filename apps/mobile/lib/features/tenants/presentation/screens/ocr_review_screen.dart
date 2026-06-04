import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khatir_tokens/khatir_tokens.dart';

import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/extracted_tenant.dart';
import 'ocr_review_args.dart';

/// OCR review/edit stage, mirroring the `ocr` prototype review state
/// (`proto/screens-landlord2.js` → `reg('ocr')`, `ocrScanned` branch).
///
/// The landlord lands here from the capture screen (T-010) with the
/// already-extracted [OcrReviewArgs.extracted] fields + `photo_ref`. OCR is
/// never trusted blindly (T-011 §2): every field is shown in an editable text
/// field prefilled from the extraction, fields the provider returned with low
/// confidence are flagged for attention, and a family sub-form lets the user
/// add/remove members. Name + NID are required. Proceeding emits a
/// [TenantReviewDraft] of the *edited* values to [onProceed] — the seam the
/// shared save action (T-016) wires; until then it is a no-op default.
///
/// All colors/spacing/radii/fonts come from the design tokens.
class OcrReviewScreen extends HookConsumerWidget {
  const OcrReviewScreen({super.key, required this.args, this.onProceed});

  /// The extracted fields + `photo_ref` + optional unit id from capture.
  final OcrReviewArgs args;

  /// Invoked with the landlord-confirmed [TenantReviewDraft] when the proceed
  /// button is tapped and validation passes. Defaults to `null`; the shared
  /// save+route action (T-016) supplies the real implementation. Exposed as a
  /// parameter so widget tests can assert the edited values flow through.
  final void Function(TenantReviewDraft draft)? onProceed;

  static const String routeName = OcrReviewArgs.routeName;
  static const String routePath = OcrReviewArgs.routePath;

  /// Confidence at or below which a value is flagged for extra attention. The
  /// provider may omit confidence entirely (then we treat the field as a normal
  /// editable field, T-011 §15).
  static const double _lowConfidence = 0.85;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final ExtractedTenant extracted = args.extracted;

    final nameCtrl = useTextEditingController(text: extracted.name.value ?? '');
    final nidCtrl =
        useTextEditingController(text: extracted.nidNumber.value ?? '');
    final dobCtrl = useTextEditingController(text: extracted.dob.value ?? '');
    final addressCtrl =
        useTextEditingController(text: extracted.address.value ?? '');

    final formKey = useMemoized(GlobalKey<FormState>.new);
    final family = useState<List<_FamilyDraftRow>>(const []);

    void addFamily() {
      family.value = [...family.value, _FamilyDraftRow()];
    }

    void removeFamily(_FamilyDraftRow row) {
      row.dispose();
      family.value = family.value.where((r) => r != row).toList();
    }

    void proceed() {
      if (!(formKey.currentState?.validate() ?? false)) return;
      final draft = TenantReviewDraft(
        name: nameCtrl.text.trim(),
        nidNumber: nidCtrl.text.trim(),
        dob: dobCtrl.text.trim(),
        address: addressCtrl.text.trim(),
        family: [
          for (final row in family.value)
            if (row.nameCtrl.text.trim().isNotEmpty)
              FamilyMemberDraft(
                name: row.nameCtrl.text.trim(),
                relation: row.relationCtrl.text.trim(),
              ),
        ],
        photoRef: extracted.photoRef,
        unitId: args.unitId,
      );
      onProceed?.call(draft);
    }

    bool isLow(ExtractedField f) =>
        f.confidence != null && f.confidence! <= _lowConfidence;

    return Scaffold(
      backgroundColor: KhatirColors.cream,
      appBar: AppBar(
        backgroundColor: KhatirColors.cream,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          l10n.ocr_review_title,
          style:
              AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Form(
          key: formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              KhatirSpacing.s5,
              KhatirSpacing.s4,
              KhatirSpacing.s5,
              KhatirSpacing.s6,
            ),
            children: [
              _ExtractedBanner(text: l10n.ocr_review_banner),
              const SizedBox(height: KhatirSpacing.s4),
              _ReviewField(
                key: const ValueKey('ocrFieldName'),
                controller: nameCtrl,
                label: l10n.tenant_name,
                icon: Icons.person_outline,
                lowConfidence: isLow(extracted.name),
                lowConfidenceHint: l10n.ocr_low_confidence,
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? l10n.ocr_err_name : null,
              ),
              const SizedBox(height: KhatirSpacing.s3),
              _ReviewField(
                key: const ValueKey('ocrFieldNid'),
                controller: nidCtrl,
                label: l10n.tenant_nid,
                icon: Icons.badge_outlined,
                keyboardType: TextInputType.number,
                lowConfidence: isLow(extracted.nidNumber),
                lowConfidenceHint: l10n.ocr_low_confidence,
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? l10n.ocr_err_nid : null,
              ),
              const SizedBox(height: KhatirSpacing.s3),
              _ReviewField(
                key: const ValueKey('ocrFieldDob'),
                controller: dobCtrl,
                label: l10n.tenant_dob,
                icon: Icons.cake_outlined,
                lowConfidence: isLow(extracted.dob),
                lowConfidenceHint: l10n.ocr_low_confidence,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: KhatirSpacing.s3),
              _ReviewField(
                key: const ValueKey('ocrFieldAddress'),
                controller: addressCtrl,
                label: l10n.tenant_address,
                icon: Icons.home_outlined,
                maxLines: 2,
                lowConfidence: isLow(extracted.address),
                lowConfidenceHint: l10n.ocr_low_confidence,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: KhatirSpacing.s5),
              _SectionLabel(text: l10n.ocr_family_section),
              const SizedBox(height: KhatirSpacing.s3),
              for (final row in family.value) ...[
                _FamilyRow(
                  key: ObjectKey(row),
                  row: row,
                  nameLabel: l10n.ocr_family_name,
                  relationLabel: l10n.ocr_family_relation,
                  removeTooltip: l10n.ocr_family_remove,
                  onRemove: () => removeFamily(row),
                ),
                const SizedBox(height: KhatirSpacing.s3),
              ],
              _AddFamilyButton(
                key: const ValueKey('ocrFamilyAdd'),
                label: l10n.ocr_family_add,
                onTap: addFamily,
              ),
              const SizedBox(height: KhatirSpacing.s6),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  key: const ValueKey('ocrProceed'),
                  onPressed: proceed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: KhatirColors.sage,
                    foregroundColor: KhatirColors.cream,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      vertical: KhatirSpacing.s4,
                    ),
                    textStyle: AppTextStyles.labelLarge,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(KhatirRadius.button),
                    ),
                  ),
                  child: Text(l10n.ocr_confirm),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mutable controllers backing one family-member row. Held in state so the
/// row's text survives rebuilds; disposed when the row is removed.
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

/// The sage "AI extracted, please confirm" reassurance banner.
class _ExtractedBanner extends StatelessWidget {
  const _ExtractedBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(KhatirSpacing.s4),
      decoration: BoxDecoration(
        color: KhatirColors.sageBg,
        borderRadius: BorderRadius.circular(KhatirRadius.card),
      ),
      child: Row(
        children: [
          const Text('✨', style: TextStyle(fontSize: 22)),
          const SizedBox(width: KhatirSpacing.s3),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodySmall.copyWith(
                color: KhatirColors.sageDk,
                fontWeight: FontWeight.w700,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A small uppercase section heading (matches the prototype `dmpSec` style).
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

/// A single editable review field — prefilled from OCR, with an optional
/// low-confidence flag the prototype's "please confirm" intent maps onto.
class _ReviewField extends StatelessWidget {
  const _ReviewField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    required this.lowConfidence,
    required this.lowConfidenceHint,
    this.keyboardType,
    this.maxLines = 1,
    this.textInputAction,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool lowConfidence;
  final String lowConfidenceHint;
  final TextInputType? keyboardType;
  final int maxLines;
  final TextInputAction? textInputAction;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    final Color borderColor =
        lowConfidence ? KhatirColors.butterDk : KhatirColors.line;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          textInputAction: textInputAction,
          validator: validator,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          style: AppTextStyles.bodyMedium,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: AppTextStyles.bodySmall.copyWith(
              color: KhatirColors.mutedDk,
              fontWeight: FontWeight.w600,
            ),
            prefixIcon: Icon(icon, size: 20, color: KhatirColors.sageDk),
            filled: true,
            fillColor: KhatirColors.card,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: KhatirSpacing.s4,
              vertical: KhatirSpacing.s3,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(KhatirRadius.md),
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(KhatirRadius.md),
              borderSide: BorderSide(
                color: borderColor,
                width: lowConfidence ? 1.5 : 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(KhatirRadius.md),
              borderSide: const BorderSide(color: KhatirColors.sage, width: 2),
            ),
          ),
        ),
        if (lowConfidence) ...[
          const SizedBox(height: KhatirSpacing.s1),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline,
                  size: 14, color: KhatirColors.roseDk),
              const SizedBox(width: KhatirSpacing.s1),
              Expanded(
                child: Text(
                  lowConfidenceHint,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontSize: 11,
                    color: KhatirColors.roseDk,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// One editable family-member row (name + relation) with a remove action.
class _FamilyRow extends StatelessWidget {
  const _FamilyRow({
    super.key,
    required this.row,
    required this.nameLabel,
    required this.relationLabel,
    required this.removeTooltip,
    required this.onRemove,
  });

  final _FamilyDraftRow row;
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
            key: const ValueKey('ocrFamilyName'),
            controller: row.nameCtrl,
            style: AppTextStyles.bodyMedium,
            decoration: _familyDecoration(nameLabel),
          ),
        ),
        const SizedBox(width: KhatirSpacing.s2),
        Expanded(
          flex: 2,
          child: TextField(
            key: const ValueKey('ocrFamilyRelation'),
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

/// The dashed "add family member" affordance.
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
