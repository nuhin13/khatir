import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khatir_mobile/features/placeholder/presentation/screens/placeholder_screen.dart';

void main() {
  testWidgets('PlaceholderScreen renders the Khatir title', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: PlaceholderScreen()),
    );

    expect(find.text('Khatir'), findsOneWidget);
  });
}
