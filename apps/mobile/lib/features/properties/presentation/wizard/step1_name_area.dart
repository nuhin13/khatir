import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khatir_tokens/khatir_tokens.dart';

import '../../../../core/config/public_config_provider.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/property_enums.dart';
import '../screens/portfolio_screen.dart' show areaLabel;
import 'add_building_controller.dart';
import 'wizard_widgets.dart';

/// Wizard step 1 — building name (required) + area chips (required).
///
/// Area chips come from `area_options` in `/config/public` (T-006), never a
/// hardcoded list. The "Next" button is disabled until both a non-blank name
/// and an area are chosen; tapping it while invalid surfaces the first failing
/// field's error.
class Step1NameArea extends ConsumerStatefulWidget {
  const Step1NameArea({super.key, required this.onNext});

  /// Called when the step is valid and the user advances.
  final VoidCallback onNext;

  @override
  ConsumerState<Step1NameArea> createState() => _Step1NameAreaState();
}

class _Step1NameAreaState extends ConsumerState<Step1NameArea> {
  late final TextEditingController _name;
  bool _showErrors = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(
      text: ref.read(addBuildingControllerProvider).name,
    );
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _submit() {
    final controller = ref.read(addBuildingControllerProvider.notifier);
    controller.setName(_name.text);
    final valid = ref.read(addBuildingControllerProvider).step1Valid;
    if (!valid) {
      setState(() => _showErrors = true);
      return;
    }
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(addBuildingControllerProvider);
    final controller = ref.read(addBuildingControllerProvider.notifier);
    final areasAsync = ref.watch(publicConfigProvider);
    final areas = areasAsync.maybeWhen(
      data: (c) => c.areaOptions,
      orElse: () => Area.values,
    );

    final nameError =
        _showErrors && _name.text.trim().isEmpty ? l10n.wizard_err_name : null;
    final areaError =
        _showErrors && state.area == null ? l10n.wizard_err_area : null;

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
            emoji: '🏢',
            title: l10n.wizard_step1_hero_title,
            subtitle: l10n.wizard_step1_hero_sub,
          ),
          const SizedBox(height: KhatirSpacing.s4),
          WizardField(
            label: l10n.building_name,
            required: true,
            errorText: nameError,
            child: TextField(
              controller: _name,
              onChanged: (v) {
                controller.setName(v);
                if (_showErrors) setState(() {});
              },
              style: AppTextStyles.bodyLarge,
              decoration: wizardInputDecoration(l10n.building_name_hint),
            ),
          ),
          const SizedBox(height: KhatirSpacing.s3),
          WizardField(
            label: l10n.building_area,
            required: true,
            errorText: areaError,
            child: Padding(
              padding: const EdgeInsets.only(top: KhatirSpacing.s1),
              child: Wrap(
                spacing: KhatirSpacing.s2 - 1,
                runSpacing: KhatirSpacing.s2 - 1,
                children: [
                  for (final area in areas)
                    _AreaChip(
                      label: areaLabel(l10n, area),
                      selected: state.area == area,
                      onTap: () {
                        controller.setArea(area);
                        if (_showErrors) setState(() {});
                      },
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: KhatirSpacing.s5),
          WizardPrimaryButton(
            label: l10n.wizard_next,
            onTap: _submit,
          ),
        ],
      ),
    );
  }
}

/// A single selectable area pill. Sage when selected, sage-bg otherwise — values
/// from the design tokens.
class _AreaChip extends StatelessWidget {
  const _AreaChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(KhatirRadius.pill);
    return Material(
      color: selected ? KhatirColors.sage : KhatirColors.sageBg,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: KhatirSpacing.s4 - 2,
            vertical: KhatirSpacing.s2,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: KhatirFonts.title,
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
              color: selected ? KhatirColors.card : KhatirColors.sageDk,
            ),
          ),
        ),
      ),
    );
  }
}
