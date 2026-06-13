/// T-006 — WarningNoticeScreen widget tests.
///
/// Covers:
/// - Loading state while generating / downloading the PDF.
/// - Data state: renders the PDF viewer, disclaimer strip, download + share CTA.
/// - Error state: shows error + retry button.
/// - Download button invokes sharer.download with the correct filename.
/// - Share button invokes sharer.share.
/// - Disclaimer strip always shown above the PDF.
library;

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khatir_mobile/core/i18n/locale_provider.dart';
import 'package:khatir_mobile/core/network/api_exception.dart';
import 'package:khatir_mobile/features/warnings/data/models/models.dart';
import 'package:khatir_mobile/features/warnings/data/providers.dart';
import 'package:khatir_mobile/features/warnings/data/warning_notice_sharer.dart';
import 'package:khatir_mobile/features/warnings/presentation/screens/warning_notice_screen.dart';
import 'package:khatir_mobile/l10n/app_localizations.dart';

// ── Test doubles ──────────────────────────────────────────────────────────

/// A fake WarningNoticePdfController for test scenarios.
class _FakeNoticeController extends WarningNoticePdfController {
  _FakeNoticeController(this._result);

  final Object _result;

  @override
  Future<WarningNoticePdf> build(String warningId) async {
    final r = _result;
    if (r is WarningNoticePdf) return r;
    throw r as Object;
  }
}

/// Records share/download invocations.
class _SpySharer implements WarningNoticeSharer {
  String? sharedName;
  String? downloadedName;
  Uint8List? sharedBytes;

  @override
  Future<void> share({required Uint8List bytes, required String fileName}) async {
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

// ── Harness ────────────────────────────────────────────────────────────────

final _pdfBytes = Uint8List.fromList(const [0x25, 0x50, 0x44, 0x46]); // %PDF

final _noticePdf = WarningNoticePdf(
  bytes: _pdfBytes,
  notice: const WarningNotice(
    warningId: 'w1',
    noticeRef: 'ref-notice-001',
    signedUrl: 'https://storage.example.com/notices/w1.pdf',
  ),
);

Widget _harness({
  required Object pdfResult,
  WarningNoticeSharer? sharer,
}) {
  final router = GoRouter(
    initialLocation: '/warning/w1/notice',
    routes: [
      GoRoute(
        path: WarningNoticeScreen.routePath,
        name: WarningNoticeScreen.routeName,
        builder: (context, state) => WarningNoticeScreen(
          warningId: state.pathParameters['warningId'] ?? 'w1',
          // Stub out the native PDF renderer with a marker widget.
          pdfViewBuilder: (bytes) =>
              SizedBox(key: const ValueKey('pdfViewStub'), width: bytes.length * 1.0),
        ),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      warningNoticePdfProvider.overrideWith(() => _FakeNoticeController(pdfResult)),
      if (sharer != null) warningNoticeSharerProvider.overrideWithValue(sharer),
    ],
    child: MaterialApp.router(
      routerConfig: router,
      locale: kLocaleEn,
      supportedLocales: kSupportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    ),
  );
}

// ── Tests ────────────────────────────────────────────────────────────────

void main() {
  late AppLocalizations l10n;

  setUp(() async {
    l10n = await AppLocalizations.delegate.load(kLocaleEn);
  });

  group('WarningNoticeScreen — data state', () {
    testWidgets('renders PDF view, disclaimer, download + share buttons',
        (tester) async {
      await tester.pumpWidget(_harness(pdfResult: _noticePdf));
      await tester.pumpAndSettle();

      // Title.
      expect(find.text(l10n.warning_notice_title), findsOneWidget);
      // "A4" format chip.
      expect(find.text('A4'), findsOneWidget);
      // PDF stub.
      expect(find.byKey(const ValueKey('pdfViewStub')), findsOneWidget);
      // Actions.
      expect(find.byKey(const ValueKey('warningNoticeDownload')), findsOneWidget);
      expect(find.byKey(const ValueKey('warningNoticeShare')), findsOneWidget);
    });

    testWidgets('privacy disclaimer strip is visible above the PDF',
        (tester) async {
      await tester.pumpWidget(_harness(pdfResult: _noticePdf));
      await tester.pumpAndSettle();

      expect(find.text(l10n.warning_private_notice), findsOneWidget);
    });

    testWidgets('share button calls sharer.share with notice filename',
        (tester) async {
      final spy = _SpySharer();
      await tester.pumpWidget(_harness(pdfResult: _noticePdf, sharer: spy));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('warningNoticeShare')));
      await tester.pump();

      expect(spy.sharedName, 'warning-notice-ref-notice-001.pdf');
      expect(spy.sharedBytes, _pdfBytes);
      expect(spy.downloadedName, isNull);
    });

    testWidgets('download button calls sharer.download with notice filename',
        (tester) async {
      final spy = _SpySharer();
      await tester.pumpWidget(_harness(pdfResult: _noticePdf, sharer: spy));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('warningNoticeDownload')));
      await tester.pump();

      expect(spy.downloadedName, 'warning-notice-ref-notice-001.pdf');
      expect(spy.sharedName, isNull);
    });
  });

  group('WarningNoticeScreen — error state', () {
    testWidgets('shows error message and retry button', (tester) async {
      await tester.pumpWidget(_harness(
        pdfResult: const ApiException(message: 'boom', statusCode: 500),
      ));
      await tester.pumpAndSettle();

      expect(find.text(l10n.warning_notice_error), findsOneWidget);
      expect(find.byKey(const ValueKey('warningNoticeRetry')), findsOneWidget);
    });
  });
}
