import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khatir_mobile/core/i18n/locale_provider.dart';
import 'package:khatir_mobile/core/network/api_exception.dart';
import 'package:khatir_mobile/features/dmpform/data/dmp_pdf_sharer.dart';
import 'package:khatir_mobile/features/dmpform/data/dmpform_providers.dart';
import 'package:khatir_mobile/features/dmpform/data/models/dmp_pdf_result.dart';
import 'package:khatir_mobile/features/dmpform/presentation/screens/dmp_pdf_screen.dart';
import 'package:khatir_mobile/l10n/app_localizations.dart';

/// PDF controller test double: builds to a fixed [DmpPdf] (or throws), so the
/// screen's generating/error/data branches are exercised without a real
/// generate → download round-trip.
class _FakePdf extends DmpPdfController {
  _FakePdf(this._result);

  final Object _result;

  @override
  Future<DmpPdf> build(String tenantId) async {
    final result = _result;
    if (result is DmpPdf) return result;
    throw result;
  }
}

/// Records share/download invocations so the footer actions can be asserted.
class _SpySharer implements DmpPdfSharer {
  String? sharedName;
  String? downloadedName;
  Uint8List? sharedBytes;

  @override
  Future<void> share({
    required Uint8List bytes,
    required String fileName,
  }) async {
    sharedName = fileName;
    sharedBytes = bytes;
  }

  @override
  Future<void> download({
    required Uint8List bytes,
    required String fileName,
  }) async {
    downloadedName = fileName;
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
  final pdf = DmpPdf(
    bytes: Uint8List.fromList(const [0x25, 0x50, 0x44, 0x46]), // "%PDF"
    result: const DmpPdfResult(signedUrl: 'https://x/y.pdf', recordId: 'rec1'),
  );

  // Stubs the native pdfium renderer with a marker widget so the headless test
  // never touches the platform renderer.
  Widget stubView(Uint8List bytes) =>
      SizedBox(key: const ValueKey('pdfViewStub'), width: bytes.length * 1.0);

  Widget harness({
    required Object pdfResult,
    DmpPdfSharer? sharer,
  }) {
    final router = GoRouter(
      initialLocation: '/dmpform/t1/pdf',
      routes: [
        GoRoute(
          path: '/dmpform/:tenantId/pdf',
          name: DmpPdfScreen.routeName,
          builder: (context, state) => DmpPdfScreen(
            tenantId: state.pathParameters['tenantId'] ?? '',
            pdfViewBuilder: stubView,
          ),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        localeStorageProvider.overrideWithValue(_FakeSecureStorage()),
        dmpPdfProvider.overrideWith(() => _FakePdf(pdfResult)),
        if (sharer != null) dmpPdfSharerProvider.overrideWithValue(sharer),
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

  testWidgets('data state renders the preview + download/share actions',
      (tester) async {
    await tester.pumpWidget(harness(pdfResult: pdf));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('pdfViewStub')), findsOneWidget);
    expect(find.text(bn.dmp_pdf_title), findsOneWidget);
    expect(find.text('A4'), findsOneWidget);
    expect(find.byKey(const ValueKey('dmpPdfDownload')), findsOneWidget);
    expect(find.byKey(const ValueKey('dmpPdfShare')), findsOneWidget);
  });

  testWidgets('share button invokes the sharer with the record filename',
      (tester) async {
    final spy = _SpySharer();
    await tester.pumpWidget(harness(pdfResult: pdf, sharer: spy));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('dmpPdfShare')));
    await tester.pump();

    expect(spy.sharedName, 'dmp-form-rec1.pdf');
    expect(spy.sharedBytes, isNotNull);
    expect(spy.downloadedName, isNull);
  });

  testWidgets('download button invokes the sharer download', (tester) async {
    final spy = _SpySharer();
    await tester.pumpWidget(harness(pdfResult: pdf, sharer: spy));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('dmpPdfDownload')));
    await tester.pump();

    expect(spy.downloadedName, 'dmp-form-rec1.pdf');
    expect(spy.sharedName, isNull);
  });

  testWidgets('error state shows a retry', (tester) async {
    await tester.pumpWidget(harness(
      pdfResult: const ApiException(message: 'boom', statusCode: 500),
    ));
    await tester.pumpAndSettle();

    expect(find.text(bn.dmp_pdf_error), findsOneWidget);
    expect(find.byKey(const ValueKey('dmpPdfRetry')), findsOneWidget);
  });
}
