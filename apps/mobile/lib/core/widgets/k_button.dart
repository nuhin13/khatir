import 'package:flutter/material.dart';
import 'package:khatir_tokens/khatir_tokens.dart';

import '../theme/text_styles.dart';

/// Notun Din primary button — pill shape (radius 999), sage fill.
/// All visual values come from the shared design tokens.
class KButton extends StatelessWidget {
  const KButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final child = icon == null
        ? Text(label)
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: KhatirSpacing.s2),
              Text(label),
            ],
          );

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: KhatirColors.sage,
        foregroundColor: KhatirColors.cream,
        elevation: 0,
        padding: const EdgeInsets.symmetric(
          horizontal: KhatirSpacing.s6,
          vertical: KhatirSpacing.s4,
        ),
        textStyle: AppTextStyles.labelLarge,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(KhatirRadius.button),
        ),
      ),
      child: child,
    );
  }
}
