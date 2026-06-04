import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khatir_mobile/core/i18n/locale_provider.dart';
import 'package:khatir_mobile/features/tenants/presentation/screens/ocr_review_args.dart';
import 'package:khatir_mobile/features/tenants/presentation/widgets/family_members_field.dart';
import 'package:khatir_mobile/l10n/app_localizations.dart';

void main() {
  late AppLocalizations l10n;

  setUp(() async {
    l10n = await AppLocalizations.delegate.load(kLocaleBn);
  });

  /// Tall viewport so lazily-laid-out children stay on screen.
  void tallView(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  Widget harness({
    required ValueChanged<List<FamilyMemberDraft>> onChanged,
    String keyPrefix = 'ocr',
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
        home: Scaffold(
          body: ListView(
            children: [
              FamilyMembersField(keyPrefix: keyPrefix, onChanged: onChanged),
            ],
          ),
        ),
      ),
    );
  }

  testWidgets('starts empty: only the add affordance is shown', (tester) async {
    tallView(tester);
    await tester.pumpWidget(harness(onChanged: (_) {}));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('ocrFamilyAdd')), findsOneWidget);
    expect(find.byKey(const ValueKey('ocrFamilyName')), findsNothing);
  });

  testWidgets('add a member: a name/relation row appears and flows out',
      (tester) async {
    List<FamilyMemberDraft> latest = const [];
    tallView(tester);
    await tester.pumpWidget(harness(onChanged: (m) => latest = m));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('ocrFamilyAdd')));
    await tester.pumpAndSettle();

    final nameField = find.byKey(const ValueKey('ocrFamilyName'));
    final relationField = find.byKey(const ValueKey('ocrFamilyRelation'));
    expect(nameField, findsOneWidget);
    expect(relationField, findsOneWidget);

    await tester.enterText(nameField, 'Rahima');
    await tester.enterText(relationField, 'Wife');
    await tester.pumpAndSettle();

    expect(latest, hasLength(1));
    expect(latest.single.name, 'Rahima');
    expect(latest.single.relation, 'Wife');
  });

  testWidgets('blank-name rows are omitted from the emitted draft',
      (tester) async {
    List<FamilyMemberDraft> latest = const [];
    tallView(tester);
    await tester.pumpWidget(harness(onChanged: (m) => latest = m));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('ocrFamilyAdd')));
    await tester.pumpAndSettle();
    // A row exists but the name is left blank → not reported.
    expect(latest, isEmpty);
  });

  testWidgets('remove a member: drops the row and re-emits', (tester) async {
    List<FamilyMemberDraft> latest = const [];
    tallView(tester);
    await tester.pumpWidget(harness(onChanged: (m) => latest = m));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('ocrFamilyAdd')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('ocrFamilyName')),
      'Karim',
    );
    await tester.pumpAndSettle();
    expect(latest, hasLength(1));

    await tester.tap(find.byTooltip(l10n.family_remove));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('ocrFamilyName')), findsNothing);
    expect(latest, isEmpty);
  });

  testWidgets('keyPrefix namespaces the row keys per host', (tester) async {
    tallView(tester);
    await tester.pumpWidget(
      harness(onChanged: (_) {}, keyPrefix: 'manual'),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('manualFamilyAdd')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('manualFamilyAdd')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('manualFamilyName')), findsOneWidget);
    expect(find.byKey(const ValueKey('manualFamilyRelation')), findsOneWidget);
  });
}
