import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khatir_mobile/core/i18n/locale_provider.dart';
import 'package:khatir_mobile/features/tenants/data/models/extracted_tenant.dart';
import 'package:khatir_mobile/features/tenants/presentation/screens/ocr_review_args.dart';
import 'package:khatir_mobile/features/tenants/presentation/screens/ocr_review_screen.dart';
import 'package:khatir_mobile/l10n/app_localizations.dart';

void main() {
  late AppLocalizations l10n;

  setUp(() async {
    l10n = await AppLocalizations.delegate.load(kLocaleBn);
  });

  /// A typical extraction: name/nid high confidence, address low (≤0.85).
  ExtractedTenant sample() => const ExtractedTenant(
        name: ExtractedField(value: 'Karim Hossain', confidence: 0.97),
        nidNumber: ExtractedField(value: '1992556677', confidence: 0.95),
        dob: ExtractedField(value: '1992-03-12', confidence: 0.9),
        address: ExtractedField(value: 'Mirpur 10, Dhaka', confidence: 0.55),
        photoRef: 'ref-abc123',
      );

  /// Tall viewport so the lazily-built ListView children (proceed button) lay
  /// out without scrolling.
  void tallView(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  Widget harness({
    required OcrReviewArgs args,
    void Function(TenantReviewDraft draft)? onProceed,
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
        home: OcrReviewScreen(args: args, onProceed: onProceed),
      ),
    );
  }

  testWidgets('prefills editable fields from the OCR result', (tester) async {
    tallView(tester);
    await tester.pumpWidget(
      harness(args: OcrReviewArgs(extracted: sample())),
    );
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextFormField, 'Karim Hossain'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, '1992556677'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, '1992-03-12'), findsOneWidget);
    expect(
      find.widgetWithText(TextFormField, 'Mirpur 10, Dhaka'),
      findsOneWidget,
    );
  });

  testWidgets('flags a low-confidence field for attention', (tester) async {
    tallView(tester);
    await tester.pumpWidget(
      harness(args: OcrReviewArgs(extracted: sample())),
    );
    await tester.pumpAndSettle();

    // Address came back at 0.55 (≤0.85) → low-confidence hint visible.
    expect(find.text(l10n.ocr_low_confidence), findsOneWidget);
  });

  testWidgets('blocks proceed when a required field is cleared',
      (tester) async {
    TenantReviewDraft? captured;
    tallView(tester);
    await tester.pumpWidget(
      harness(
        args: OcrReviewArgs(extracted: sample()),
        onProceed: (d) => captured = d,
      ),
    );
    await tester.pumpAndSettle();

    // Clear the required name field.
    await tester.enterText(find.byKey(const ValueKey('ocrFieldName')), '');
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('ocrProceed')));
    await tester.pumpAndSettle();

    expect(captured, isNull); // validation blocked the proceed
    expect(find.text(l10n.ocr_err_name), findsOneWidget);
  });

  testWidgets('proceed emits the edited values + photo_ref + unit',
      (tester) async {
    TenantReviewDraft? captured;
    tallView(tester);
    await tester.pumpWidget(
      harness(
        args: OcrReviewArgs(extracted: sample(), unitId: 'unit-7'),
        onProceed: (d) => captured = d,
      ),
    );
    await tester.pumpAndSettle();

    // Correct a misread NID digit (manual QA scenario, T-011 §12).
    await tester.enterText(
      find.byKey(const ValueKey('ocrFieldNid')),
      '1992556678',
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('ocrProceed')));
    await tester.pumpAndSettle();

    expect(captured, isNotNull);
    expect(captured!.name, 'Karim Hossain');
    expect(captured!.nidNumber, '1992556678'); // the corrected value, not OCR
    expect(captured!.photoRef, 'ref-abc123');
    expect(captured!.unitId, 'unit-7');
    expect(captured!.family, isEmpty);
  });

  testWidgets('family sub-form: add a member, it flows into the draft',
      (tester) async {
    TenantReviewDraft? captured;
    tallView(tester);
    await tester.pumpWidget(
      harness(
        args: OcrReviewArgs(extracted: sample()),
        onProceed: (d) => captured = d,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('ocrFamilyAdd')));
    await tester.pumpAndSettle();

    final nameField = find.byKey(const ValueKey('ocrFamilyName'));
    final relationField = find.byKey(const ValueKey('ocrFamilyRelation'));
    expect(nameField, findsOneWidget);
    await tester.enterText(nameField, 'Rahima');
    await tester.enterText(relationField, 'Wife');
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('ocrProceed')));
    await tester.pumpAndSettle();

    expect(captured, isNotNull);
    expect(captured!.family, hasLength(1));
    expect(captured!.family.single.name, 'Rahima');
    expect(captured!.family.single.relation, 'Wife');
  });

  testWidgets('family sub-form: remove a member drops its row', (tester) async {
    tallView(tester);
    await tester.pumpWidget(
      harness(args: OcrReviewArgs(extracted: sample())),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('ocrFamilyAdd')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('ocrFamilyName')), findsOneWidget);

    await tester.tap(find.byTooltip(l10n.ocr_family_remove));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('ocrFamilyName')), findsNothing);
  });
}
