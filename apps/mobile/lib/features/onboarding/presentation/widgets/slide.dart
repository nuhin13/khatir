import 'package:flutter/material.dart';
import 'package:khatir_tokens/khatir_tokens.dart';

import '../../../../core/theme/text_styles.dart';

/// Static content for one onboarding page. Strings are resolved from ARB by the
/// screen; colours/emoji are presentation-only and sourced from design tokens.
class OnboardingSlideData {
  const OnboardingSlideData({
    required this.emoji,
    required this.background,
    required this.accent,
    required this.accentDark,
    required this.kicker,
    required this.title,
    required this.accentLine,
    required this.body,
  });

  final String emoji;
  final Color background;
  final Color accent;
  final Color accentDark;
  final String kicker;
  final String title;
  final String accentLine;
  final String body;
}

/// A single onboarding page: a tinted circular emoji hero, a chip kicker, the
/// Bangla/English title, a handwritten accent line, and the body copy.
/// Mirrors the `intro` prototype slide composition; all values from tokens.
class OnboardingSlide extends StatelessWidget {
  const OnboardingSlide({super.key, required this.data});

  final OnboardingSlideData data;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: KhatirSpacing.s7,
        vertical: KhatirSpacing.s6,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Circular tinted emoji hero with two accent dots.
          SizedBox(
            width: 212,
            height: 212,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: data.background,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: data.accent.withValues(alpha: 0.35),
                        blurRadius: 60,
                        offset: const Offset(0, 30),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    data.emoji,
                    style: const TextStyle(fontSize: 104),
                  ),
                ),
                Positioned(
                  top: 22,
                  right: 18,
                  child: _Dot(color: data.accent, size: 22, opacity: 0.8),
                ),
                Positioned(
                  bottom: 30,
                  left: 14,
                  child: _Dot(color: data.accent, size: 13, opacity: 0.55),
                ),
              ],
            ),
          ),
          const SizedBox(height: KhatirSpacing.s6),
          // Chip kicker.
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: KhatirSpacing.s4,
              vertical: KhatirSpacing.s2,
            ),
            decoration: BoxDecoration(
              color: data.background,
              borderRadius: BorderRadius.circular(KhatirRadius.chip),
            ),
            child: Text(
              data.kicker,
              style: AppTextStyles.labelLarge.copyWith(color: data.accentDark),
            ),
          ),
          const SizedBox(height: KhatirSpacing.s3),
          // Bangla/English title.
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: AppTextStyles.headlineMedium,
          ),
          const SizedBox(height: KhatirSpacing.s1),
          // Handwritten accent line.
          Text(
            data.accentLine,
            textAlign: TextAlign.center,
            style: AppTextStyles.accent.copyWith(color: data.accentDark),
          ),
          const SizedBox(height: KhatirSpacing.s3),
          // Body copy.
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: Text(
              data.body,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: KhatirColors.mutedDk,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color, required this.size, required this.opacity});

  final Color color;
  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: opacity),
        shape: BoxShape.circle,
      ),
    );
  }
}
