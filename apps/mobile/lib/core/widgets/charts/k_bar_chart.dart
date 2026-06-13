import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:khatir_tokens/khatir_tokens.dart';

import '../../i18n/bangla_numerals.dart';
import 'chart_states.dart';

/// A single labelled bar group (one month / category) for [KBarChart].
///
/// A datum always carries a primary [value]; when [secondValue] is non-null the
/// chart renders a second, side-by-side rod in the same group (a grouped/
/// two-series bar — e.g. income vs expense per month).
class KBarDatum {
  const KBarDatum({
    required this.label,
    required this.value,
    this.secondValue,
  });

  /// Axis label drawn under the bar (e.g. a localized month abbreviation).
  final String label;

  /// Primary bar height value, on the same scale as the other data points.
  final double value;

  /// Optional second-series value drawn beside [value] in the same group. When
  /// null the group renders a single bar (the original single-series layout).
  final double? secondValue;
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
    this.barColors = const [KhatirColors.sage, KhatirColors.sageDk],
    this.secondBarColors = const [KhatirColors.rose, KhatirColors.roseDk],
    this.showValueLabels = true,
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

  /// Top → bottom gradient stops for the primary rod. Defaults to the sage
  /// gradient; callers pass token colors (never inline hex).
  final List<Color> barColors;

  /// Top → bottom gradient stops for the second-series rod (used only when a
  /// datum carries a [KBarDatum.secondValue]). Defaults to the rose gradient.
  final List<Color> secondBarColors;

  /// When true (single-series default) each bar shows its value as a top label.
  /// Grouped two-series charts pass false to keep the axis uncluttered.
  final bool showValueLabels;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return ChartLoadingState(height: height);
    }
    if (data.isEmpty) {
      return ChartEmptyState(height: height, label: emptyLabel);
    }

    final top = maxValue ??
        data.fold<double>(1, (a, d) {
          final hi = (d.secondValue ?? 0) > d.value ? d.secondValue! : d.value;
          return hi > a ? hi : a;
        });
    final grouped = data.any((d) => d.secondValue != null);

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
                showTitles: showValueLabels && !grouped,
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
                barsSpace: grouped ? 4 : 0,
                barRods: [
                  BarChartRodData(
                    toY: data[i].value,
                    width: grouped ? 9 : 14,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(KhatirRadius.xs * 0.7),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: barColors,
                    ),
                  ),
                  if (data[i].secondValue != null)
                    BarChartRodData(
                      toY: data[i].secondValue!,
                      width: 9,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(KhatirRadius.xs * 0.7),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: secondBarColors,
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
