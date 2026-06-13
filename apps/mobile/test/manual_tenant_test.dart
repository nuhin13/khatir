import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khatir_mobile/core/i18n/locale_provider.dart';
import 'package:khatir_mobile/features/tenants/presentation/screens/manual_tenant_screen.dart';
import 'package:khatir_mobile/l10n/app_localizations.dart';

void main() {
  late AppLocalizations l10n;

  setUp(() async {
    l10n = await AppLocalizations.delegate.load(kLocaleBn);
  });

  /// Tall viewport so the lazily-built ListView children (proceed button) lay
  /// out without scrolling.
  void tallView(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  Widget harness({
    String? unitId,
    void Function(ManualTenantDraft draft)? onProceed,
  }) {
    return ProviderScope(
      child: MaterialApp(
        locale: kLocaleBn,
        supportedLocales: kSupportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: ManualTenantScreen(unitId: unitId, onProceed: onProceed),
      ),
    );
  }

  testWidgets('renders the DMP section headings and an empty form',
      (tester) async {
    tallView(tester);
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    expect(find.text(l10n.manual_section_landlord), findsOneWidget);
    expect(find.text(l10n.manual_section_tenant), findsOneWidget);
    expect(find.text(l10n.manual_section_unit), findsOneWidget);
    expect(find.text(l10n.manual_section_family), findsOneWidget);
    expect(find.byKey(const ValueKey('manualProceed')), findsOneWidget);
    // Nothing is prefilled: the required tenant name field shows no value.
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('manualName')),
        matching: find.byType(EditableText),
      ),
      findsOneWidget,
    );
    final editable = tester.widget<EditableText>(
      find.descendant(
        of: find.byKey(const ValueKey('manualName')),
        matching: find.byType(EditableText),
      ),
    );
    expect(editable.controller.text, isEmpty);
  });

  testWidgets('blocks proceed when required fields are empty', (tester) async {
    ManualTenantDraft? captured;
    tallView(tester);
    await tester.pumpWidget(harness(onProceed: (d) => captured = d));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('manualProceed')));
    await tester.pumpAndSettle();

    expect(captured, isNull); // validation blocked the proceed
    expect(find.text(l10n.ocr_err_name), findsOneWidget);
    expect(find.text(l10n.ocr_err_nid), findsOneWidget);
  });

  testWidgets('proceed emits the entered values + unit when valid',
      (tester) async {
    ManualTenantDraft? captured;
    tallView(tester);
    await tester.pumpWidget(
      harness(unitId: 'unit-9', onProceed: (d) => captured = d),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('manualName')),
      'Rahim Uddin',
    );
    await tester.enterText(
      find.byKey(const ValueKey('manualNid')),
      '1992556677',
    );
    await tester.enterText(
      find.byKey(const ValueKey('manualRent')),
      '26000',
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('manualProceed')));
    await tester.pumpAndSettle();

    expect(captured, isNotNull);
    expect(captured!.name, 'Rahim Uddin');
    expect(captured!.nidNumber, '1992556677');
    expect(captured!.rent, '26000');
    expect(captured!.unitId, 'unit-9');
    expect(captured!.family, isEmpty);
  });

  testWidgets('family sub-form: add a member, it flows into the draft',
      (tester) async {
    ManualTenantDraft? captured;
    tallView(tester);
    await tester.pumpWidget(harness(onProceed: (d) => captured = d));
    await tester.pumpAndSettle();

    // Required tenant fields so proceed passes validation.
    await tester.enterText(
      find.byKey(const ValueKey('manualName')),
      'Rahim Uddin',
    );
    await tester.enterText(
      find.byKey(const ValueKey('manualNid')),
      '1992556677',
    );

    await tester.tap(find.byKey(const ValueKey('manualFamilyAdd')));
    await tester.pumpAndSettle();

    final nameField = find.byKey(const ValueKey('manualFamilyName'));
    final relationField = find.byKey(const ValueKey('manualFamilyRelation'));
    expect(nameField, findsOneWidget);
    await tester.enterText(nameField, 'Salma');
    await tester.enterText(relationField, 'Wife');
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('manualProceed')));
    await tester.pumpAndSettle();

    expect(captured, isNotNull);
    expect(captured!.family, hasLength(1));
    expect(captured!.family.single.name, 'Salma');
    expect(captured!.family.single.relation, 'Wife');
  });

  testWidgets('family sub-form: remove a member drops its row', (tester) async {
    tallView(tester);
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('manualFamilyAdd')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('manualFamilyName')), findsOneWidget);

    await tester.tap(find.byTooltip(l10n.ocr_family_remove));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('manualFamilyName')), findsNothing);
  });
}
