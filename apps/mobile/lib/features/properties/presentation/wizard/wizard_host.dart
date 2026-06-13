import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khatir_tokens/khatir_tokens.dart';

import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';
import 'add_building_controller.dart';
import 'step1_name_area.dart';
import 'step2_address_map.dart';
import 'step3_units.dart';
import 'step4_review.dart';
import 'wizard_progress.dart';

/// Host screen for the 4-step add-building wizard (`/properties/add`).
///
/// Owns the shared chrome — a top bar with a context-aware back button and the
/// current step's title, plus the [WizardProgress] header — and renders the
/// step view for [AddBuildingState.step]. Back on step 1 leaves the wizard;
/// back on later steps returns to the previous step. T-010 wires steps 1–2;
/// steps 3–4 (T-011) are placeholders here until that task lands.
class WizardHost extends ConsumerWidget {
  const WizardHost({super.key});

  static const String routePath = '/properties/add';
  static const String routeName = 'addBuilding';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final step = ref.watch(addBuildingControllerProvider.select((s) => s.step));
    final controller = ref.read(addBuildingControllerProvider.notifier);

    final titles = <String>[
      l10n.wizard_title_name,
      l10n.wizard_title_address,
      l10n.wizard_title_units,
      l10n.wizard_title_review,
    ];

    void onBack() {
      if (step > 1) {
        controller.back();
      } else if (context.canPop()) {
        context.pop();
      } else {
        context.go('/landlord/home');
      }
    }

    return PopScope(
      // Intercept the system back so step >1 walks back through the wizard
      // rather than popping the whole route.
      canPop: step <= 1,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && step > 1) controller.back();
      },
      child: Scaffold(
        backgroundColor: KhatirColors.cream,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _WizardTopBar(title: titles[step - 1], onBack: onBack),
              WizardProgress(step: step),
              Expanded(child: _StepView(step: step, onNext: controller.next)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Picks the body for the active step. Steps 3–4 land in T-011.
class _StepView extends StatelessWidget {
  const _StepView({required this.step, required this.onNext});

  final int step;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    switch (step) {
      case 1:
        return Step1NameArea(onNext: onNext);
      case 2:
        return Step2AddressMap(onNext: onNext);
      case 3:
        return Step3Units(onNext: onNext);
      default:
        return const Step4Review();
    }
  }
}

/// Top bar: a circular back button and the current step's title.
class _WizardTopBar extends StatelessWidget {
  const _WizardTopBar({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        KhatirSpacing.s3,
        KhatirSpacing.s2,
        KhatirSpacing.s4,
        KhatirSpacing.s1,
      ),
      child: Row(
        children: [
          Material(
            color: KhatirColors.card,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onBack,
              child: const Padding(
                padding: EdgeInsets.all(KhatirSpacing.s2),
                child: Icon(Icons.arrow_back, size: 20, color: KhatirColors.ink),
              ),
            ),
          ),
          const SizedBox(width: KhatirSpacing.s2),
          Expanded(
            child: Text(
              title,
              style: AppTextStyles.titleLarge.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
