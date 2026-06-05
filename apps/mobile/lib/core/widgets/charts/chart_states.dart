import 'package:flutter/material.dart';
import 'package:khatir_tokens/khatir_tokens.dart';

/// Loading placeholder shared by the Notun Din chart widgets — a soft
/// sage-tinted box with a centered spinner, sized to match the chart it
/// replaces. Themed entirely from the shared design tokens.
class ChartLoadingState extends StatelessWidget {
  const ChartLoadingState({super.key, required this.height, this.width});

  final double height;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: KhatirColors.sageBg,
        borderRadius: BorderRadius.circular(KhatirRadius.tile),
      ),
      alignment: Alignment.center,
      child: const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(KhatirColors.sage),
        ),
      ),
    );
  }
}

/// Empty-state placeholder shared by the Notun Din chart widgets.
///
/// [label] is supplied by the calling screen (already localized); the widget
/// itself stays l10n-agnostic and falls back to an em dash.
class ChartEmptyState extends StatelessWidget {
  const ChartEmptyState({
    super.key,
    required this.height,
    this.width,
    this.label,
  });

  final double height;
  final double? width;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: KhatirColors.sageBg,
        borderRadius: BorderRadius.circular(KhatirRadius.tile),
      ),
      alignment: Alignment.center,
      child: Text(
        label ?? '—',
        style: const TextStyle(
          color: KhatirColors.muted,
          fontWeight: FontWeight.w600,
          fontSize: 12,
          fontFamily: KhatirFonts.body,
        ),
      ),
    );
  }
}
