import 'package:flutter/material.dart';
import 'package:khatir_tokens/khatir_tokens.dart';

import '../theme/text_styles.dart';

/// Notun Din chip — pill-shaped tag with a tinted background.
/// Colors/radii come from the shared design tokens.
class KChip extends StatelessWidget {
  const KChip({
    super.key,
    required this.label,
    this.background = KhatirColors.sageBg,
    this.foreground = KhatirColors.sageDk,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: KhatirSpacing.s3,
        vertical: KhatirSpacing.s1,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(KhatirRadius.chip),
      ),
      child: Text(
        label,
        style: AppTextStyles.bodySmall.copyWith(
          color: foreground,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
