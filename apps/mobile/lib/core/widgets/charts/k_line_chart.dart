import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:khatir_tokens/khatir_tokens.dart';

import 'chart_states.dart';

/// A single point on a [KLineChart] trend line.
class KLinePoint {
  const KLinePoint({required this.label, required this.value});

  /// Axis label drawn under the point (e.g. a localized month abbreviation).
  final String label;

  /// The point's value on the vertical scale.
  final double value;
}

/// Notun Din line chart — a thin, generic wrapper over fl_chart's
/// [LineChart] for trend series. Sage line with a soft sage-bg fill below,
/// rose accent dots; all colors from the shared design tokens.
///
/// Shows a loading placeholder when [isLoading] and a localized empty state
/// when [data] is empty. Bottom-axis labels are supplied by the caller
/// already localized.
class KLineChart extends StatelessWidget {
  const KLineChart({
    super.key,
    required this.data,
    this.height = 140,
    this.isLoading = false,
    this.emptyLabel,
  });

  /// Trend points, left → right.
  final List<KLinePoint> data;

  /// Overall chart height.
  final double height;

  /// When true a loading placeholder is shown instead of the chart.
  final bool isLoading;

  /// Text shown when [data] is empty. Defaults to an em dash.
  final String? emptyLabel;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return ChartLoadingState(height: height);
    }
    if (data.isEmpty) {
      return ChartEmptyState(height: height, label: emptyLabel);
    }

    final values = data.map((d) => d.value);
    final maxV = values.fold<double>(values.first, (a, b) => a > b ? a : b);
    final minV = values.fold<double>(values.first, (a, b) => a < b ? a : b);
    // Pad the range a touch so the line never hugs the top/bottom edge.
    final span = (maxV - minV).abs();
    final pad = span == 0 ? (maxV.abs() == 0 ? 1 : maxV.abs() * 0.1) : span * 0.15;

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          minY: minV - pad,
          maxY: maxV + pad,
          lineTouchData: const LineTouchData(enabled: false),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final i = value.round();
                  if (i < 0 || i >= data.length || i != value) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: KhatirSpacing.s2),
                    child: Text(
                      data[i].label,
                      style: const TextStyle(
                        color: KhatirColors.muted,
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                        fontFamily: KhatirFonts.body,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              isCurved: true,
              curveSmoothness: 0.32,
              color: KhatirColors.sage,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, bar, index) =>
                    FlDotCirclePainter(
                  radius: 3.5,
                  color: KhatirColors.rose,
                  strokeWidth: 2,
                  strokeColor: KhatirColors.card,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                color: KhatirColors.sageBg,
              ),
              spots: [
                for (var i = 0; i < data.length; i++)
                  FlSpot(i.toDouble(), data[i].value),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
