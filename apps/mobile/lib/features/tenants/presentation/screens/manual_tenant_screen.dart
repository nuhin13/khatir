import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khatir_tokens/khatir_tokens.dart';

import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../controllers/tenant_save_controller.dart';
import '../widgets/family_members_field.dart';
import 'ocr_review_args.dart';

/// Manual tenant-entry form, mirroring the `manualTenant` prototype
/// (`proto/screens-landlord2.js` → `reg('manualTenant')`).
///
/// This is the fallback path when OCR (T-010/T-011) and voice (T-012) aren't
/// used: the landlord types every DMP-required field by hand. It is the *same*
/// form as the OCR review screen — the editable field widgets, the family
/// sub-form, the validation, and the proceed seam are shared in spirit — only
/// here nothing is prefilled and there is no `photo_ref` (T-013 §15).
///
/// The form follows the prototype's DMP grouping: landlord, tenant, current
/// unit, and family & staff. Tenant full name + NID are required (the ★ fields
/// in the prototype). Proceeding validates, then emits a [ManualTenantDraft] of
/// the entered values to [onProceed] — the seam the shared save action (T-016)
/// wires; until then it is a no-op default.
///
/// All colors/spacing/radii/fonts come from the design tokens.
class ManualTenantScreen extends HookConsumerWidget {
  const ManualTenantScreen({super.key, this.unitId, this.onProceed});

  /// Optional target unit id threaded from the add-tenant chooser (T-009),
  /// carried through to the downstream save so it knows the unit context.
  final String? unitId;

  /// Test seam: invoked with the entered [ManualTenantDraft] when proceed is
  /// tapped and validation passes. When `null` (the default, and what the router
  /// supplies) the screen runs the shared save+route action (T-016) instead —
  /// persisting the tenant and routing to the DMP form. Widget tests pass a
  /// callback to assert the entered values flow through without hitting the
  /// network.
  final void Function(ManualTenantDraft draft)? onProceed;

  /// Sub-route under `/tenants/add`.
  static const String routePath = 'manual';
  static const String routeName = 'tenantsAddManual';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    // Landlord block.
    final landlordNameCtrl = useTextEditingController();
    final landlordNidCtrl = useTextEditingController();
    final landlordMobileCtrl = useTextEditingController();
    // Tenant block.
    final nameCtrl = useTextEditingController();
    final nidCtrl = useTextEditingController();
    final dobCtrl = useTextEditingController();
    final occupationCtrl = useTextEditingController();
    final mobileCtrl = useTextEditingController();
    final addressCtrl = useTextEditingController();
    // Current-unit block.
    final buildingCtrl = useTextEditingController();
    final unitCtrl = useTextEditingController();
    final rentCtrl = useTextEditingController();
    final moveInCtrl = useTextEditingController();

    final formKey = useMemoized(GlobalKey<FormState>.new);
    final family = useState<List<FamilyMemberDraft>>(const []);
    final saving = useState<bool>(false);

    Future<void> proceed() async {
      if (saving.value) return;
      if (!(formKey.currentState?.validate() ?? false)) return;
      final draft = ManualTenantDraft(
        landlordName: landlordNameCtrl.text.trim(),
        landlordNid: landlordNidCtrl.text.trim(),
        landlordMobile: landlordMobileCtrl.text.trim(),
        name: nameCtrl.text.trim(),
        nidNumber: nidCtrl.text.trim(),
        dob: dobCtrl.text.trim(),
        occupation: occupationCtrl.text.trim(),
        mobile: mobileCtrl.text.trim(),
        address: addressCtrl.text.trim(),
        building: buildingCtrl.text.trim(),
        unit: unitCtrl.text.trim(),
        rent: rentCtrl.text.trim(),
        moveIn: moveInCtrl.text.trim(),
        family: family.value,
        unitId: unitId,
      );
      // Test seam: a supplied callback short-circuits the network save so widget
      // tests can assert the entered values. The router leaves it null → run the
      // shared save+route action (T-016).
      final onProceed = this.onProceed;
      if (onProceed != null) {
        onProceed(draft);
        return;
      }
      saving.value = true;
      final ok = await TenantSaveController(ref).saveAndContinue(
        context,
        TenantSaveDraft(
          name: draft.name,
          nidNumber: draft.nidNumber,
          dob: draft.dob,
          address: draft.address,
          family: draft.family,
          unitId: draft.unitId,
        ),
      );
      if (context.mounted && !ok) saving.value = false;
    }

    return Scaffold(
      backgroundColor: KhatirColors.cream,
      appBar: AppBar(
        backgroundColor: KhatirColors.cream,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          l10n.manual_title,
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
              _IntroBanner(text: l10n.manual_intro),
              const SizedBox(height: KhatirSpacing.s4),

              // ── 1 · Landlord ───────────────────────────────────────────
              _SectionLabel(text: l10n.manual_section_landlord),
              const SizedBox(height: KhatirSpacing.s3),
              _FormField(
                key: const ValueKey('manualLandlordName'),
                controller: landlordNameCtrl,
                label: l10n.tenant_name,
                icon: Icons.person_outline,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: KhatirSpacing.s3),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _FormField(
                      key: const ValueKey('manualLandlordNid'),
                      controller: landlordNidCtrl,
                      label: l10n.tenant_nid,
                      icon: Icons.badge_outlined,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  const SizedBox(width: KhatirSpacing.s3),
                  Expanded(
                    child: _FormField(
                      key: const ValueKey('manualLandlordMobile'),
                      controller: landlordMobileCtrl,
                      label: l10n.tenant_mobile,
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: KhatirSpacing.s5),

              // ── 2 · Tenant ─────────────────────────────────────────────
              _SectionLabel(text: l10n.manual_section_tenant),
              const SizedBox(height: KhatirSpacing.s3),
              _FormField(
                key: const ValueKey('manualName'),
                controller: nameCtrl,
                label: l10n.manual_full_name,
                icon: Icons.person_outline,
                required: true,
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? l10n.ocr_err_name : null,
              ),
              const SizedBox(height: KhatirSpacing.s3),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _FormField(
                      key: const ValueKey('manualNid'),
                      controller: nidCtrl,
                      label: l10n.tenant_nid,
                      icon: Icons.badge_outlined,
                      keyboardType: TextInputType.number,
                      required: true,
                      textInputAction: TextInputAction.next,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? l10n.ocr_err_nid
                          : null,
                    ),
                  ),
                  const SizedBox(width: KhatirSpacing.s3),
                  Expanded(
                    child: _FormField(
                      key: const ValueKey('manualDob'),
                      controller: dobCtrl,
                      label: l10n.tenant_dob,
                      icon: Icons.cake_outlined,
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: KhatirSpacing.s3),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _FormField(
                      key: const ValueKey('manualOccupation'),
                      controller: occupationCtrl,
                      label: l10n.manual_occupation,
                      icon: Icons.work_outline,
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  const SizedBox(width: KhatirSpacing.s3),
                  Expanded(
                    child: _FormField(
                      key: const ValueKey('manualMobile'),
                      controller: mobileCtrl,
                      label: l10n.tenant_mobile,
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: KhatirSpacing.s3),
              _FormField(
                key: const ValueKey('manualAddress'),
                controller: addressCtrl,
                label: l10n.manual_permanent_address,
                icon: Icons.home_outlined,
                maxLines: 2,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: KhatirSpacing.s5),

              // ── 3 · Current unit ───────────────────────────────────────
              _SectionLabel(text: l10n.manual_section_unit),
              const SizedBox(height: KhatirSpacing.s3),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _FormField(
                      key: const ValueKey('manualBuilding'),
                      controller: buildingCtrl,
                      label: l10n.manual_building,
                      icon: Icons.apartment_outlined,
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  const SizedBox(width: KhatirSpacing.s3),
                  Expanded(
                    child: _FormField(
                      key: const ValueKey('manualUnit'),
                      controller: unitCtrl,
                      label: l10n.manual_unit,
                      icon: Icons.meeting_room_outlined,
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: KhatirSpacing.s3),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _FormField(
                      key: const ValueKey('manualRent'),
                      controller: rentCtrl,
                      label: l10n.manual_rent,
                      icon: Icons.payments_outlined,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  const SizedBox(width: KhatirSpacing.s3),
                  Expanded(
                    child: _FormField(
                      key: const ValueKey('manualMoveIn'),
                      controller: moveInCtrl,
                      label: l10n.manual_move_in,
                      icon: Icons.event_outlined,
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: KhatirSpacing.s5),

              // ── 4 · Family & staff ─────────────────────────────────────
              _SectionLabel(text: l10n.manual_section_family),
              const SizedBox(height: KhatirSpacing.s3),
              FamilyMembersField(
                keyPrefix: 'manual',
                onChanged: (members) => family.value = members,
              ),
              const SizedBox(height: KhatirSpacing.s6),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  key: const ValueKey('manualProceed'),
                  onPressed: saving.value ? null : proceed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: KhatirColors.sage,
                    foregroundColor: KhatirColors.cream,
                    disabledBackgroundColor: KhatirColors.sage,
                    disabledForegroundColor: KhatirColors.cream,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      vertical: KhatirSpacing.s4,
                    ),
                    textStyle: AppTextStyles.labelLarge,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(KhatirRadius.button),
                    ),
                  ),
                  child: saving.value
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: KhatirColors.cream,
                          ),
                        )
                      : Text(l10n.manual_proceed),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The butter "fill every official field by hand" intro card from the
/// `manualTenant` prototype.
class _IntroBanner extends StatelessWidget {
  const _IntroBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(KhatirSpacing.s4),
      decoration: BoxDecoration(
        color: KhatirColors.butterBg,
        borderRadius: BorderRadius.circular(KhatirRadius.card),
      ),
      child: Row(
        children: [
          const Text('✍️', style: TextStyle(fontSize: 22)),
          const SizedBox(width: KhatirSpacing.s3),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodySmall.copyWith(
                color: KhatirColors.mutedDk,
                fontWeight: FontWeight.w600,
                height: 1.5,
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

/// A single editable manual-entry field. Same composition as the OCR review
/// field (T-011) minus the OCR-only low-confidence flag; required fields show
/// the focus border in sage on focus and are validated on proceed.
class _FormField extends StatelessWidget {
  const _FormField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.maxLines = 1,
    this.required = false,
    this.textInputAction,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final int maxLines;
  final bool required;
  final TextInputAction? textInputAction;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      textInputAction: textInputAction,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      style: AppTextStyles.bodyMedium,
      decoration: InputDecoration(
        labelText: required ? '$label ★' : label,
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
          borderSide: const BorderSide(color: KhatirColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(KhatirRadius.md),
          borderSide: const BorderSide(color: KhatirColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(KhatirRadius.md),
          borderSide: const BorderSide(color: KhatirColors.sage, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(KhatirRadius.md),
          borderSide: const BorderSide(color: KhatirColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(KhatirRadius.md),
          borderSide: const BorderSide(color: KhatirColors.danger, width: 2),
        ),
      ),
    );
  }
}

/// The hand-entered tenant fields emitted when the manual form's proceed button
/// is tapped. Superset of [TenantReviewDraft]: the manual `manualTenant` form
/// collects the full DMP set (landlord + tenant + current unit + family), none
/// of which is prefilled and with no `photo_ref`. This is the seam the shared
/// save action (T-016) consumes on its way to the DMP form.
class ManualTenantDraft {
  const ManualTenantDraft({
    required this.landlordName,
    required this.landlordNid,
    required this.landlordMobile,
    required this.name,
    required this.nidNumber,
    required this.dob,
    required this.occupation,
    required this.mobile,
    required this.address,
    required this.building,
    required this.unit,
    required this.rent,
    required this.moveIn,
    required this.family,
    this.unitId,
  });

  final String landlordName;
  final String landlordNid;
  final String landlordMobile;
  final String name;
  final String nidNumber;
  final String dob;
  final String occupation;
  final String mobile;
  final String address;
  final String building;
  final String unit;
  final String rent;
  final String moveIn;
  final List<FamilyMemberDraft> family;
  final String? unitId;
}
