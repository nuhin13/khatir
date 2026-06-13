import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:khatir_tokens/khatir_tokens.dart';

import '../../i18n/bangla_numerals.dart';
import 'chart_states.dart';

/// A single slice of a [KDonutChart] (e.g. occupied / vacant / pending).
class KDonutSlice {
  const KDonutSlice({required this.value, required this.color});

  /// Raw value; slices are drawn proportional to the sum of all values.
  final double value;

  /// Slice color — pass a token color (e.g. [KhatirColors.sage]).
  final Color color;
}

/// Notun Din donut chart — a thin, generic wrapper over fl_chart's
/// [PieChart] with a hollow center that renders a primary value and an
/// optional sublabel (mirroring the dashboard occupancy ring).
///
/// Themed entirely from the shared design tokens; the caller supplies slice
/// colors (token values) and the already-localized center labels. Shows a
/// loading placeholder when [isLoading] and an empty state when [slices] is
/// empty or sums to zero.
class KDonutChart extends StatelessWidget {
  const KDonutChart({
    super.key,
    required this.slices,
    required this.centerLabel,
    this.centerSublabel,
    this.size = 100,
    this.strokeWidth = 12,
    this.isLoading = false,
    this.emptyLabel,
  });

  /// Slices in draw order; each contributes a proportional arc.
  final List<KDonutSlice> slices;

  /// Large value drawn in the donut hole (e.g. `'৭৮%'`).
  final String centerLabel;

  /// Optional smaller line below [centerLabel] (e.g. `'১১/১৪'`).
  final String? centerSublabel;

  /// Outer diameter of the ring.
  final double size;

  /// Thickness of the ring.
  final double strokeWidth;

  /// When true a loading placeholder is shown instead of the chart.
  final bool isLoading;

  /// Text shown when there is no data. Defaults to an em dash.
  final String? emptyLabel;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return ChartLoadingState(height: size, width: size);
    }

    final total = slices.fold<double>(0, (a, s) => a + s.value);
    if (slices.isEmpty || total <= 0) {
      return ChartEmptyState(height: size, width: size, label: emptyLabel);
    }

    final radius = strokeWidth;
    final centerSpace = (size - strokeWidth * 2) / 2;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              startDegreeOffset: -90,
              sectionsSpace: 0,
              centerSpaceRadius: centerSpace,
              pieTouchData: PieTouchData(enabled: false),
              sections: [
                for (final s in slices)
                  PieChartSectionData(
                    value: s.value,
                    color: s.color,
                    radius: radius,
                    showTitle: false,
                  ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                centerLabel,
                style: const TextStyle(
                  fontFamily: KhatirFonts.title,
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                  height: 1,
                  color: KhatirColors.ink,
                ),
              ),
              if (centerSublabel != null)
                Padding(
                  padding: const EdgeInsets.only(top: KhatirSpacing.s1 * 0.5),
                  child: Text(
                    centerSublabel!,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 9.5,
                      color: KhatirColors.muted,
                      fontFamily: KhatirFonts.body,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// Convenience builder for the common single-percentage ring (sage filled
  /// arc on a sage-bg track), with a localized `'NN%'` center label.
  ///
  /// [percent] is 0–100. Numerals are rendered per [localeCode].
  factory KDonutChart.percentage({
    Key? key,
    required double percent,
    required String localeCode,
    String? centerSublabel,
    double size = 100,
    double strokeWidth = 12,
    bool isLoading = false,
    String? emptyLabel,
  }) {
    final clamped = percent.clamp(0, 100).toDouble();
    final label =
        '${BanglaNumerals.format(clamped.round(), localeCode, grouped: false)}%';
    return KDonutChart(
      key: key,
      slices: [
        KDonutSlice(value: clamped, color: KhatirColors.sage),
        KDonutSlice(value: 100 - clamped, color: KhatirColors.sageBg),
      ],
      centerLabel: label,
      centerSublabel: centerSublabel,
      size: size,
      strokeWidth: strokeWidth,
      isLoading: isLoading,
      emptyLabel: emptyLabel,
    );
  }
}
