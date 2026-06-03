import 'package:flutter/material.dart';
import 'package:khatir_tokens/khatir_tokens.dart';

import '../../../../core/theme/text_styles.dart';

/// A single tappable row in the More menu, mirroring a `fieldrow` entry in the
/// `more` prototype: a round sage icon badge, a Bangla primary line + English
/// caption, and a trailing chevron.
///
/// All colors/spacing/radii come from the shared design tokens; the row never
/// hardcodes prototype hex/px.
class MoreRow extends StatelessWidget {
  const MoreRow({
    super.key,
    required this.icon,
    required this.titleBn,
    required this.titleEn,
    required this.onTap,
    this.showDivider = true,
  });

  /// Leading glyph shown inside the round badge.
  final IconData icon;

  /// Primary Bangla label.
  final String titleBn;

  /// English caption under the Bangla label.
  final String titleEn;

  /// Tap handler — routes or toggles.
  final VoidCallback onTap;

  /// Whether to draw the hairline divider under this row (false for the last
  /// row in a card).
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: KhatirSpacing.s4,
            vertical: KhatirSpacing.s3,
          ),
          decoration: BoxDecoration(
            border: showDivider
                ? const Border(
                    bottom: BorderSide(color: KhatirColors.line),
                  )
                : null,
          ),
          child: Row(
            children: [
              // Round sage icon badge.
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: KhatirColors.sageBg,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 18, color: KhatirColors.sageDk),
              ),
              const SizedBox(width: KhatirSpacing.s3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      titleBn,
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      titleEn,
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                size: 18,
                color: KhatirColors.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
