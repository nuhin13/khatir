import 'package:flutter/material.dart';
import 'package:khatir_tokens/khatir_tokens.dart';

import '../theme/text_styles.dart';
import 'k_card.dart';

/// Direction of a [KMetricCard] trend indicator.
enum KMetricTrend {
  /// Value improved versus the comparison period (sage ↑).
  up,

  /// Value worsened versus the comparison period (rose ↓).
  down,

  /// Value held steady (muted →).
  flat,
}

/// Notun Din KPI card — a single metric (collection rate %, occupancy %, an
/// amount, …) shown as an icon badge, a label and a large value, with an
/// optional trend pill.
///
/// Deliberately generic: it knows nothing about collection or occupancy, so the
/// dashboard and home can reuse it for any KPI. All colors / spacing / radii /
/// fonts come from the shared design tokens — no inline hex or px.
class KMetricCard extends StatelessWidget {
  const KMetricCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.trend,
    this.trendLabel,
    this.accent = KhatirColors.sage,
    this.accentBackground = KhatirColors.sageBg,
    this.onTap,
  });

  /// Leading glyph shown inside the tinted badge.
  final IconData icon;

  /// Short caption describing the metric (e.g. "Collection rate").
  final String label;

  /// Pre-formatted metric value (e.g. "78%", "৳71,000"). Formatting/locale is
  /// the caller's responsibility so this widget stays presentation-only.
  final String value;

  /// Optional trend direction; when null no trend pill is rendered.
  final KMetricTrend? trend;

  /// Optional text shown beside the trend arrow (e.g. "12%").
  final String? trendLabel;

  /// Accent color for the icon glyph and trend.
  final Color accent;

  /// Background tint behind the icon badge.
  final Color accentBackground;

  /// Optional tap handler (forwarded to the underlying [KCard]).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return KCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _IconBadge(icon: icon, accent: accent, background: accentBackground),
          const SizedBox(height: KhatirSpacing.s3),
          Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: KhatirColors.muted,
            ),
          ),
          const SizedBox(height: KhatirSpacing.s1),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: AppTextStyles.headlineMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (trend != null) ...[
                const SizedBox(width: KhatirSpacing.s2),
                _TrendPill(trend: trend!, label: trendLabel),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({
    required this.icon,
    required this.accent,
    required this.background,
  });

  final IconData icon;
  final Color accent;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: KhatirSpacing.s8,
      height: KhatirSpacing.s8,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(KhatirRadius.tile),
      ),
      child: Icon(icon, size: KhatirSpacing.s5, color: accent),
    );
  }
}

class _TrendPill extends StatelessWidget {
  const _TrendPill({required this.trend, this.label});

  final KMetricTrend trend;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final (color, glyph) = switch (trend) {
      KMetricTrend.up => (KhatirColors.sageDk, Icons.arrow_upward),
      KMetricTrend.down => (KhatirColors.roseDk, Icons.arrow_downward),
      KMetricTrend.flat => (KhatirColors.mutedDk, Icons.arrow_forward),
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(glyph, size: KhatirSpacing.s4, color: color),
        if (label != null && label!.isNotEmpty) ...[
          const SizedBox(width: KhatirSpacing.s1),
          Text(
            label!,
            style: AppTextStyles.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    );
  }
}
