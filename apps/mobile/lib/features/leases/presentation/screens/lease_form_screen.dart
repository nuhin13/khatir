import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khatir_tokens/khatir_tokens.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../properties/data/properties_providers.dart';
import '../../../tenants/data/models/tenant.dart';
import '../../../tenants/data/tenants_providers.dart';
import '../../data/models/models.dart';
import '../../data/providers.dart';

/// The values a completed lease form emits — the test seam that lets widget
/// tests assert the entered terms without hitting the network. Mirrors the
/// fields the lease create endpoint consumes (T-003/T-007). [activate] records
/// which button was tapped (Save draft vs. Save & activate).
class LeaseFormDraft {
  const LeaseFormDraft({
    required this.unitId,
    required this.tenantId,
    required this.startDate,
    required this.endDate,
    required this.rent,
    required this.advance,
    required this.dueDay,
    required this.activate,
  });

  final String unitId;
  final String tenantId;
  final DateTime startDate;
  final DateTime endDate;
  final double rent;
  final double? advance;
  final int dueDay;
  final bool activate;
}

/// Lease create/edit form (EPIC-06 T-008), launched from the unit-detail screen
/// in unit context. No prototype screen of its own (the design map marks the
/// lease-create screens "derived") — it follows the shared Khatir form
/// composition (the manual-tenant form, EPIC-04 T-013): a cream scaffold, sage
/// section labels, white card fields, and a pill primary button. Every
/// color/spacing/radius comes from the design tokens.
///
/// The landlord is server-derived from the unit owner and is never collected
/// here. The tenant picker is seeded from the unit's tenants ([unitTenantsProvider]);
/// rent defaults from the unit ([unitProvider]); the due day defaults from
/// config ([kDefaultDueDay], SystemConfig `default_due_day` = 5, T-006) and
/// drives the server-side schedule generation (it is not a lease field, so it
/// is collected for clarity but not sent).
///
/// Saving creates a **draft** lease ([LeaseRepository.createLease]); the
/// "Save & activate" action additionally activates it ([LeaseController.activate]),
/// which makes the server generate the rent schedule. When the unit already has
/// an active lease the backend rejects activation; that 400/409 is surfaced as a
/// friendly snackbar (T-008 §15) rather than the raw error.
class LeaseFormScreen extends HookConsumerWidget {
  const LeaseFormScreen({
    super.key,
    required this.unitId,
    this.leaseId,
    this.onProceed,
  });

  /// The unit this lease belongs to — always supplied (the form is launched in
  /// unit context). Threaded into the create call as `unit_id`.
  final String unitId;

  /// When set the form is in edit mode (`/lease/:id/edit`); the draft's terms
  /// are loaded and saved via PATCH. When null it is a create form.
  final String? leaseId;

  /// Test seam: invoked with the entered [LeaseFormDraft] when a save button is
  /// tapped and validation passes. When null (the default, and what the router
  /// supplies) the screen runs the real create(+activate) flow and pops back to
  /// the unit on success.
  final void Function(LeaseFormDraft draft)? onProceed;

  static const String routePath = '/lease/new';
  static const String routeName = 'leaseNew';
  static const String editRoutePath = '/lease/:id/edit';
  static const String editRouteName = 'leaseEdit';

  /// SystemConfig `default_due_day` (T-006) — the day of month rent falls due.
  /// Mirrored client-side as a sensible default for the form's due-day picker.
  static const int kDefaultDueDay = 5;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isEdit = leaseId != null;

    // Tenant picker is seeded from this unit's tenants.
    final tenantsAsync = ref.watch(unitTenantsProvider(unitId));
    // Rent default comes from the unit; ignore the loading/error tail.
    final unitAsync = ref.watch(unitProvider(unitId));

    final selectedTenant = useState<String?>(null);
    final rentCtrl = useTextEditingController();
    final advanceCtrl = useTextEditingController();
    final startDate = useState<DateTime?>(null);
    final endDate = useState<DateTime?>(null);
    final dueDay = useState<int>(kDefaultDueDay);
    final saving = useState<bool>(false);

    final formKey = useMemoized(GlobalKey<FormState>.new);

    // Prefill the rent from the unit once it resolves (only if untouched).
    final unitRent = unitAsync.valueOrNull?.rent;
    useEffect(
      () {
        if (unitRent != null && unitRent > 0 && rentCtrl.text.trim().isEmpty) {
          rentCtrl.text = _money(unitRent);
        }
        return null;
      },
      [unitRent],
    );

    String fmt(DateTime? d) => d == null
        ? ''
        : '${d.year.toString().padLeft(4, '0')}-'
            '${d.month.toString().padLeft(2, '0')}-'
            '${d.day.toString().padLeft(2, '0')}';

    Future<void> pickDate(ValueNotifier<DateTime?> target) async {
      final now = DateTime.now();
      final initial = target.value ?? now;
      final picked = await showDatePicker(
        context: context,
        initialDate: initial,
        firstDate: DateTime(now.year - 5),
        lastDate: DateTime(now.year + 10),
      );
      if (picked != null) target.value = picked;
    }

    void showSnack(String text) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(text)));
    }

    Future<void> save({required bool activate}) async {
      if (saving.value) return;
      if (!(formKey.currentState?.validate() ?? false)) return;

      final tenantId = selectedTenant.value;
      if (tenantId == null || tenantId.isEmpty) {
        showSnack(l10n.lease_err_tenant);
        return;
      }
      final start = startDate.value;
      final end = endDate.value;
      if (start == null || end == null || !end.isAfter(start)) {
        showSnack(l10n.lease_err_dates);
        return;
      }
      final rent = double.tryParse(rentCtrl.text.trim());
      if (rent == null || rent <= 0) {
        showSnack(l10n.lease_err_rent);
        return;
      }
      final advanceText = advanceCtrl.text.trim();
      final advance = advanceText.isEmpty ? null : double.tryParse(advanceText);

      final draft = LeaseFormDraft(
        unitId: unitId,
        tenantId: tenantId,
        startDate: start,
        endDate: end,
        rent: rent,
        advance: advance,
        dueDay: dueDay.value,
        activate: activate,
      );

      // Test seam: a supplied callback short-circuits the network save so widget
      // tests assert the entered terms. The router leaves it null → real flow.
      final onProceed = this.onProceed;
      if (onProceed != null) {
        onProceed(draft);
        return;
      }

      saving.value = true;
      try {
        final repo = ref.read(leaseRepositoryProvider);
        final Lease created;
        if (isEdit) {
          created = await repo.updateLease(
            leaseId!,
            startDate: start,
            endDate: end,
            rent: rent,
            advance: advance,
          );
        } else {
          created = await repo.createLease(
            unitId: unitId,
            tenantId: tenantId,
            startDate: start,
            endDate: end,
            rent: rent,
            advance: advance,
          );
        }
        if (activate) {
          await ref.read(leaseControllerProvider(created.id).notifier).activate();
        }
        if (!context.mounted) return;
        showSnack(activate ? l10n.lease_activated : l10n.lease_saved);
        Navigator.of(context).pop(created);
      } on ApiException catch (e) {
        if (!context.mounted) return;
        saving.value = false;
        // The unit-already-has-an-active-lease guard is a 400/409 from the
        // backend; surface it as the friendly message (T-008 §15).
        final isActiveClash =
            e.statusCode == 409 || e.statusCode == 400;
        showSnack(isActiveClash ? l10n.lease_active_exists : l10n.lease_save_error);
      } catch (_) {
        if (!context.mounted) return;
        saving.value = false;
        showSnack(l10n.lease_save_error);
      }
    }

    final tenants = tenantsAsync.valueOrNull ?? const <Tenant>[];

    return Scaffold(
      backgroundColor: KhatirColors.cream,
      appBar: AppBar(
        backgroundColor: KhatirColors.cream,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          isEdit ? l10n.lease_edit_title : l10n.lease_new_title,
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
              // ── Tenant ─────────────────────────────────────────────────
              _SectionLabel(text: l10n.lease_section_tenant),
              const SizedBox(height: KhatirSpacing.s3),
              if (tenants.isEmpty)
                _Helper(text: l10n.lease_tenant_empty)
              else
                _TenantPicker(
                  key: const ValueKey('leaseTenant'),
                  label: l10n.lease_tenant,
                  hint: l10n.lease_tenant_hint,
                  tenants: tenants,
                  value: selectedTenant.value,
                  onChanged: (id) => selectedTenant.value = id,
                ),
              const SizedBox(height: KhatirSpacing.s5),

              // ── Terms ──────────────────────────────────────────────────
              _SectionLabel(text: l10n.lease_section_terms),
              const SizedBox(height: KhatirSpacing.s3),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _FormField(
                      key: const ValueKey('leaseRent'),
                      controller: rentCtrl,
                      label: l10n.lease_rent,
                      icon: Icons.payments_outlined,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[0-9.]'),
                        ),
                      ],
                      required: true,
                      validator: (v) {
                        final n = double.tryParse((v ?? '').trim());
                        return (n == null || n <= 0) ? l10n.lease_err_rent : null;
                      },
                    ),
                  ),
                  const SizedBox(width: KhatirSpacing.s3),
                  Expanded(
                    child: _FormField(
                      key: const ValueKey('leaseAdvance'),
                      controller: advanceCtrl,
                      label: l10n.lease_advance,
                      icon: Icons.savings_outlined,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[0-9.]'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: KhatirSpacing.s3),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _DateField(
                      key: const ValueKey('leaseStart'),
                      label: l10n.lease_start,
                      value: fmt(startDate.value),
                      onTap: () => pickDate(startDate),
                    ),
                  ),
                  const SizedBox(width: KhatirSpacing.s3),
                  Expanded(
                    child: _DateField(
                      key: const ValueKey('leaseEnd'),
                      label: l10n.lease_end,
                      value: fmt(endDate.value),
                      onTap: () => pickDate(endDate),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: KhatirSpacing.s3),
              _DueDayField(
                key: const ValueKey('leaseDueDay'),
                label: l10n.lease_due_day,
                value: dueDay.value,
                valueLabel: l10n.lease_due_day_value(dueDay.value),
                onChanged: (d) => dueDay.value = d,
              ),
              const SizedBox(height: KhatirSpacing.s2),
              _Helper(text: l10n.lease_due_day_note),
              const SizedBox(height: KhatirSpacing.s6),

              // ── Actions ────────────────────────────────────────────────
              _SaveButton(
                key: const ValueKey('leaseSave'),
                label: l10n.lease_save,
                filled: false,
                busy: saving.value,
                onPressed:
                    saving.value ? null : () => save(activate: false),
              ),
              const SizedBox(height: KhatirSpacing.s3),
              _SaveButton(
                key: const ValueKey('leaseActivate'),
                label: l10n.lease_activate,
                filled: true,
                busy: saving.value,
                onPressed:
                    saving.value ? null : () => save(activate: true),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Renders a money double without a trailing `.0` for whole amounts.
  static String _money(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();
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

/// A muted helper/empty line beneath a field or section.
class _Helper extends StatelessWidget {
  const _Helper({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTextStyles.bodySmall.copyWith(
        color: KhatirColors.mutedDk,
        height: 1.4,
      ),
    );
  }
}

/// The tenant dropdown, seeded from the unit's tenants. Stores the tenant id.
class _TenantPicker extends StatelessWidget {
  const _TenantPicker({
    super.key,
    required this.label,
    required this.hint,
    required this.tenants,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String hint;
  final List<Tenant> tenants;
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      hint: Text(
        hint,
        style: AppTextStyles.bodyMedium.copyWith(color: KhatirColors.muted),
      ),
      style: AppTextStyles.bodyMedium,
      icon: const Icon(Icons.expand_more, color: KhatirColors.sageDk),
      dropdownColor: KhatirColors.card,
      decoration: _fieldDecoration(
        label: label,
        icon: Icons.person_outline,
      ),
      items: [
        for (final t in tenants)
          DropdownMenuItem<String>(
            value: t.id,
            child: Text(t.name, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: onChanged,
    );
  }
}

/// A single editable text field, matching the shared form field composition.
class _FormField extends StatelessWidget {
  const _FormField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.inputFormatters,
    this.required = false,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final bool required;
  final FormFieldValidator<String>? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      style: AppTextStyles.bodyMedium,
      decoration: _fieldDecoration(
        label: required ? '$label ★' : label,
        icon: icon,
      ),
    );
  }
}

/// A read-only field that opens a date picker on tap.
class _DateField extends StatelessWidget {
  const _DateField({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(KhatirRadius.md),
      child: InputDecorator(
        decoration: _fieldDecoration(
          label: '$label ★',
          icon: Icons.event_outlined,
        ),
        child: Text(
          value.isEmpty ? ' ' : value,
          style: AppTextStyles.bodyMedium.copyWith(
            color: value.isEmpty ? KhatirColors.muted : null,
          ),
        ),
      ),
    );
  }
}

/// A due-day stepper (1–28, the always-valid range across months). Displays the
/// chosen day and lets the user nudge it up/down.
class _DueDayField extends StatelessWidget {
  const _DueDayField({
    super.key,
    required this.label,
    required this.value,
    required this.valueLabel,
    required this.onChanged,
  });

  final String label;
  final int value;
  final String valueLabel;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: _fieldDecoration(
        label: label,
        icon: Icons.today_outlined,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(valueLabel, style: AppTextStyles.bodyMedium),
          ),
          IconButton(
            key: const ValueKey('leaseDueDayDown'),
            visualDensity: VisualDensity.compact,
            onPressed: value > 1 ? () => onChanged(value - 1) : null,
            icon: const Icon(Icons.remove, color: KhatirColors.sageDk),
          ),
          IconButton(
            key: const ValueKey('leaseDueDayUp'),
            visualDensity: VisualDensity.compact,
            onPressed: value < 28 ? () => onChanged(value + 1) : null,
            icon: const Icon(Icons.add, color: KhatirColors.sageDk),
          ),
        ],
      ),
    );
  }
}

/// A full-width pill button — [filled] sage for the primary activate action,
/// outlined for the secondary save-draft action.
class _SaveButton extends StatelessWidget {
  const _SaveButton({
    super.key,
    required this.label,
    required this.filled,
    required this.busy,
    required this.onPressed,
  });

  final String label;
  final bool filled;
  final bool busy;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(KhatirRadius.button),
    );
    final padding = const EdgeInsets.symmetric(vertical: KhatirSpacing.s4);
    final spinner = SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(
        strokeWidth: 2.5,
        color: filled ? KhatirColors.cream : KhatirColors.sageDk,
      ),
    );

    if (filled) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: KhatirColors.sage,
            foregroundColor: KhatirColors.cream,
            disabledBackgroundColor: KhatirColors.sage,
            disabledForegroundColor: KhatirColors.cream,
            elevation: 0,
            padding: padding,
            textStyle: AppTextStyles.labelLarge,
            shape: shape,
          ),
          child: busy ? spinner : Text(label),
        ),
      );
    }
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: KhatirColors.sageDk,
          padding: padding,
          textStyle: AppTextStyles.labelLarge,
          side: const BorderSide(color: KhatirColors.sage),
          shape: shape,
        ),
        child: busy ? spinner : Text(label),
      ),
    );
  }
}

/// Shared field decoration (white card, line border, sage focus) so the picker,
/// text, date, and stepper fields read identically.
InputDecoration _fieldDecoration({
  required String label,
  required IconData icon,
}) {
  return InputDecoration(
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
  );
}
