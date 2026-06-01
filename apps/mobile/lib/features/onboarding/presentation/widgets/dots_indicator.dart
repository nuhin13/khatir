import 'package:flutter/material.dart';
import 'package:khatir_tokens/khatir_tokens.dart';

/// Page-progress dots for the onboarding slides. The active dot stretches into
/// a pill tinted with the active slide's accent colour; matches the `intro`
/// prototype. All dimensions/colours come from design tokens.
class DotsIndicator extends StatelessWidget {
  const DotsIndicator({
    super.key,
    required this.count,
    required this.activeIndex,
    required this.activeColor,
  });

  final int count;
  final int activeIndex;
  final Color activeColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (i) {
        final active = i == activeIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.only(right: KhatirSpacing.s2 - 2),
          width: active ? 28 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active ? activeColor : KhatirColors.line,
            borderRadius: BorderRadius.circular(KhatirRadius.xs / 2.5),
          ),
        );
      }),
    );
  }
}
