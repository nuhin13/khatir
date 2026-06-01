import 'package:flutter/material.dart';
import 'package:khatir_tokens/khatir_tokens.dart';

import '../theme/app_theme.dart';
import '../theme/text_styles.dart';

/// A single destination in [KBottomNav].
class KBottomNavItem {
  const KBottomNavItem({required this.icon, required this.label});
  final IconData icon;
  final String label;
}

/// Notun Din bottom navigation bar shared by the three role shells.
/// Surface, radii, colors and shadow all come from the shared design tokens.
class KBottomNav extends StatelessWidget {
  const KBottomNav({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<KBottomNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: KhatirColors.card,
        boxShadow: AppTheme.softShadow,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: KhatirSpacing.s3,
            vertical: KhatirSpacing.s2,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (var i = 0; i < items.length; i++)
                _NavTile(
                  item: items[i],
                  selected: i == currentIndex,
                  onTap: () => onTap(i),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final KBottomNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? KhatirColors.sageDk : KhatirColors.muted;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(KhatirRadius.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: KhatirSpacing.s3,
          vertical: KhatirSpacing.s2,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(item.icon, size: 24, color: color),
            const SizedBox(height: KhatirSpacing.s1),
            Text(
              item.label,
              style: AppTextStyles.bodySmall.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}
