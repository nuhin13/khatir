import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khatir_tokens/khatir_tokens.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../properties/data/models/building.dart';
import '../../../properties/data/models/unit.dart';
import '../../../properties/data/properties_providers.dart';
import '../../../tenants/data/tenants_providers.dart';
import '../../data/models/maintenance_enums.dart';
import '../../data/providers.dart';
import 'expenses_screen.dart' show ExpensesScreen, categoryLabel;

/// The draft an add-expense submission emits — the test seam that lets widget
/// tests assert the entered fields + chosen unit without hitting the network.
/// Mirrors the create call the expense endpoint consumes (T-003 / T-007
/// [ExpenseRepository.createExpense]): a unit, an amount, a category, the day
/// incurred, an optional note and an optional receipt reference.
class AddExpenseDraft {
  const AddExpenseDraft({
    required this.unitId,
    required this.amount,
    required this.category,
    required this.date,
    this.note,
    this.receiptRef,
  });

  final String unitId;
  final double amount;
  final ExpenseCategory category;
  final DateTime date;
  final String? note;
  final String? receiptRef;
}

/// Add-expense screen (EPIC-08 T-009), reached at `/expenses/add` from the
/// expenses list's app-bar Add action. It logs a manual expense on a unit:
/// amount, category, unit, date, an optional note and an optional receipt photo.
///
/// Per the `addExpense` prototype (`proto/screens-landlord2.js` →
/// `reg('addExpense')`): the amount input, a wrapping category chip row, the
/// unit + date fields, a note field, then the full-width "Save expense" CTA.
/// The single prototype "Unit" field is realised here as a building selector
/// plus a unit selector (the create call needs the unit id; the building narrows
/// the choice). Every colour/spacing/radius/font comes from the design tokens
/// (no prototype hex/px); typed numerals are kept as-is.
///
/// Categories come from the [ExpenseCategory] config enum (T-006 seed / enums).
/// Saving runs [ExpenseRepository.createExpense] then invalidates the expense
/// list so the new row shows on return, and routes back to `/expenses`.
///
/// States: **data** (the idle form), **validation** (inline amount/unit errors),
/// **saving** (a spinner on the CTA, form disabled), **error** (a friendly
/// snackbar, form re-enabled to retry).
class AddExpenseScreen extends HookConsumerWidget {
  const AddExpenseScreen({super.key, this.onSaved});

  /// Test seam: invoked with the entered [AddExpenseDraft] when Save is tapped
  /// and validation passes. When null (the default, and what the router
  /// supplies) the screen runs the real create flow and routes back to the list.
  final Future<void> Function(AddExpenseDraft draft)? onSaved;

  static const String routePath = '/expenses/add';
  static const String routeName = 'addExpense';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    final amountCtrl = useTextEditingController();
    final noteCtrl = useTextEditingController();
    final category = useState<ExpenseCategory>(ExpenseCategory.plumbing);
    final buildingId = useState<String?>(null);
    final unitId = useState<String?>(null);
    final unitError = useState<bool>(false);
    final date = useState<DateTime>(DateTime.now());
    final receipt = useState<PickedImage?>(null);
    final busy = useState<bool>(false);
    final formKey = useMemoized(GlobalKey<FormState>.new);

    Future<void> save() async {
      final form = formKey.currentState;
      final formOk = form != null && form.validate();
      final unit = unitId.value;
      unitError.value = unit == null;
      if (!formOk || unit == null) return;

      final amount = double.parse(amountCtrl.text.trim());
      final note = noteCtrl.text.trim();
      final messenger = ScaffoldMessenger.of(context);
      final router = GoRouter.maybeOf(context);

      busy.value = true;
      try {
        final draft = AddExpenseDraft(
          unitId: unit,
          amount: amount,
          category: category.value,
          date: date.value,
          note: note.isEmpty ? null : note,
          // The picked receipt is attached by name; the encrypted-storage upload
          // ref is wired through the same field when the media endpoint lands.
          receiptRef: receipt.value?.filename,
        );
        if (onSaved != null) {
          await onSaved!(draft);
          return;
        }
        await ref.read(expenseRepositoryProvider).createExpense(
              unitId: draft.unitId,
              amount: draft.amount,
              date: draft.date,
              category: draft.category,
              note: draft.note,
              receiptRef: draft.receiptRef,
            );
        // Keep the list fresh so the new expense shows on return (all filters).
        ref.invalidate(expenseListProvider);
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(l10n.expense_saved)));
        router?.go(ExpensesScreen.routePath);
      } on ApiException {
        _reportError(messenger, l10n);
      } catch (_) {
        _reportError(messenger, l10n);
      } finally {
        busy.value = false;
      }
    }

    return Scaffold(
      backgroundColor: KhatirColors.cream,
      appBar: AppBar(
        backgroundColor: KhatirColors.cream,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          l10n.add_expense_title,
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
              // ── Amount (required) ───────────────────────────────────────────
              _Field(
                key: const ValueKey('expenseAmount'),
                controller: amountCtrl,
                label: l10n.expense_amount,
                hint: l10n.expense_amount_hint,
                icon: Icons.payments_outlined,
                enabled: !busy.value,
                keyboardType: const TextInputType.numberWithOptions(),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  final amount = double.tryParse((value ?? '').trim());
                  if (amount == null || amount <= 0) {
                    return l10n.expense_err_amount;
                  }
                  return null;
                },
              ),
              const SizedBox(height: KhatirSpacing.s4),

              // ── Category (config chips) ─────────────────────────────────────
              _CategoryPicker(
                selected: category.value,
                onSelected:
                    busy.value ? null : (c) => category.value = c,
              ),
              const SizedBox(height: KhatirSpacing.s4),

              // ── Building → Unit (the create call needs the unit id) ─────────
              _BuildingSelector(
                selectedBuildingId: buildingId.value,
                enabled: !busy.value,
                onSelected: (id) {
                  buildingId.value = id;
                  unitId.value = null;
                  unitError.value = false;
                },
              ),
              const SizedBox(height: KhatirSpacing.s4),
              _UnitSelector(
                buildingId: buildingId.value,
                selectedUnitId: unitId.value,
                showError: unitError.value,
                enabled: !busy.value,
                onSelected: (id) {
                  unitId.value = id;
                  unitError.value = false;
                },
              ),
              const SizedBox(height: KhatirSpacing.s4),

              // ── Date ────────────────────────────────────────────────────────
              _DateField(
                date: date.value,
                enabled: !busy.value,
                onPick: (d) => date.value = d,
              ),
              const SizedBox(height: KhatirSpacing.s4),

              // ── Note (optional) ─────────────────────────────────────────────
              _Field(
                key: const ValueKey('expenseNote'),
                controller: noteCtrl,
                label: l10n.expense_note,
                icon: Icons.notes_outlined,
                enabled: !busy.value,
                keyboardType: TextInputType.multiline,
                maxLines: 3,
              ),
              const SizedBox(height: KhatirSpacing.s4),

              // ── Receipt (optional photo) ────────────────────────────────────
              _ReceiptPicker(
                receipt: receipt.value,
                enabled: !busy.value,
                onPick: () async {
                  final picked = await ref
                      .read(imagePickerServiceProvider)
                      .pickFromGallery();
                  if (picked != null) receipt.value = picked;
                },
                onRemove: () => receipt.value = null,
              ),
              const SizedBox(height: KhatirSpacing.s6),

              // ── Save ────────────────────────────────────────────────────────
              _SaveButton(
                key: const ValueKey('expenseSave'),
                label: l10n.expense_save,
                busy: busy.value,
                onPressed: busy.value ? null : save,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _reportError(ScaffoldMessengerState messenger, AppLocalizations l10n) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(l10n.expense_save_failed)));
  }
}

/// The wrapping category chip row, driven by the [ExpenseCategory] config enum.
/// The selected chip fills sage; the rest are sage-tinted, mirroring the
/// prototype's category buttons.
class _CategoryPicker extends StatelessWidget {
  const _CategoryPicker({required this.selected, required this.onSelected});

  final ExpenseCategory selected;
  final ValueChanged<ExpenseCategory>? onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _SectionCard(
      label: l10n.expense_category,
      child: Wrap(
        spacing: KhatirSpacing.s2,
        runSpacing: KhatirSpacing.s2,
        children: [
          for (final category in ExpenseCategory.values)
            _CategoryChip(
              key: ValueKey('expenseCategory-${category.wire}'),
              label: '${_emoji(category)} ${categoryLabel(l10n, category)}',
              selected: category == selected,
              onTap: onSelected == null ? null : () => onSelected!(category),
            ),
        ],
      ),
    );
  }

  static String _emoji(ExpenseCategory category) => switch (category) {
        ExpenseCategory.plumbing => '🔧',
        ExpenseCategory.paint => '🎨',
        ExpenseCategory.electrical => '💡',
        ExpenseCategory.structural => '🏗️',
        ExpenseCategory.appliance => '❄️',
        ExpenseCategory.utility => '💧',
        ExpenseCategory.other => '✨',
      };
}

/// One category pill; the selected one fills sage.
class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(KhatirRadius.chip);
    return Material(
      color: selected ? KhatirColors.sage : KhatirColors.sageBg,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: KhatirSpacing.s3,
            vertical: KhatirSpacing.s2,
          ),
          child: Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              color: selected ? KhatirColors.card : KhatirColors.sageDk,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

/// The building selector — a labelled dropdown over the caller's buildings
/// ([buildingsProvider]). Choosing a building resets the unit (its units are
/// loaded fresh). While buildings load (or if the read fails) the dropdown is
/// empty so the form never blocks.
class _BuildingSelector extends ConsumerWidget {
  const _BuildingSelector({
    required this.selectedBuildingId,
    required this.enabled,
    required this.onSelected,
  });

  final String? selectedBuildingId;
  final bool enabled;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final buildings =
        ref.watch(buildingsProvider).asData?.value ?? const <Building>[];

    return _SectionCard(
      label: l10n.expense_building,
      child: _Dropdown<String>(
        key: const ValueKey('expenseBuilding'),
        value: selectedBuildingId,
        hint: l10n.expense_building_hint,
        enabled: enabled,
        items: [
          for (final building in buildings)
            DropdownMenuItem<String>(
              value: building.id,
              child: Text(building.name, overflow: TextOverflow.ellipsis),
            ),
        ],
        onChanged: enabled ? onSelected : null,
      ),
    );
  }
}

/// The unit selector — a labelled dropdown over the chosen building's units
/// ([buildingUnitsProvider]). Disabled until a building is chosen. Shows the
/// missing-unit validation error inline when [showError] is set (the unit is not
/// a [FormField], so it is validated alongside the form on Save).
class _UnitSelector extends ConsumerWidget {
  const _UnitSelector({
    required this.buildingId,
    required this.selectedUnitId,
    required this.showError,
    required this.enabled,
    required this.onSelected,
  });

  final String? buildingId;
  final String? selectedUnitId;
  final bool showError;
  final bool enabled;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final units = buildingId == null
        ? const <Unit>[]
        : ref.watch(buildingUnitsProvider(buildingId!)).asData?.value ??
            const <Unit>[];
    final active = enabled && buildingId != null;

    return _SectionCard(
      label: l10n.expense_unit,
      error: showError ? l10n.expense_err_unit : null,
      child: _Dropdown<String>(
        key: const ValueKey('expenseUnit'),
        value: selectedUnitId,
        hint: l10n.expense_unit_hint,
        enabled: active,
        hasError: showError,
        items: [
          for (final unit in units)
            DropdownMenuItem<String>(
              value: unit.id,
              child: Text(unit.label, overflow: TextOverflow.ellipsis),
            ),
        ],
        onChanged: active ? onSelected : null,
      ),
    );
  }
}

/// The date field — a read-only tappable card opening the platform date picker,
/// defaulting to today. Shows the chosen `YYYY-MM-DD` day.
class _DateField extends StatelessWidget {
  const _DateField({
    required this.date,
    required this.enabled,
    required this.onPick,
  });

  final DateTime date;
  final bool enabled;
  final ValueChanged<DateTime> onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final radius = BorderRadius.circular(KhatirRadius.md);
    final text = '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';

    return _SectionCard(
      label: l10n.expense_date,
      child: Material(
        color: KhatirColors.card,
        borderRadius: radius,
        child: InkWell(
          key: const ValueKey('expenseDate'),
          borderRadius: radius,
          onTap: enabled
              ? () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: date,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) onPick(picked);
                }
              : null,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: KhatirSpacing.s4,
              vertical: KhatirSpacing.s4,
            ),
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(color: KhatirColors.line),
            ),
            child: Row(
              children: [
                const Icon(Icons.event_outlined,
                    size: 20, color: KhatirColors.sageDk),
                const SizedBox(width: KhatirSpacing.s3),
                Expanded(
                  child: Text(text, style: AppTextStyles.bodyMedium),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The optional receipt picker — an "Attach receipt" button when empty, or the
/// attached-confirmation row (with a Remove affordance) once a photo is picked.
class _ReceiptPicker extends StatelessWidget {
  const _ReceiptPicker({
    required this.receipt,
    required this.enabled,
    required this.onPick,
    required this.onRemove,
  });

  final PickedImage? receipt;
  final bool enabled;
  final Future<void> Function() onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final radius = BorderRadius.circular(KhatirRadius.md);

    return _SectionCard(
      label: l10n.expense_receipt,
      child: receipt == null
          ? Material(
              color: KhatirColors.sageBg,
              borderRadius: radius,
              child: InkWell(
                key: const ValueKey('expenseReceiptAdd'),
                borderRadius: radius,
                onTap: enabled ? onPick : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: KhatirSpacing.s4,
                    vertical: KhatirSpacing.s4,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.add_a_photo_outlined,
                          size: 20, color: KhatirColors.sageDk),
                      const SizedBox(width: KhatirSpacing.s3),
                      Text(
                        l10n.expense_receipt_add,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: KhatirColors.sageDk,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : Container(
              key: const ValueKey('expenseReceiptAttached'),
              padding: const EdgeInsets.symmetric(
                horizontal: KhatirSpacing.s4,
                vertical: KhatirSpacing.s3,
              ),
              decoration: BoxDecoration(
                color: KhatirColors.card,
                borderRadius: radius,
                border: Border.all(color: KhatirColors.line),
              ),
              child: Row(
                children: [
                  const Icon(Icons.receipt_long_outlined,
                      size: 20, color: KhatirColors.sageDk),
                  const SizedBox(width: KhatirSpacing.s3),
                  Expanded(
                    child: Text(
                      l10n.expense_receipt_attached,
                      style: AppTextStyles.bodyMedium
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  TextButton(
                    key: const ValueKey('expenseReceiptRemove'),
                    onPressed: enabled ? onRemove : null,
                    child: Text(
                      l10n.expense_receipt_remove,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: KhatirColors.roseDk,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

/// A labelled section wrapper: the field label, the [child] control, and an
/// optional inline [error] line — matching the prototype's `k-field` block.
class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.label,
    required this.child,
    this.error,
  });

  final String label;
  final Widget child;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: KhatirColors.mutedDk,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: KhatirSpacing.s2),
        child,
        if (error != null) ...[
          const SizedBox(height: KhatirSpacing.s1),
          Text(
            error!,
            style: AppTextStyles.bodySmall.copyWith(color: KhatirColors.danger),
          ),
        ],
      ],
    );
  }
}

/// A token-styled dropdown inside a white card, used by the building + unit
/// selectors. Shows [hint] until a value is chosen; outlined danger when
/// [hasError].
class _Dropdown<T> extends StatelessWidget {
  const _Dropdown({
    super.key,
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
    required this.enabled,
    this.hasError = false,
  });

  final T? value;
  final String hint;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final bool enabled;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(KhatirRadius.md);
    final border = OutlineInputBorder(
      borderRadius: radius,
      borderSide: BorderSide(
        color: hasError ? KhatirColors.danger : KhatirColors.line,
      ),
    );
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      hint: Text(
        hint,
        style: AppTextStyles.bodySmall.copyWith(color: KhatirColors.muted),
      ),
      style: AppTextStyles.bodyMedium.copyWith(color: KhatirColors.ink),
      icon: const Icon(Icons.expand_more_rounded, color: KhatirColors.sageDk),
      items: items,
      onChanged: enabled ? onChanged : null,
      decoration: InputDecoration(
        filled: true,
        fillColor: KhatirColors.card,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: KhatirSpacing.s4,
          vertical: KhatirSpacing.s3,
        ),
        border: border,
        enabledBorder: border,
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(
            color: hasError ? KhatirColors.danger : KhatirColors.sage,
            width: 2,
          ),
        ),
      ),
    );
  }
}

/// A single editable text field, matching the shared form-field composition
/// (white card, line border, sage focus).
class _Field extends StatelessWidget {
  const _Field({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.hint,
    this.enabled = true,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? hint;
  final bool enabled;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final FormFieldValidator<String>? validator;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(KhatirRadius.md);
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      maxLines: maxLines,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      style: AppTextStyles.bodyMedium,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        alignLabelWithHint: maxLines > 1,
        labelStyle: AppTextStyles.bodySmall.copyWith(
          color: KhatirColors.mutedDk,
          fontWeight: FontWeight.w600,
        ),
        hintStyle:
            AppTextStyles.bodySmall.copyWith(color: KhatirColors.muted),
        prefixIcon: Icon(icon, size: 20, color: KhatirColors.sageDk),
        filled: true,
        fillColor: KhatirColors.card,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: KhatirSpacing.s4,
          vertical: KhatirSpacing.s3,
        ),
        border: OutlineInputBorder(
          borderRadius: radius,
          borderSide: const BorderSide(color: KhatirColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: const BorderSide(color: KhatirColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: const BorderSide(color: KhatirColors.sage, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: const BorderSide(color: KhatirColors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: radius,
          borderSide: const BorderSide(color: KhatirColors.danger, width: 2),
        ),
      ),
    );
  }
}

/// The full-width sage "Save expense" CTA; shows a spinner while [busy].
class _SaveButton extends StatelessWidget {
  const _SaveButton({
    super.key,
    required this.label,
    required this.busy,
    required this.onPressed,
  });

  final String label;
  final bool busy;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(KhatirRadius.button),
    );
    final child = busy
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: KhatirColors.cream,
            ),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_rounded, size: 18),
              const SizedBox(width: KhatirSpacing.s2),
              Flexible(child: Text(label, textAlign: TextAlign.center)),
            ],
          );

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
          padding: const EdgeInsets.symmetric(vertical: KhatirSpacing.s4),
          textStyle: AppTextStyles.labelLarge,
          shape: shape,
        ),
        child: child,
      ),
    );
  }
}
