import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khatir_mobile/core/i18n/locale_provider.dart';
import 'package:khatir_mobile/features/rent/data/models/models.dart';
import 'package:khatir_mobile/features/rent/data/models/rent_enums.dart';
import 'package:khatir_mobile/features/rent/data/providers.dart';
import 'package:khatir_mobile/features/rent/data/receipt_sharer.dart';
import 'package:khatir_mobile/features/rent/data/rent_repository.dart';
import 'package:khatir_mobile/features/rent/presentation/screens/receipt_screen.dart';
import 'package:khatir_mobile/l10n/app_localizations.dart';

/// A rent repository returning a fixed settled request (and fixed receipt bytes)
/// without a network. [failGet] simulates a load failure to exercise the error
/// state.
class _FakeRentRepo extends RentRepository {
  _FakeRentRepo({this.failGet = false}) : super(Dio());

  final bool failGet;

  static const _request = RentRequest(
    id: 'r-1',
    leaseId: 'l-1',
    amount: 22000,
    period: '2026-06',
    status: RentRequestStatus.verified,
  );

  @override
  Future<RentRequest> getRequest(String id) async {
    if (failGet) throw Exception('boom');
    return _request;
  }

  @override
  Future<Uint8List> fetchReceiptBytes(String url) async =>
      Uint8List.fromList(const [0x25, 0x50, 0x44, 0x46]); // "%PDF"
}

/// Records share/download invocations so the receipt actions can be asserted.
class _SpySharer implements ReceiptSharer {
  String? sharedPdfName;
  String? sharedText;
  String? downloadedName;
  Uint8List? sharedBytes;

  @override
  Future<void> sharePdf({
    required Uint8List bytes,
    required String fileName,
  }) async {
    sharedPdfName = fileName;
    sharedBytes = bytes;
  }

  @override
  Future<void> shareText({required String text, String? subject}) async {
    sharedText = text;
  }

  @override
  Future<void> downloadPdf({
    required Uint8List bytes,
    required String fileName,
  }) async {
    downloadedName = fileName;
  }
}

void main() {
  late AppLocalizations l10n;

  setUp(() async {
    l10n = await AppLocalizations.delegate.load(kLocaleEn);
  });

  void tallView(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 3200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  Widget harness(
    _FakeRentRepo repo, {
    ReceiptSharer? sharer,
    ReceiptArgs? args,
  }) {
    return ProviderScope(
      overrides: [
        rentRepositoryProvider.overrideWithValue(repo),
        if (sharer != null)
          receiptSharerProvider.overrideWithValue(sharer),
      ],
      child: MaterialApp(
        locale: kLocaleEn,
        supportedLocales: kSupportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: ReceiptScreen(requestId: 'r-1', args: args),
      ),
    );
  }

  testWidgets('renders the receipt summary and both actions', (tester) async {
    tallView(tester);
    await tester.pumpWidget(harness(
      _FakeRentRepo(),
      args: const ReceiptArgs(
        tenantName: 'Karim Hossain',
        unitLabel: '2C',
        method: 'bKash',
        receiptNo: 'KHT/2026/RC-0512',
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('receiptCard')), findsOneWidget);
    expect(find.text(l10n.receipt_amount('22000')), findsOneWidget);
    expect(find.text('Karim Hossain'), findsOneWidget);
    expect(find.text(l10n.receipt_status_paid), findsOneWidget);
    expect(find.byKey(const ValueKey('receiptShare')), findsOneWidget);
    expect(find.byKey(const ValueKey('receiptDone')), findsOneWidget);
  });

  testWidgets('share with a signed PDF url shares the receipt PDF',
      (tester) async {
    tallView(tester);
    final spy = _SpySharer();
    await tester.pumpWidget(harness(
      _FakeRentRepo(),
      sharer: spy,
      args: const ReceiptArgs(
        receiptNo: 'KHT/2026/RC-0512',
        pdfUrl: 'https://x/receipt.pdf',
      ),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('receiptShare')));
    await tester.pumpAndSettle();

    expect(spy.sharedPdfName, 'rent-receipt-KHT-2026-RC-0512.pdf');
    expect(spy.sharedBytes, isNotNull);
    expect(spy.sharedText, isNull);
  });

  testWidgets('share without a PDF url falls back to a text summary',
      (tester) async {
    tallView(tester);
    final spy = _SpySharer();
    await tester.pumpWidget(harness(_FakeRentRepo(), sharer: spy));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('receiptShare')));
    await tester.pumpAndSettle();

    expect(spy.sharedText, l10n.receipt_share_text('22000', '2026-06'));
    expect(spy.sharedPdfName, isNull);
  });

  testWidgets('done downloads the PDF when a signed url is present',
      (tester) async {
    tallView(tester);
    final spy = _SpySharer();
    await tester.pumpWidget(harness(
      _FakeRentRepo(),
      sharer: spy,
      args: const ReceiptArgs(pdfUrl: 'https://x/receipt.pdf'),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('receiptDone')));
    await tester.pumpAndSettle();

    expect(spy.downloadedName, 'rent-receipt-r-1.pdf');
  });

  testWidgets('load error shows a retry', (tester) async {
    tallView(tester);
    await tester.pumpWidget(harness(_FakeRentRepo(failGet: true)));
    await tester.pumpAndSettle();

    expect(find.text(l10n.receipt_load_error), findsOneWidget);
    expect(find.byKey(const ValueKey('receiptRetry')), findsOneWidget);
  });
}
