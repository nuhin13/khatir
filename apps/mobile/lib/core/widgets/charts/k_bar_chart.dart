import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:khatir_tokens/khatir_tokens.dart';

import '../../i18n/bangla_numerals.dart';
import 'chart_states.dart';

/// A single labelled bar (one month / category) for [KBarChart].
class KBarDatum {
  const KBarDatum({required this.label, required this.value});

  /// Axis label drawn under the bar (e.g. a localized month abbreviation).
  final String label;

  /// Bar height value, on the same scale as the other data points.
  final double value;
}

/// Notun Din bar chart — a thin, generic wrapper over fl_chart's [BarChart].
///
/// Themed entirely from the shared design tokens (sage gradient bars, token
/// label colors); nothing here is hardcoded hex/px. The business data → chart
/// data mapping lives in the calling screen, not here.
///
/// Renders a loading shimmer placeholder when [isLoading] is true and a
/// localized empty state when [data] is empty.
class KBarChart extends StatelessWidget {
  const KBarChart({
    super.key,
    required this.data,
    required this.localeCode,
    this.maxValue,
    this.valueSuffix = '',
    this.height = 140,
    this.isLoading = false,
    this.emptyLabel,
  });

  /// The bars, in display order (left → right).
  final List<KBarDatum> data;

  /// `'bn'` or `'en'` — drives numeral rendering on the value labels.
  final String localeCode;

  /// Optional fixed axis maximum. Defaults to the largest datum (or 1).
  final double? maxValue;

  /// Suffix appended to each bar's value label (e.g. `'%'`).
  final String valueSuffix;

  /// Overall chart height.
  final double height;

  /// When true a loading placeholder is shown instead of the chart.
  final bool isLoading;

  /// Text shown when [data] is empty. Defaults to `'—'` so the widget stays
  /// l10n-agnostic; screens pass a localized string.
  final String? emptyLabel;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return ChartLoadingState(height: height);
    }
    if (data.isEmpty) {
      return ChartEmptyState(height: height, label: emptyLabel);
    }

    final top = maxValue ??
        data.map((d) => d.value).fold<double>(1, (a, b) => a > b ? a : b);

    return SizedBox(
      height: height,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: top,
          minY: 0,
          barTouchData: BarTouchData(enabled: false),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 18,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= data.length) return const SizedBox.shrink();
                  final label =
                      '${BanglaNumerals.format(data[i].value, localeCode, grouped: false)}$valueSuffix';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: KhatirSpacing.s1),
                    child: Text(
                      label,
                      style: const TextStyle(
                        color: KhatirColors.muted,
                        fontWeight: FontWeight.w700,
                        fontSize: 9,
                        fontFamily: KhatirFonts.title,
                      ),
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 20,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= data.length) return const SizedBox.shrink();
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
          barGroups: [
            for (var i = 0; i < data.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: data[i].value,
                    width: 14,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(KhatirRadius.xs * 0.7),
                    ),
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [KhatirColors.sage, KhatirColors.sageDk],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
