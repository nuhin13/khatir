import 'package:flutter/material.dart';
import 'package:khatir_tokens/khatir_tokens.dart';

import '../theme/app_theme.dart';

/// Notun Din card — white surface, large rounded corners (radius 22) and a
/// soft shadow. All values are sourced from the shared design tokens.
class KCard extends StatelessWidget {
  const KCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(KhatirSpacing.s5),
    this.onTap,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(KhatirRadius.card);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: KhatirColors.card,
        borderRadius: radius,
        boxShadow: AppTheme.softShadow,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
