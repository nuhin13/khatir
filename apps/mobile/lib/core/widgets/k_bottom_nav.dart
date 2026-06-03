import 'package:flutter/material.dart';
import 'package:khatir_tokens/khatir_tokens.dart';

import '../theme/app_theme.dart';
import '../theme/text_styles.dart';

/// A single destination in [KBottomNav].
///
/// When [fab] is true the slot renders as the raised, filled accent button
/// (the center "Add" action in the prototype) rather than a plain tab.
class KBottomNavItem {
  const KBottomNavItem({
    required this.icon,
    required this.label,
    this.fab = false,
  });

  final IconData icon;
  final String label;

  /// Renders this slot as the center accent FAB (filled sage, raised, shadow).
  final bool fab;
}

/// Notun Din bottom navigation bar shared by the three role shells.
///
/// Layout mirrors `bottomnav()` in `proto/ui.js`: a [Row] of slots over a card
/// surface with a hairline top border. The active tab shows a sage-tinted
/// circle behind its icon; an optional center slot renders as a raised accent
/// FAB. Every color/radius/spacing/shadow comes from the shared design tokens.
class KBottomNav extends StatelessWidget {
  const KBottomNav({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<KBottomNavItem> items;

  /// Index of the active slot. The FAB slot is never "active".
  final int currentIndex;

  /// Fired with the tapped slot index.
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: KhatirColors.card,
        boxShadow: AppTheme.softShadow,
        border: Border(
          top: BorderSide(color: KhatirColors.line),
        ),
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
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < items.length; i++)
                _NavTile(
                  item: items[i],
                  selected: i == currentIndex && !items[i].fab,
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
    final labelColor = selected ? KhatirColors.sageDk : KhatirColors.muted;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(KhatirRadius.md),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: KhatirSpacing.s2,
          vertical: KhatirSpacing.s1,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Indicator(item: item, selected: selected),
            const SizedBox(height: KhatirSpacing.s1),
            Text(
              item.label,
              style: AppTextStyles.bodySmall.copyWith(
                color: labelColor,
                fontFamily: KhatirFonts.title,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The circular icon holder behind a slot: a 32px sage-bg disc for the active
/// tab, or a raised 44px filled-sage FAB for the center accent slot.
class _Indicator extends StatelessWidget {
  const _Indicator({required this.item, required this.selected});

  final KBottomNavItem item;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    if (item.fab) {
      return Transform.translate(
        offset: const Offset(0, -KhatirSpacing.s2),
        child: Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            color: KhatirColors.sage,
            shape: BoxShape.circle,
            boxShadow: AppTheme.sageShadow,
          ),
          child: const Icon(Icons.add, size: 21, color: KhatirColors.card),
        ),
      );
    }
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: selected ? KhatirColors.sageBg : Colors.transparent,
        shape: BoxShape.circle,
      ),
      child: Icon(
        item.icon,
        size: 20,
        color: selected ? KhatirColors.sageDk : KhatirColors.muted,
      ),
    );
  }
}
