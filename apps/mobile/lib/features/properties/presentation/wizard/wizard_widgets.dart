import 'package:flutter/material.dart';
import 'package:khatir_tokens/khatir_tokens.dart';

import '../../../../core/theme/text_styles.dart';

/// Emoji hero used at the top of each wizard step: a large emoji, an English
/// headline and a Bangla subtitle. Mirrors the prototype's `emojiHero(...)`.
class WizardHero extends StatelessWidget {
  const WizardHero({
    super.key,
    required this.emoji,
    required this.title,
    required this.subtitle,
  });

  final String emoji;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 40)),
        const SizedBox(height: KhatirSpacing.s2),
        Text(
          title,
          style: AppTextStyles.titleLarge.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: AppTextStyles.bodySmall.copyWith(color: KhatirColors.muted),
        ),
      ],
    );
  }
}

/// A labelled form field block: a label (with an optional required ★) above
/// [child], and an optional inline error message below it.
class WizardField extends StatelessWidget {
  const WizardField({
    super.key,
    required this.label,
    required this.child,
    this.required = false,
    this.errorText,
  });

  final String label;
  final Widget child;
  final bool required;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final labelStyle = AppTextStyles.labelLarge.copyWith(
      color: KhatirColors.mutedDk,
      fontWeight: FontWeight.w700,
      fontSize: 12.5,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Keep the label as a plain Text (not a RichText span) so it stays a
        // findable, accessible string; the required ★ is a separate leading
        // glyph rather than part of the label run.
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (required)
              Text(
                '★ ',
                style: labelStyle.copyWith(color: KhatirColors.rose),
              ),
            Text(label, style: labelStyle),
          ],
        ),
        const SizedBox(height: KhatirSpacing.s2 - 2),
        child,
        if (errorText != null) ...[
          const SizedBox(height: KhatirSpacing.s1 + 2),
          Text(
            errorText!,
            style: AppTextStyles.bodySmall.copyWith(
              color: KhatirColors.danger,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

/// Shared text-field decoration for the wizard: cream-filled, pill-soft rounded
/// box with a sage focus ring. All values from the design tokens.
InputDecoration wizardInputDecoration(String hint) {
  OutlineInputBorder border(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(KhatirRadius.tile),
        borderSide: BorderSide(color: color, width: width),
      );

  return InputDecoration(
    hintText: hint,
    hintStyle: AppTextStyles.bodyMedium.copyWith(color: KhatirColors.muted),
    filled: true,
    fillColor: KhatirColors.card,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: KhatirSpacing.s4,
      vertical: KhatirSpacing.s3 + 2,
    ),
    enabledBorder: border(KhatirColors.line),
    focusedBorder: border(KhatirColors.sage, 1.5),
    border: border(KhatirColors.line),
  );
}

/// Full-width sage primary button used at the foot of each wizard step. An
/// optional trailing arrow matches the prototype's "Next →" affordance.
class WizardPrimaryButton extends StatelessWidget {
  const WizardPrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
    this.showArrow = true,
  });

  final String label;
  final VoidCallback onTap;
  final bool showArrow;

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
          padding: const EdgeInsets.symmetric(
            horizontal: KhatirSpacing.s6,
            vertical: KhatirSpacing.s4,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: AppTextStyles.labelLarge.copyWith(
                  color: KhatirColors.card,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (showArrow) ...[
                const SizedBox(width: KhatirSpacing.s2),
                const Icon(Icons.arrow_forward,
                    size: 16, color: KhatirColors.card),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Full-width soft (sage-bg) secondary button — e.g. the "pick on map" toggle.
class WizardSoftButton extends StatelessWidget {
  const WizardSoftButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(KhatirRadius.button);
    return Material(
      color: KhatirColors.sageBg,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: KhatirSpacing.s5,
            vertical: KhatirSpacing.s3 + 2,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: KhatirColors.sageDk),
                const SizedBox(width: KhatirSpacing.s2),
              ],
              Flexible(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: KhatirColors.sageDk,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
