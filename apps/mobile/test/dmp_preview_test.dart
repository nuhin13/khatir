import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khatir_mobile/core/i18n/locale_provider.dart';
import 'package:khatir_mobile/core/network/api_exception.dart';
import 'package:khatir_mobile/features/dmpform/data/dmpform_providers.dart';
import 'package:khatir_mobile/features/dmpform/data/models/dmp_preview.dart';
import 'package:khatir_mobile/features/dmpform/presentation/screens/dmp_preview_screen.dart';
import 'package:khatir_mobile/l10n/app_localizations.dart';

/// Preview controller test double: builds to a fixed [DmpPreview] (or throws),
/// so the screen's loading/error/data branches can be exercised without a
/// network round-trip.
class _FakePreview extends DmpPreviewController {
  _FakePreview(this._result);

  final Object _result;

  @override
  Future<DmpPreview> build(String tenantId) async {
    if (_result is DmpPreview) return _result;
    throw _result;
  }
}

class _FakeSecureStorage extends FlutterSecureStorage {
  _FakeSecureStorage() : super();
  final Map<String, String> _store = {};

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async =>
      _store[key];

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value == null) {
      _store.remove(key);
    } else {
      _store[key] = value;
    }
  }
}

void main() {
  const preview = DmpPreview(
    tenantName: 'Karim Hossain',
    nidNumber: '**** **** 7788',
    landlordName: 'Abdul Karim',
    buildingAddress: 'Mirpur 10, Flat 2C',
    landlordPhone: '01711-000111',
    familyMembers: [
      DmpFamilyMember(name: 'Salma Begum', relation: 'Wife'),
    ],
  );

  Widget harness({
    required Object previewResult,
    void Function(BuildContext)? onGenerate,
    void Function(BuildContext)? onEdit,
  }) {
    final router = GoRouter(
      initialLocation: '/dmpform/t1',
      routes: [
        GoRoute(
          path: '/dmpform/:tenantId',
          name: DmpPreviewScreen.routeName,
          builder: (context, state) => DmpPreviewScreen(
            tenantId: state.pathParameters['tenantId'] ?? '',
            onGenerate: onGenerate,
            onEdit: onEdit,
          ),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        localeStorageProvider.overrideWithValue(_FakeSecureStorage()),
        dmpPreviewProvider.overrideWith(() => _FakePreview(previewResult)),
      ],
      child: Consumer(
        builder: (context, ref, _) {
          final locale = ref.watch(localeProvider);
          return MaterialApp.router(
            routerConfig: router,
            locale: locale,
            supportedLocales: kSupportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
          );
        },
      ),
    );
  }

  late AppLocalizations bn;

  setUp(() async {
    bn = await AppLocalizations.delegate.load(kLocaleBn);
  });

  testWidgets('data state renders assembled fields and masked NID',
      (tester) async {
    await tester.pumpWidget(harness(previewResult: preview));
    await tester.pumpAndSettle();

    expect(find.text('Karim Hossain'), findsOneWidget);
    // NID shows only the masked value — never a full number.
    expect(find.text('**** **** 7788'), findsOneWidget);
    expect(find.text('Abdul Karim'), findsOneWidget);
    expect(find.text('Salma Begum'), findsOneWidget);
    expect(find.text(bn.dmp_ready), findsOneWidget);
    // Both action buttons render (scroll the lazy list to reach them).
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('dmpEdit')),
      200,
    );
    expect(find.byKey(const ValueKey('dmpGenerate')), findsOneWidget);
    expect(find.byKey(const ValueKey('dmpEdit')), findsOneWidget);
  });

  testWidgets('generate button fires the generate action', (tester) async {
    var generated = false;
    await tester.pumpWidget(harness(
      previewResult: preview,
      onGenerate: (_) => generated = true,
    ));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('dmpGenerate')),
      200,
    );
    await tester.tap(find.byKey(const ValueKey('dmpGenerate')));
    await tester.pump();

    expect(generated, isTrue);
  });

  testWidgets('edit button fires the edit action', (tester) async {
    var edited = false;
    await tester.pumpWidget(harness(
      previewResult: preview,
      onEdit: (_) => edited = true,
    ));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('dmpEdit')),
      200,
    );
    await tester.tap(find.byKey(const ValueKey('dmpEdit')));
    await tester.pump();

    expect(edited, isTrue);
  });

  testWidgets('error state shows a retry', (tester) async {
    await tester.pumpWidget(harness(
      previewResult: const ApiException(message: 'boom', statusCode: 404),
    ));
    await tester.pumpAndSettle();

    expect(find.text(bn.dmp_error), findsOneWidget);
    expect(find.byKey(const ValueKey('dmpRetry')), findsOneWidget);
  });
}
