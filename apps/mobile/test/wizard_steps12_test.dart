import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khatir_mobile/core/config/public_config_provider.dart';
import 'package:khatir_mobile/features/properties/data/models/property_enums.dart';
import 'package:khatir_mobile/features/properties/presentation/wizard/add_building_controller.dart';
import 'package:khatir_mobile/features/properties/presentation/wizard/wizard_host.dart';
import 'package:khatir_mobile/l10n/app_localizations.dart';
import 'package:latlong2/latlong.dart';

/// Mounts the [WizardHost] under a minimal localized app with a fixed
/// [publicConfig] so the area chips are deterministic.
Widget _host({PublicConfig? config}) {
  return ProviderScope(
    overrides: [
      if (config != null)
        publicConfigProvider.overrideWith((ref) async => config),
    ],
    child: const MaterialApp(
      locale: Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: WizardHost(),
    ),
  );
}

void main() {
  late AppLocalizations en;

  setUp(() async {
    en = await AppLocalizations.delegate.load(const Locale('en'));
  });

  const twoAreas = PublicConfig(areaOptions: [Area.uttara, Area.mirpur]);

  testWidgets('step 1 renders name field and area chips from config',
      (tester) async {
    await tester.pumpWidget(_host(config: twoAreas));
    await tester.pumpAndSettle();

    expect(find.text(en.wizard_title_name), findsOneWidget);
    expect(find.text(en.building_name), findsOneWidget);
    // Area chips from the (overridden) config — exactly the two we seeded.
    expect(find.text(en.area_uttara), findsOneWidget);
    expect(find.text(en.area_mirpur), findsOneWidget);
    expect(find.text(en.area_gulshan), findsNothing);
    // Step 1 of 4.
    expect(find.text(en.wizard_step_x_of_4('1')), findsOneWidget);
  });

  testWidgets('cannot advance from step 1 without a name', (tester) async {
    await tester.pumpWidget(_host(config: twoAreas));
    await tester.pumpAndSettle();

    // Pick an area but leave the name blank, then try Next.
    await tester.tap(find.text(en.area_mirpur));
    await tester.pump();
    await tester.tap(find.text(en.wizard_next));
    await tester.pumpAndSettle();

    // Still on step 1, with the name error shown.
    expect(find.text(en.wizard_title_name), findsOneWidget);
    expect(find.text(en.wizard_err_name), findsOneWidget);
  });

  testWidgets('cannot advance from step 1 without an area', (tester) async {
    await tester.pumpWidget(_host(config: twoAreas));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextField).first,
      'করিম মঞ্জিল',
    );
    await tester.pump();
    await tester.tap(find.text(en.wizard_next));
    await tester.pumpAndSettle();

    expect(find.text(en.wizard_title_name), findsOneWidget);
    expect(find.text(en.wizard_err_area), findsOneWidget);
  });

  testWidgets('valid step 1 advances to step 2', (tester) async {
    await tester.pumpWidget(_host(config: twoAreas));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'করিম মঞ্জিল');
    await tester.pump();
    await tester.tap(find.text(en.area_mirpur));
    await tester.pump();
    await tester.tap(find.text(en.wizard_next));
    await tester.pumpAndSettle();

    // On step 2 now.
    expect(find.text(en.wizard_title_address), findsOneWidget);
    expect(find.text(en.building_address), findsOneWidget);
    expect(find.text(en.wizard_step_x_of_4('2')), findsOneWidget);
  });

  testWidgets('step 2 requires an address before advancing', (tester) async {
    await tester.pumpWidget(_host(config: twoAreas));
    await tester.pumpAndSettle();

    // Advance to step 2.
    await tester.enterText(find.byType(TextField).first, 'করিম মঞ্জিল');
    await tester.pump();
    await tester.tap(find.text(en.area_mirpur));
    await tester.pump();
    await tester.tap(find.text(en.wizard_next));
    await tester.pumpAndSettle();

    // Try to advance with a blank address.
    await tester.tap(find.text(en.wizard_next_units));
    await tester.pumpAndSettle();

    expect(find.text(en.wizard_err_address), findsOneWidget);
  });

  testWidgets('dropping a map pin fills the (editable) address', (tester) async {
    await tester.pumpWidget(_host(config: twoAreas));
    await tester.pumpAndSettle();

    // Advance to step 2.
    await tester.enterText(find.byType(TextField).first, 'করিম মঞ্জিল');
    await tester.pump();
    await tester.tap(find.text(en.area_mirpur));
    await tester.pump();
    await tester.tap(find.text(en.wizard_next));
    await tester.pumpAndSettle();

    // Open the map and tap it to drop a pin.
    await tester.tap(find.text(en.wizard_pick_on_map));
    await tester.pumpAndSettle();
    expect(find.byType(FlutterMap), findsOneWidget);

    await tester.tap(find.byType(FlutterMap));
    await tester.pump(); // setState (pin)
    await tester.pump(); // resolve geocoder future
    await tester.pump();

    // Address field is now populated and the "(auto)" hint is shown.
    final addressField = tester.widget<TextField>(find.byType(TextField).last);
    expect(addressField.controller?.text, isNotEmpty);
    expect(addressField.controller?.text, contains('°'));
    expect(find.textContaining(en.building_address_auto), findsOneWidget);
  });

  test('controller state persists across steps and validates per step', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final controller =
        container.read(addBuildingControllerProvider.notifier);

    // Step 1 invalid until name + area set.
    expect(container.read(addBuildingControllerProvider).step1Valid, isFalse);
    controller.setName('করিম মঞ্জিল');
    controller.setArea(Area.mirpur);
    expect(container.read(addBuildingControllerProvider).step1Valid, isTrue);

    controller.next();
    expect(container.read(addBuildingControllerProvider).step, 2);
    // Step-1 data is still there.
    expect(container.read(addBuildingControllerProvider).name, 'করিম মঞ্জিল');
    expect(container.read(addBuildingControllerProvider).area, Area.mirpur);

    // Step 2 invalid until address set.
    expect(container.read(addBuildingControllerProvider).step2Valid, isFalse);
    controller.setPin(23.8103, 90.4125);
    controller.fillAddressFromMap('House 12, Mirpur');
    final state = container.read(addBuildingControllerProvider);
    expect(state.step2Valid, isTrue);
    expect(state.hasPin, isTrue);
    expect(state.addressAutoFilled, isTrue);
    expect(state.lat, const LatLng(23.8103, 90.4125).latitude);

    // Hand-editing the address clears the auto-filled flag but keeps the pin.
    controller.setAddress('Manual address');
    final edited = container.read(addBuildingControllerProvider);
    expect(edited.addressAutoFilled, isFalse);
    expect(edited.hasPin, isTrue);

    // Back returns to step 1 without losing data.
    controller.back();
    expect(container.read(addBuildingControllerProvider).step, 1);
    expect(container.read(addBuildingControllerProvider).name, 'করিম মঞ্জিল');
  });
}
