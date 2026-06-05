import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khatir_mobile/core/i18n/locale_provider.dart';
import 'package:khatir_mobile/features/rent/data/models/models.dart';
import 'package:khatir_mobile/features/rent/data/models/rent_enums.dart';
import 'package:khatir_mobile/features/rent/data/providers.dart';
import 'package:khatir_mobile/features/rent/data/rent_repository.dart';
import 'package:khatir_mobile/features/rent/presentation/screens/rent_request_screen.dart';
import 'package:khatir_mobile/l10n/app_localizations.dart';

/// A rent repository that creates a fixed request and records the
/// create/send/mark-received calls without a network, so the action paths can be
/// asserted. [failCreate] / [failSend] / [failMarkReceived] simulate an API
/// failure on the matching step.
class _FakeRentRepo extends RentRepository {
  _FakeRentRepo({
    this.failCreate = false,
    this.failSend = false,
    this.failMarkReceived = false,
  }) : super(Dio());

  int createCalls = 0;
  int sendCalls = 0;
  int markReceivedCalls = 0;
  double? lastAmount;
  String? lastPeriod;
  String? lastLeaseId;

  final bool failCreate;
  final bool failSend;
  final bool failMarkReceived;

  static const _created = RentRequest(id: 'r-1', leaseId: 'l-1');

  @override
  Future<RentRequest> createManual({
    required String leaseId,
    required double amount,
    required String period,
    Channel? sentVia,
  }) async {
    createCalls++;
    lastLeaseId = leaseId;
    lastAmount = amount;
    lastPeriod = period;
    if (failCreate) throw Exception('boom');
    return _created;
  }

  @override
  Future<RentRequest> getRequest(String id) async => _created;

  @override
  Future<RentRequest> sendRequest(String id) async {
    sendCalls++;
    if (failSend) throw Exception('boom');
    return _created.copyWith(status: RentRequestStatus.sent);
  }

  @override
  Future<RentRequest> markReceived(String id) async {
    markReceivedCalls++;
    if (failMarkReceived) throw Exception('boom');
    return _created.copyWith(status: RentRequestStatus.verified);
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
    double? initialAmount,
    String? initialPeriod,
  }) {
    return ProviderScope(
      overrides: [
        rentRepositoryProvider.overrideWithValue(repo),
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
        home: RentRequestScreen(
          leaseId: 'l-1',
          initialAmount: initialAmount,
          initialPeriod: initialPeriod,
        ),
      ),
    );
  }

  testWidgets('renders the hero, fields and both actions', (tester) async {
    tallView(tester);
    await tester.pumpWidget(harness(_FakeRentRepo()));
    await tester.pumpAndSettle();

    expect(find.text(l10n.rent_request_heading), findsOneWidget);
    expect(find.byKey(const ValueKey('rentAmount')), findsOneWidget);
    expect(find.byKey(const ValueKey('rentPeriod')), findsOneWidget);
    expect(find.byKey(const ValueKey('rentSend')), findsOneWidget);
    expect(find.byKey(const ValueKey('rentMarkReceived')), findsOneWidget);
  });

  testWidgets('prefills the amount and period when supplied', (tester) async {
    tallView(tester);
    await tester.pumpWidget(
      harness(_FakeRentRepo(), initialAmount: 22000, initialPeriod: '2026-06'),
    );
    await tester.pumpAndSettle();

    expect(find.text('22000'), findsOneWidget);
    expect(find.text('2026-06'), findsOneWidget);
  });

  testWidgets('send creates the request then sends the link', (tester) async {
    tallView(tester);
    final repo = _FakeRentRepo();
    await tester.pumpWidget(
      harness(repo, initialAmount: 22000, initialPeriod: '2026-06'),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('rentSend')));
    await tester.pumpAndSettle();

    expect(repo.createCalls, 1);
    expect(repo.sendCalls, 1);
    expect(repo.markReceivedCalls, 0);
    expect(repo.lastAmount, 22000);
    expect(repo.lastPeriod, '2026-06');
    expect(repo.lastLeaseId, 'l-1');
    expect(find.text(l10n.rent_request_sent), findsOneWidget);
  });

  testWidgets('mark received creates the request then settles cash',
      (tester) async {
    tallView(tester);
    final repo = _FakeRentRepo();
    await tester.pumpWidget(
      harness(repo, initialAmount: 18500, initialPeriod: '2026-06'),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('rentMarkReceived')));
    await tester.pumpAndSettle();

    expect(repo.createCalls, 1);
    expect(repo.markReceivedCalls, 1);
    expect(repo.sendCalls, 0);
    expect(find.text(l10n.rent_request_received), findsOneWidget);
  });

  testWidgets('blocks the action and shows errors on invalid input',
      (tester) async {
    tallView(tester);
    final repo = _FakeRentRepo();
    // No prefill → empty amount + period are invalid.
    await tester.pumpWidget(harness(repo));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('rentSend')));
    await tester.pumpAndSettle();

    expect(repo.createCalls, 0);
    expect(find.text(l10n.rent_request_err_amount), findsOneWidget);
    expect(find.text(l10n.rent_request_err_period), findsOneWidget);
  });

  testWidgets('surfaces a friendly error when sending fails', (tester) async {
    tallView(tester);
    final repo = _FakeRentRepo(failSend: true);
    await tester.pumpWidget(
      harness(repo, initialAmount: 22000, initialPeriod: '2026-06'),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('rentSend')));
    await tester.pumpAndSettle();

    expect(repo.createCalls, 1);
    expect(repo.sendCalls, 1);
    expect(find.text(l10n.rent_request_error), findsOneWidget);
  });

  testWidgets('surfaces a friendly error when create fails (no send)',
      (tester) async {
    tallView(tester);
    final repo = _FakeRentRepo(failCreate: true);
    await tester.pumpWidget(
      harness(repo, initialAmount: 22000, initialPeriod: '2026-06'),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('rentSend')));
    await tester.pumpAndSettle();

    expect(repo.createCalls, 1);
    expect(repo.sendCalls, 0);
    expect(find.text(l10n.rent_request_error), findsOneWidget);
  });

  testWidgets('surfaces a friendly error when mark-received fails',
      (tester) async {
    tallView(tester);
    final repo = _FakeRentRepo(failMarkReceived: true);
    await tester.pumpWidget(
      harness(repo, initialAmount: 18500, initialPeriod: '2026-06'),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('rentMarkReceived')));
    await tester.pumpAndSettle();

    expect(repo.createCalls, 1);
    expect(repo.markReceivedCalls, 1);
    expect(find.text(l10n.rent_request_error), findsOneWidget);
  });
}
