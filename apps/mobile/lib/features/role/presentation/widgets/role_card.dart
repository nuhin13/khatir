import 'package:flutter/material.dart';
import 'package:khatir_tokens/khatir_tokens.dart';

import '../../../../core/theme/text_styles.dart';

/// A single selectable role card on the role chooser (T-005), mirroring a
/// `ROLE_CARDS` entry in the `roleChooser` prototype: a round emoji avatar, the
/// Bangla + handwritten English name, a one-line description, perk chips, and an
/// optional "most common" badge for the recommended role.
///
/// All colors/spacing/radii come from [KhatirColors]/[KhatirSpacing]/
/// [KhatirRadius]; the card's accent palette is passed in by the screen so the
/// per-role coloring (sage / butter / rose) stays data-driven.
class RoleCard extends StatelessWidget {
  const RoleCard({
    super.key,
    required this.emoji,
    required this.nameBn,
    required this.nameEn,
    required this.description,
    required this.perks,
    required this.background,
    required this.accent,
    required this.accentDark,
    required this.onTap,
    this.mostCommonLabel,
    this.enabled = true,
  });

  /// Emoji shown in the round avatar (🏠 / 🏢 / 👤).
  final String emoji;

  /// Bangla role name (primary title).
  final String nameBn;

  /// English role name (handwritten accent line).
  final String nameEn;

  /// One-line bilingual description.
  final String description;

  /// Perk chip labels.
  final List<String> perks;

  /// Card surface tint for this role.
  final Color background;

  /// Card accent (border for the recommended card).
  final Color accent;

  /// Darker accent for the English name, chips, badge, and trailing arrow.
  final Color accentDark;

  /// Tap handler — selects this role.
  final VoidCallback onTap;

  /// "Most common ⭐" badge copy; when null the badge is hidden (only the
  /// recommended role shows it).
  final String? mostCommonLabel;

  /// When false the card is non-interactive (e.g. while a selection persists).
  final bool enabled;

  bool get _isRecommended => mostCommonLabel != null;

  @override
  Widget build(BuildContext context) {
    final card = Material(
      color: background,
      borderRadius: BorderRadius.circular(KhatirRadius.card),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(KhatirRadius.card),
        child: Container(
          padding: const EdgeInsets.all(KhatirSpacing.s4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(KhatirRadius.card),
            border: Border.all(
              color: _isRecommended ? accent : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Round emoji avatar.
                  Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      color: KhatirColors.card,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: accentDark.withValues(alpha: 0.35),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      emoji,
                      style: const TextStyle(fontSize: 30),
                    ),
                  ),
                  const SizedBox(width: KhatirSpacing.s3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          nameBn,
                          style: AppTextStyles.titleMedium.copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: KhatirSpacing.s1),
                        Text(
                          nameEn,
                          style: AppTextStyles.accent.copyWith(
                            color: accentDark,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: KhatirSpacing.s1),
                        Text(
                          description,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: KhatirColors.mutedDk,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: KhatirSpacing.s2),
                  Icon(Icons.arrow_forward, size: 20, color: accentDark),
                ],
              ),
              const SizedBox(height: KhatirSpacing.s3),
              const Divider(
                height: 1,
                thickness: 1,
                color: KhatirColors.line,
              ),
              const SizedBox(height: KhatirSpacing.s3),
              Wrap(
                spacing: KhatirSpacing.s2,
                runSpacing: KhatirSpacing.s2,
                children: [
                  for (final perk in perks)
                    _PerkChip(label: perk, color: accentDark),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (!_isRecommended) return card;

    // Recommended role: overlay the "most common ⭐" badge near the top-right.
    return Stack(
      clipBehavior: Clip.none,
      children: [
        card,
        Positioned(
          top: -10,
          right: KhatirSpacing.s4,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: KhatirSpacing.s3,
              vertical: KhatirSpacing.s1,
            ),
            decoration: BoxDecoration(
              color: accentDark,
              borderRadius: BorderRadius.circular(KhatirRadius.pill),
            ),
            child: Text(
              mostCommonLabel!,
              style: AppTextStyles.labelLarge.copyWith(
                color: KhatirColors.cream,
                fontFamily: KhatirFonts.title,
                fontWeight: FontWeight.w800,
                fontSize: 10,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A perk chip: a pill with a check glyph and the perk label, tinted with the
/// role's dark accent.
class _PerkChip extends StatelessWidget {
  const _PerkChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: KhatirSpacing.s3,
        vertical: KhatirSpacing.s1,
      ),
      decoration: BoxDecoration(
        color: KhatirColors.card.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(KhatirRadius.chip),
      ),
      child: Text(
        '✓ $label',
        style: AppTextStyles.labelLarge.copyWith(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
