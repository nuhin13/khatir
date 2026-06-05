import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khatir_mobile/core/i18n/locale_provider.dart';
import 'package:khatir_mobile/features/leases/data/lease_repository.dart';
import 'package:khatir_mobile/features/leases/data/models/lease_enums.dart';
import 'package:khatir_mobile/features/leases/data/models/models.dart';
import 'package:khatir_mobile/features/leases/data/providers.dart';
import 'package:khatir_mobile/features/leases/presentation/screens/lease_detail_screen.dart';
import 'package:khatir_mobile/l10n/app_localizations.dart';

/// A lease repository that serves a fixed lease + schedule without a network,
/// and records terminate calls so the action can be asserted.
class _FakeLeaseRepo extends LeaseRepository {
  _FakeLeaseRepo({
    required this.lease,
    this.schedule = const [],
    this.failGet = false,
  }) : super(Dio());

  Lease lease;
  final List<RentSchedule> schedule;
  final bool failGet;
  int terminateCalls = 0;

  @override
  Future<Lease> getLease(String id) async {
    if (failGet) throw Exception('boom');
    return lease;
  }

  @override
  Future<List<RentSchedule>> getSchedule(String id) async => schedule;

  @override
  Future<Lease> terminateLease(String id, {LeaseStatus? status}) async {
    terminateCalls++;
    lease = lease.copyWith(status: status ?? LeaseStatus.terminated);
    return lease;
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

  Widget harness(_FakeLeaseRepo repo) {
    return ProviderScope(
      overrides: [
        leaseRepositoryProvider.overrideWithValue(repo),
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
        home: const LeaseDetailScreen(leaseId: 'l-1'),
      ),
    );
  }

  testWidgets('renders the terms and schedule summary for an active lease',
      (tester) async {
    tallView(tester);
    final repo = _FakeLeaseRepo(
      lease: const Lease(
        id: 'l-1',
        rent: 26000,
        advance: 52000,
        status: LeaseStatus.active,
      ),
      schedule: const [
        RentSchedule(id: 's-1', status: RentScheduleStatus.paid),
        RentSchedule(id: 's-2', status: RentScheduleStatus.pending),
      ],
    );
    await tester.pumpWidget(harness(repo));
    await tester.pumpAndSettle();

    // Section headings (uppercased) and the schedule count are present.
    expect(find.text(l10n.lease_section_terms.toUpperCase()), findsOneWidget);
    expect(find.text(l10n.lease_section_schedule.toUpperCase()), findsOneWidget);
    expect(find.text(l10n.lease_schedule_summary('2')), findsOneWidget);

    // The terminate action is visible for an active lease.
    expect(find.byKey(const ValueKey('leaseTerminate')), findsOneWidget);
  });

  testWidgets('hides the terminate action for a non-active lease',
      (tester) async {
    tallView(tester);
    final repo = _FakeLeaseRepo(
      lease: const Lease(id: 'l-1', rent: 26000, status: LeaseStatus.ended),
    );
    await tester.pumpWidget(harness(repo));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('leaseTerminate')), findsNothing);
  });

  testWidgets('shows the empty-schedule helper when there are no rows',
      (tester) async {
    tallView(tester);
    final repo = _FakeLeaseRepo(
      lease: const Lease(id: 'l-1', rent: 26000, status: LeaseStatus.draft),
    );
    await tester.pumpWidget(harness(repo));
    await tester.pumpAndSettle();

    expect(find.text(l10n.lease_schedule_empty), findsOneWidget);
  });

  testWidgets('terminate confirm flow calls the repo and reports success',
      (tester) async {
    tallView(tester);
    final repo = _FakeLeaseRepo(
      lease: const Lease(id: 'l-1', rent: 26000, status: LeaseStatus.active),
    );
    await tester.pumpWidget(harness(repo));
    await tester.pumpAndSettle();

    // Open the confirm dialog.
    await tester.tap(find.byKey(const ValueKey('leaseTerminate')));
    await tester.pumpAndSettle();
    expect(find.text(l10n.lease_terminate_confirm_title), findsOneWidget);

    // Confirm.
    await tester.tap(find.byKey(const ValueKey('leaseTerminateConfirm')));
    await tester.pumpAndSettle();

    expect(repo.terminateCalls, 1);
    expect(find.text(l10n.lease_terminated_ok), findsOneWidget);
    // The closed lease hides the terminate action.
    expect(find.byKey(const ValueKey('leaseTerminate')), findsNothing);
  });

  testWidgets('cancelling the terminate dialog does not call the repo',
      (tester) async {
    tallView(tester);
    final repo = _FakeLeaseRepo(
      lease: const Lease(id: 'l-1', rent: 26000, status: LeaseStatus.active),
    );
    await tester.pumpWidget(harness(repo));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('leaseTerminate')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.lease_terminate_cancel));
    await tester.pumpAndSettle();

    expect(repo.terminateCalls, 0);
    expect(find.byKey(const ValueKey('leaseTerminate')), findsOneWidget);
  });

  testWidgets('shows the error state when the lease fails to load',
      (tester) async {
    tallView(tester);
    final repo = _FakeLeaseRepo(
      lease: const Lease(id: 'l-1'),
      failGet: true,
    );
    await tester.pumpWidget(harness(repo));
    await tester.pumpAndSettle();

    expect(find.text(l10n.common_network_error), findsOneWidget);
    expect(find.text(l10n.common_retry), findsOneWidget);
  });
}
