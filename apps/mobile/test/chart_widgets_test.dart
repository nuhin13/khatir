import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khatir_mobile/core/widgets/charts/chart_states.dart';
import 'package:khatir_mobile/core/widgets/charts/k_bar_chart.dart';
import 'package:khatir_mobile/core/widgets/charts/k_donut_chart.dart';
import 'package:khatir_mobile/core/widgets/charts/k_line_chart.dart';
import 'package:khatir_tokens/khatir_tokens.dart';

/// Pumps [child] inside a sized Scaffold so the charts have bounded
/// constraints to lay out within.
Widget _harness(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(width: 320, child: child),
      ),
    ),
  );
}

void main() {
  group('KBarChart', () {
    testWidgets('renders a BarChart with data', (tester) async {
      await tester.pumpWidget(
        _harness(
          const KBarChart(
            data: [
              KBarDatum(label: 'ডিসে', value: 60),
              KBarDatum(label: 'জানু', value: 72),
              KBarDatum(label: 'ফেব', value: 88),
            ],
            localeCode: 'bn',
            valueSuffix: '%',
          ),
        ),
      );
      expect(find.byType(BarChart), findsOneWidget);
      expect(find.byType(ChartEmptyState), findsNothing);
      expect(find.byType(ChartLoadingState), findsNothing);
    });

    testWidgets('shows empty state with no data', (tester) async {
      await tester.pumpWidget(
        _harness(
          const KBarChart(
            data: [],
            localeCode: 'bn',
            emptyLabel: 'কোনো তথ্য নেই',
          ),
        ),
      );
      expect(find.byType(BarChart), findsNothing);
      expect(find.byType(ChartEmptyState), findsOneWidget);
      expect(find.text('কোনো তথ্য নেই'), findsOneWidget);
    });

    testWidgets('shows loading state', (tester) async {
      await tester.pumpWidget(
        _harness(
          const KBarChart(data: [], localeCode: 'bn', isLoading: true),
        ),
      );
      expect(find.byType(ChartLoadingState), findsOneWidget);
      expect(find.byType(BarChart), findsNothing);
    });

    testWidgets('value labels use Bangla numerals', (tester) async {
      await tester.pumpWidget(
        _harness(
          const KBarChart(
            data: [KBarDatum(label: 'মে', value: 88)],
            localeCode: 'bn',
            valueSuffix: '%',
          ),
        ),
      );
      // 88 -> ৮৮ in Bengali digits.
      expect(find.text('৮৮%'), findsOneWidget);
    });
  });

  group('KDonutChart', () {
    testWidgets('renders a PieChart with center label', (tester) async {
      await tester.pumpWidget(
        _harness(
          const KDonutChart(
            slices: [
              KDonutSlice(value: 11, color: KhatirColors.sage),
              KDonutSlice(value: 3, color: KhatirColors.rose),
            ],
            centerLabel: '৭৮%',
            centerSublabel: '১১/১৪',
          ),
        ),
      );
      expect(find.byType(PieChart), findsOneWidget);
      expect(find.text('৭৮%'), findsOneWidget);
      expect(find.text('১১/১৪'), findsOneWidget);
    });

    testWidgets('empty when slices sum to zero', (tester) async {
      await tester.pumpWidget(
        _harness(
          const KDonutChart(
            slices: [KDonutSlice(value: 0, color: KhatirColors.sage)],
            centerLabel: '০%',
            emptyLabel: '—',
          ),
        ),
      );
      expect(find.byType(PieChart), findsNothing);
      expect(find.byType(ChartEmptyState), findsOneWidget);
    });

    testWidgets('percentage factory localizes the center label',
        (tester) async {
      await tester.pumpWidget(
        _harness(
          KDonutChart.percentage(percent: 78, localeCode: 'bn'),
        ),
      );
      expect(find.byType(PieChart), findsOneWidget);
      expect(find.text('৭৮%'), findsOneWidget);
    });

    testWidgets('percentage factory renders English numerals for en',
        (tester) async {
      await tester.pumpWidget(
        _harness(
          KDonutChart.percentage(percent: 78, localeCode: 'en'),
        ),
      );
      expect(find.text('78%'), findsOneWidget);
    });

    testWidgets('shows loading state', (tester) async {
      await tester.pumpWidget(
        _harness(
          const KDonutChart(
            slices: [],
            centerLabel: '',
            isLoading: true,
          ),
        ),
      );
      expect(find.byType(ChartLoadingState), findsOneWidget);
      expect(find.byType(PieChart), findsNothing);
    });
  });

  group('KLineChart', () {
    testWidgets('renders a LineChart with data', (tester) async {
      await tester.pumpWidget(
        _harness(
          const KLineChart(
            data: [
              KLinePoint(label: 'ডিসে', value: 60),
              KLinePoint(label: 'জানু', value: 72),
              KLinePoint(label: 'ফেব', value: 68),
            ],
          ),
        ),
      );
      expect(find.byType(LineChart), findsOneWidget);
      expect(find.byType(ChartEmptyState), findsNothing);
    });

    testWidgets('shows empty state with no data', (tester) async {
      await tester.pumpWidget(
        _harness(
          const KLineChart(data: [], emptyLabel: 'কোনো তথ্য নেই'),
        ),
      );
      expect(find.byType(LineChart), findsNothing);
      expect(find.byType(ChartEmptyState), findsOneWidget);
      expect(find.text('কোনো তথ্য নেই'), findsOneWidget);
    });

    testWidgets('shows loading state', (tester) async {
      await tester.pumpWidget(
        _harness(const KLineChart(data: [], isLoading: true)),
      );
      expect(find.byType(ChartLoadingState), findsOneWidget);
      expect(find.byType(LineChart), findsNothing);
    });

    testWidgets('handles a flat (single-value) series without error',
        (tester) async {
      await tester.pumpWidget(
        _harness(
          const KLineChart(
            data: [
              KLinePoint(label: 'a', value: 50),
              KLinePoint(label: 'b', value: 50),
            ],
          ),
        ),
      );
      expect(find.byType(LineChart), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
