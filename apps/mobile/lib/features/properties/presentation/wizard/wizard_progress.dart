import 'package:flutter/material.dart';
import 'package:khatir_tokens/khatir_tokens.dart';

import '../../../../core/i18n/bangla_numerals.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../l10n/app_localizations.dart';

/// The 4-step wizard progress header: four rounded segments where the current
/// step is wider (flex 2), completed/current segments are sage and the rest are
/// the line colour, plus a "Step N of 4" caption.
///
/// Mirrors the prototype's progress bar (`reg('addBuilding')` prog block);
/// every colour/spacing/radius comes from the design tokens.
class WizardProgress extends StatelessWidget {
  const WizardProgress({super.key, required this.step, this.totalSteps = 4});

  /// 1-based current step.
  final int step;

  /// Total step count (4 for the add-building wizard).
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final localeCode = Localizations.localeOf(context).languageCode;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        KhatirSpacing.s5,
        KhatirSpacing.s1,
        KhatirSpacing.s5,
        KhatirSpacing.s3 + 2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              for (var s = 1; s <= totalSteps; s++) ...[
                if (s > 1) const SizedBox(width: KhatirSpacing.s2 - 2),
                Expanded(
                  flex: s == step ? 2 : 1,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 6,
                    decoration: BoxDecoration(
                      color: s <= step ? KhatirColors.sage : KhatirColors.line,
                      borderRadius: BorderRadius.circular(KhatirRadius.pill),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: KhatirSpacing.s2 - 2),
          Text(
            l10n.wizard_step_x_of_4(
              BanglaNumerals.format(step, localeCode),
            ),
            style: AppTextStyles.bodySmall.copyWith(
              color: KhatirColors.muted,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
