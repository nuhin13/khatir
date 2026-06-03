import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:khatir_mobile/core/widgets/k_map_picker.dart';
import 'package:khatir_mobile/l10n/app_localizations.dart';
import 'package:latlong2/latlong.dart';

/// Wraps [child] in the minimum app scaffolding (MaterialApp + localizations)
/// the widget needs to build under test.
Widget _host(Widget child) {
  return MaterialApp(
    locale: const Locale('en'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    home: Scaffold(body: child),
  );
}

void main() {
  group('coordsAsTextGeocoder', () {
    test('renders coordinates as N/E text', () async {
      final out = await coordsAsTextGeocoder(const LatLng(23.8103, 90.4125));
      expect(out, '23.8103°N, 90.4125°E');
    });

    test('uses S/W for negative coordinates', () async {
      final out = await coordsAsTextGeocoder(const LatLng(-12.5, -45.25));
      expect(out, '12.5000°S, 45.2500°W');
    });
  });

  testWidgets('KMapPicker renders OSM tiles, attribution and tap hint',
      (tester) async {
    await tester.pumpWidget(_host(const KMapPicker()));
    await tester.pump();

    // OSM tile layer is present.
    expect(find.byType(FlutterMap), findsOneWidget);
    expect(find.byType(TileLayer), findsOneWidget);

    // Required OSM attribution overlay is shown.
    expect(find.byType(RichAttributionWidget), findsOneWidget);

    // Empty state: "tap to drop pin" hint, no marker yet.
    expect(find.text('Tap to drop pin'), findsOneWidget);
    expect(find.byType(MarkerLayer), findsNothing);
  });

  testWidgets('KMapPicker with an initial pin shows a marker and no hint',
      (tester) async {
    await tester.pumpWidget(
      _host(const KMapPicker(initialPin: LatLng(23.8103, 90.4125))),
    );
    await tester.pump();

    expect(find.byType(MarkerLayer), findsOneWidget);
    expect(find.text('Tap to drop pin'), findsNothing);
  });

  testWidgets('tapping the map drops a pin and emits LatLng + address',
      (tester) async {
    LatLng? emitted;
    String? address;

    await tester.pumpWidget(
      _host(
        KMapPicker(
          onChanged: (v) => emitted = v,
          onAddressResolved: (a) => address = a,
        ),
      ),
    );
    await tester.pump();

    // Tap the centre of the map.
    await tester.tap(find.byType(FlutterMap));
    await tester.pump(); // run setState
    await tester.pump(); // resolve the (async) geocoder future

    expect(emitted, isA<LatLng>());
    expect(emitted, isNotNull);
    expect(address, isNotNull);
    expect(address, contains('°'));

    // Pin dropped -> hint gone, marker shown.
    await tester.pump();
    expect(find.byType(MarkerLayer), findsOneWidget);
    expect(find.text('Tap to drop pin'), findsNothing);
  });
}
