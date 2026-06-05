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
import 'package:khatir_mobile/features/rent/presentation/screens/verify_payment_screen.dart';
import 'package:khatir_mobile/l10n/app_localizations.dart';

/// A rent repository that returns a fixed request and records the verify/reject
/// calls without a network, so the action paths can be asserted. [failGet]
/// simulates a load failure; [failVerify] / [failReject] simulate an API failure
/// on the matching transition.
class _FakeRentRepo extends RentRepository {
  _FakeRentRepo({
    this.failGet = false,
    this.failVerify = false,
    this.failReject = false,
  }) : super(Dio());

  int verifyCalls = 0;
  int rejectCalls = 0;
  String? lastReason;

  final bool failGet;
  final bool failVerify;
  final bool failReject;

  static const _request = RentRequest(
    id: 'r-1',
    leaseId: 'l-1',
    amount: 22000,
    period: '2026-06',
    status: RentRequestStatus.proofSubmitted,
  );

  @override
  Future<RentRequest> getRequest(String id) async {
    if (failGet) throw Exception('boom');
    return _request;
  }

  @override
  Future<RentRequest> verify(String id) async {
    verifyCalls++;
    if (failVerify) throw Exception('boom');
    return _request.copyWith(status: RentRequestStatus.verified);
  }

  @override
  Future<RentRequest> reject(String id, {required String reason}) async {
    rejectCalls++;
    lastReason = reason;
    if (failReject) throw Exception('boom');
    return _request.copyWith(status: RentRequestStatus.rejected);
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
    PaymentProof? proof,
    String? tenantName = 'Karim',
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
        home: VerifyPaymentScreen(
          requestId: 'r-1',
          tenantName: tenantName,
          proof: proof,
        ),
      ),
    );
  }

  testWidgets('renders the claim, proof viewer and both actions',
      (tester) async {
    tallView(tester);
    await tester.pumpWidget(harness(_FakeRentRepo()));
    await tester.pumpAndSettle();

    expect(find.text(l10n.verify_claim('Karim')), findsOneWidget);
    expect(find.text(l10n.verify_proof), findsWidgets);
    expect(find.byKey(const ValueKey('verifyConfirm')), findsOneWidget);
    expect(find.byKey(const ValueKey('verifyReject')), findsOneWidget);
  });

  testWidgets('shows a "no proof" placeholder when no proof is supplied',
      (tester) async {
    tallView(tester);
    await tester.pumpWidget(harness(_FakeRentRepo()));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('verifyProofNone')), findsOneWidget);
    expect(find.text(l10n.verify_proof_none), findsOneWidget);
  });

  testWidgets('shows proof details when a proof with a txn value is supplied',
      (tester) async {
    tallView(tester);
    await tester.pumpWidget(
      harness(
        _FakeRentRepo(),
        proof: const PaymentProof(
          id: 'p-1',
          type: PaymentProofType.bkashTxn,
          value: '8GH4K2L9PQ',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('verifyProof')), findsOneWidget);
    expect(find.text('8GH4K2L9PQ'), findsOneWidget);
    expect(find.byKey(const ValueKey('verifyProofNone')), findsNothing);
  });

  testWidgets('verify runs the verify transition and confirms', (tester) async {
    tallView(tester);
    final repo = _FakeRentRepo();
    await tester.pumpWidget(harness(repo));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('verifyConfirm')));
    await tester.pumpAndSettle();

    expect(repo.verifyCalls, 1);
    expect(repo.rejectCalls, 0);
    expect(find.text(l10n.verify_verified), findsOneWidget);
  });

  testWidgets('reject opens the reason dialog and rejects with the reason',
      (tester) async {
    tallView(tester);
    final repo = _FakeRentRepo();
    await tester.pumpWidget(harness(repo));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('verifyReject')));
    await tester.pumpAndSettle();

    // Dialog is open; submitting empty shows the required error.
    await tester.tap(find.byKey(const ValueKey('verifyReasonSubmit')));
    await tester.pumpAndSettle();
    expect(find.text(l10n.verify_reason_required), findsOneWidget);
    expect(repo.rejectCalls, 0);

    // Enter a reason and submit.
    await tester.enterText(
      find.byKey(const ValueKey('verifyReasonField')),
      'Wrong amount',
    );
    await tester.tap(find.byKey(const ValueKey('verifyReasonSubmit')));
    await tester.pumpAndSettle();

    expect(repo.rejectCalls, 1);
    expect(repo.lastReason, 'Wrong amount');
    expect(find.text(l10n.verify_rejected), findsOneWidget);
  });

  testWidgets('cancelling the reject dialog runs no transition', (tester) async {
    tallView(tester);
    final repo = _FakeRentRepo();
    await tester.pumpWidget(harness(repo));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('verifyReject')));
    await tester.pumpAndSettle();

    await tester.tap(find.text(l10n.verify_reason_cancel));
    await tester.pumpAndSettle();

    expect(repo.rejectCalls, 0);
    expect(repo.verifyCalls, 0);
  });

  testWidgets('surfaces a friendly error when verify fails', (tester) async {
    tallView(tester);
    final repo = _FakeRentRepo(failVerify: true);
    await tester.pumpWidget(harness(repo));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('verifyConfirm')));
    await tester.pumpAndSettle();

    expect(repo.verifyCalls, 1);
    expect(find.text(l10n.verify_error), findsOneWidget);
  });

  testWidgets('surfaces a friendly error when reject fails', (tester) async {
    tallView(tester);
    final repo = _FakeRentRepo(failReject: true);
    await tester.pumpWidget(harness(repo));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('verifyReject')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('verifyReasonField')),
      'Wrong amount',
    );
    await tester.tap(find.byKey(const ValueKey('verifyReasonSubmit')));
    await tester.pumpAndSettle();

    expect(repo.rejectCalls, 1);
    expect(find.text(l10n.verify_error), findsOneWidget);
  });

  testWidgets('shows the load-error state with a retry when the load fails',
      (tester) async {
    tallView(tester);
    final repo = _FakeRentRepo(failGet: true);
    await tester.pumpWidget(harness(repo));
    await tester.pumpAndSettle();

    expect(find.text(l10n.verify_load_error), findsOneWidget);
    expect(find.byKey(const ValueKey('verifyRetry')), findsOneWidget);
  });
}
