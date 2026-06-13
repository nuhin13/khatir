import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khatir_tokens/khatir_tokens.dart';

import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/property_enums.dart';
import 'add_building_controller.dart';
import 'wizard_widgets.dart';

/// Wizard step 3 — the units generator.
///
/// Two steppers (floors, flats/floor) and a scheme toggle (`1A·1B` letter /
/// `101·102` number) drive a live, de-duplicated label list that mirrors the
/// backend generator exactly. Each label chip is removable; a "+ custom" action
/// adds arbitrary labels (e.g. `8B`, `2001`). "Next" is gated on at least one
/// unit existing.
class Step3Units extends ConsumerWidget {
  const Step3Units({super.key, required this.onNext});

  /// Called when the step is valid and the user advances.
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(addBuildingControllerProvider);
    final controller = ref.read(addBuildingControllerProvider.notifier);
    final labels = state.unitLabels;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        KhatirSpacing.s5,
        0,
        KhatirSpacing.s5,
        KhatirSpacing.s6,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          WizardHero(
            emoji: '🚪',
            title: l10n.wizard_step3_hero_title,
            subtitle: l10n.wizard_step3_hero_sub,
          ),
          const SizedBox(height: KhatirSpacing.s4),
          _Stepper(
            label: l10n.wizard_floors,
            sub: l10n.wizard_floors_sub,
            value: state.floors,
            onDecrement: () => controller.changeFloors(-1),
            onIncrement: () => controller.changeFloors(1),
          ),
          const SizedBox(height: KhatirSpacing.s2 + 2),
          _Stepper(
            label: l10n.wizard_per_floor,
            sub: l10n.wizard_per_floor_sub,
            value: state.perFloor,
            onDecrement: () => controller.changePerFloor(-1),
            onIncrement: () => controller.changePerFloor(1),
          ),
          const SizedBox(height: KhatirSpacing.s2 + 2),
          WizardField(
            label: l10n.wizard_scheme,
            child: Padding(
              padding: const EdgeInsets.only(top: KhatirSpacing.s1 + 2),
              child: Row(
                children: [
                  Expanded(
                    child: _SchemeOption(
                      title: '1A · 1B',
                      sub: l10n.wizard_scheme_letter,
                      selected: state.scheme == UnitScheme.letter,
                      onTap: () => controller.setScheme(UnitScheme.letter),
                    ),
                  ),
                  const SizedBox(width: KhatirSpacing.s2),
                  Expanded(
                    child: _SchemeOption(
                      title: '101 · 102',
                      sub: l10n.wizard_scheme_number,
                      selected: state.scheme == UnitScheme.number,
                      onTap: () => controller.setScheme(UnitScheme.number),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: KhatirSpacing.s3),
          _UnitListCard(
            labels: labels,
            onRemove: controller.removeLabel,
            onAddCustom: () => _promptAddCustom(context, controller),
          ),
          const SizedBox(height: KhatirSpacing.s4),
          WizardPrimaryButton(
            label: l10n.wizard_next_review,
            onTap: () {
              if (state.step3Valid) onNext();
            },
          ),
        ],
      ),
    );
  }

  /// Opens a small dialog to capture a custom unit label, then adds it.
  Future<void> _promptAddCustom(
    BuildContext context,
    AddBuildingController controller,
  ) async {
    final value = await showDialog<String>(
      context: context,
      builder: (context) => const _AddCustomDialog(),
    );
    if (value != null && value.trim().isNotEmpty) {
      controller.addCustomLabel(value);
    }
  }
}

/// A labelled +/− stepper row. Mirrors the prototype's `stepCtl(...)`.
class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.label,
    required this.sub,
    required this.value,
    required this.onDecrement,
    required this.onIncrement,
  });

  final String label;
  final String sub;
  final int value;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: KhatirFonts.title,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: KhatirColors.ink,
                ),
              ),
              Text(
                sub,
                style: AppTextStyles.bodySmall.copyWith(
                  color: KhatirColors.muted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(KhatirSpacing.s1),
          decoration: BoxDecoration(
            color: KhatirColors.sageBg,
            borderRadius: BorderRadius.circular(KhatirRadius.pill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _StepButton(icon: Icons.remove, onTap: onDecrement),
              SizedBox(
                width: 38,
                child: Text(
                  '$value',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: KhatirFonts.title,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    color: KhatirColors.ink,
                  ),
                ),
              ),
              _StepButton(icon: Icons.add, onTap: onIncrement),
            ],
          ),
        ),
      ],
    );
  }
}

/// A round +/− button inside a [_Stepper].
class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: KhatirColors.card,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(icon, size: 18, color: KhatirColors.sageDk),
        ),
      ),
    );
  }
}

/// One of the two numbering-scheme toggle cards.
class _SchemeOption extends StatelessWidget {
  const _SchemeOption({
    required this.title,
    required this.sub,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String sub;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(KhatirRadius.tile - 4);
    return Material(
      color: selected ? KhatirColors.sageBg : KhatirColors.card,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          padding: const EdgeInsets.all(KhatirSpacing.s3 - 2),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(
              color: selected ? KhatirColors.sage : KhatirColors.line,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Text(
                title,
                style: TextStyle(
                  fontFamily: KhatirFonts.title,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: KhatirColors.ink,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                sub,
                style: AppTextStyles.bodySmall.copyWith(
                  color: KhatirColors.muted,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The card holding the unit-count header, the +custom action and the removable
/// label chips. Mirrors the prototype's units `k-card`.
class _UnitListCard extends StatelessWidget {
  const _UnitListCard({
    required this.labels,
    required this.onRemove,
    required this.onAddCustom,
  });

  final List<String> labels;
  final ValueChanged<String> onRemove;
  final VoidCallback onAddCustom;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.all(KhatirSpacing.s4),
      decoration: BoxDecoration(
        color: KhatirColors.card,
        borderRadius: BorderRadius.circular(KhatirRadius.card),
        border: Border.all(color: KhatirColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.wizard_units_count(labels.length),
                  style: TextStyle(
                    fontFamily: KhatirFonts.title,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: KhatirColors.ink,
                  ),
                ),
              ),
              const SizedBox(width: KhatirSpacing.s2),
              _AddCustomChip(onTap: onAddCustom),
            ],
          ),
          const SizedBox(height: KhatirSpacing.s3 - 2),
          if (labels.isEmpty)
            Padding(
              padding: const EdgeInsets.all(KhatirSpacing.s2),
              child: Text(
                l10n.wizard_units_empty,
                style: AppTextStyles.bodySmall.copyWith(
                  color: KhatirColors.muted,
                ),
              ),
            )
          else
            Wrap(
              spacing: KhatirSpacing.s2,
              runSpacing: KhatirSpacing.s2,
              children: [
                for (final label in labels)
                  _UnitChip(label: label, onRemove: () => onRemove(label)),
              ],
            ),
          const SizedBox(height: KhatirSpacing.s3 - 2),
          const Divider(color: KhatirColors.line, height: 1),
          const SizedBox(height: KhatirSpacing.s3 - 2),
          Text(
            l10n.wizard_units_footnote,
            style: AppTextStyles.bodySmall.copyWith(
              color: KhatirColors.muted,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

/// The rose "+ custom" pill.
class _AddCustomChip extends StatelessWidget {
  const _AddCustomChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final radius = BorderRadius.circular(KhatirRadius.pill);
    return Material(
      color: KhatirColors.roseBg,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: KhatirSpacing.s3,
            vertical: KhatirSpacing.s2 - 2,
          ),
          child: Text(
            l10n.wizard_add_custom,
            style: TextStyle(
              fontFamily: KhatirFonts.title,
              fontWeight: FontWeight.w700,
              fontSize: 11.5,
              color: KhatirColors.roseDk,
            ),
          ),
        ),
      ),
    );
  }
}

/// A single removable unit-label chip.
class _UnitChip extends StatelessWidget {
  const _UnitChip({required this.label, required this.onRemove});

  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        KhatirSpacing.s3 - 2,
        KhatirSpacing.s2,
        KhatirSpacing.s2 - 2,
        KhatirSpacing.s2,
      ),
      decoration: BoxDecoration(
        color: KhatirColors.sageBg,
        borderRadius: BorderRadius.circular(KhatirRadius.tile - 6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: KhatirFonts.title,
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: KhatirColors.sageDk,
            ),
          ),
          const SizedBox(width: KhatirSpacing.s1 + 2),
          InkWell(
            customBorder: const CircleBorder(),
            onTap: onRemove,
            child: const Icon(Icons.close, size: 14, color: KhatirColors.muted),
          ),
        ],
      ),
    );
  }
}

/// A minimal dialog that captures a custom unit label.
class _AddCustomDialog extends StatefulWidget {
  const _AddCustomDialog();

  @override
  State<_AddCustomDialog> createState() => _AddCustomDialogState();
}

class _AddCustomDialogState extends State<_AddCustomDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      backgroundColor: KhatirColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(KhatirRadius.card),
      ),
      title: Text(
        l10n.wizard_add_custom_title,
        style: AppTextStyles.titleMedium,
      ),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textInputAction: TextInputAction.done,
        onSubmitted: (v) => Navigator.of(context).pop(v),
        style: AppTextStyles.bodyLarge,
        decoration: wizardInputDecoration(l10n.wizard_add_custom_hint),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            l10n.wizard_cancel,
            style: AppTextStyles.labelLarge.copyWith(color: KhatirColors.muted),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: Text(
            l10n.wizard_add,
            style: AppTextStyles.labelLarge.copyWith(color: KhatirColors.sageDk),
          ),
        ),
      ],
    );
  }
}
