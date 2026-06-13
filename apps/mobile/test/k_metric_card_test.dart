import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khatir_mobile/core/widgets/k_metric_card.dart';
import 'package:khatir_tokens/khatir_tokens.dart';

/// Pumps [child] inside a sized Scaffold so the card has bounded constraints.
Widget _harness(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: Center(child: SizedBox(width: 200, child: child)),
    ),
  );
}

void main() {
  group('KMetricCard', () {
    testWidgets('renders value and label', (tester) async {
      await tester.pumpWidget(
        _harness(
          const KMetricCard(
            icon: Icons.show_chart,
            label: 'Collection rate',
            value: '78%',
          ),
        ),
      );

      expect(find.text('78%'), findsOneWidget);
      expect(find.text('Collection rate'), findsOneWidget);
      expect(find.byIcon(Icons.show_chart), findsOneWidget);
    });

    testWidgets('renders an amount value (generic, not collection-specific)',
        (tester) async {
      await tester.pumpWidget(
        _harness(
          const KMetricCard(
            icon: Icons.payments,
            label: 'Income this month',
            value: '৳71,000',
            accent: KhatirColors.butterDk,
            accentBackground: KhatirColors.butterBg,
          ),
        ),
      );

      expect(find.text('৳71,000'), findsOneWidget);
      expect(find.text('Income this month'), findsOneWidget);
    });

    testWidgets('shows an upward trend pill with its label', (tester) async {
      await tester.pumpWidget(
        _harness(
          const KMetricCard(
            icon: Icons.pie_chart,
            label: 'Occupancy',
            value: '78%',
            trend: KMetricTrend.up,
            trendLabel: '12%',
          ),
        ),
      );

      expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
      expect(find.text('12%'), findsOneWidget);
    });

    testWidgets('shows a downward trend arrow', (tester) async {
      await tester.pumpWidget(
        _harness(
          const KMetricCard(
            icon: Icons.pie_chart,
            label: 'Occupancy',
            value: '60%',
            trend: KMetricTrend.down,
          ),
        ),
      );

      expect(find.byIcon(Icons.arrow_downward), findsOneWidget);
    });

    testWidgets('renders no trend pill when trend is null', (tester) async {
      await tester.pumpWidget(
        _harness(
          const KMetricCard(
            icon: Icons.show_chart,
            label: 'Collection rate',
            value: '78%',
          ),
        ),
      );

      expect(find.byIcon(Icons.arrow_upward), findsNothing);
      expect(find.byIcon(Icons.arrow_downward), findsNothing);
      expect(find.byIcon(Icons.arrow_forward), findsNothing);
    });

    testWidgets('forwards taps via onTap', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        _harness(
          KMetricCard(
            icon: Icons.show_chart,
            label: 'Collection rate',
            value: '78%',
            onTap: () => tapped = true,
          ),
        ),
      );

      await tester.tap(find.byType(KMetricCard));
      expect(tapped, isTrue);
    });
  });
}
