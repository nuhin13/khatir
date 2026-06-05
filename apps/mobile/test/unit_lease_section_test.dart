import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khatir_mobile/core/i18n/locale_provider.dart';
import 'package:khatir_mobile/features/leases/data/lease_repository.dart';
import 'package:khatir_mobile/features/leases/data/models/lease_enums.dart';
import 'package:khatir_mobile/features/leases/data/models/models.dart';
import 'package:khatir_mobile/features/leases/data/providers.dart';
import 'package:khatir_mobile/features/leases/presentation/screens/lease_detail_screen.dart';
import 'package:khatir_mobile/features/leases/presentation/screens/lease_form_screen.dart';
import 'package:khatir_mobile/features/leases/presentation/widgets/unit_lease_section.dart';
import 'package:khatir_mobile/features/rent/presentation/screens/rent_request_screen.dart';
import 'package:khatir_mobile/features/tenants/data/models/tenant_enums.dart';
import 'package:khatir_mobile/l10n/app_localizations.dart';

/// A lease repository that serves a fixed unit-lease + schedule (or 404s),
/// recording the unit/lease it was asked for so the unit-scoped read can be
/// asserted without a network.
class _FakeLeaseRepo extends LeaseRepository {
  _FakeLeaseRepo({this.unitLease, this.schedule = const []}) : super(Dio());

  final UnitLease? unitLease;
  final List<RentSchedule> schedule;
  String? lastUnitId;
  String? lastScheduleLeaseId;

  @override
  Future<UnitLease> getUnitLease(String unitId) async {
    lastUnitId = unitId;
    final value = unitLease;
    if (value == null) throw Exception('no active lease');
    return value;
  }

  @override
  Future<List<RentSchedule>> getSchedule(String id) async {
    lastScheduleLeaseId = id;
    return schedule;
  }
}

void main() {
  late AppLocalizations l10n;

  setUp(() async {
    l10n = await AppLocalizations.delegate.load(kLocaleEn);
  });

  final activeLease = UnitLease(
    lease: Lease(
      id: 'lease-1',
      unitId: 'u1',
      tenantId: 't1',
      rent: 22000,
      status: LeaseStatus.active,
      startDate: DateTime(2025, 1, 1),
      endDate: DateTime(2025, 12, 31),
    ),
    tenant: const LeaseTenantSummary(
      id: 't1',
      name: 'Karim Hossain',
      verificationStatus: VerificationStatus.matched,
    ),
  );

  final schedule = [
    RentSchedule(
      id: 's-paid',
      leaseId: 'lease-1',
      period: '2025-01',
      amount: 22000,
      status: RentScheduleStatus.paid,
      dueDate: DateTime(2025, 1, 5),
    ),
    RentSchedule(
      id: 's-next',
      leaseId: 'lease-1',
      period: '2025-02',
      amount: 22000,
      status: RentScheduleStatus.pending,
      dueDate: DateTime(2025, 2, 5),
    ),
    RentSchedule(
      id: 's-later',
      leaseId: 'lease-1',
      period: '2025-03',
      amount: 22000,
      status: RentScheduleStatus.pending,
      dueDate: DateTime(2025, 3, 5),
    ),
  ];

  Widget harness({required _FakeLeaseRepo repo}) {
    final router = GoRouter(
      initialLocation: '/unit',
      routes: [
        GoRoute(
          path: '/unit',
          builder: (context, state) => const Scaffold(
            body: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: UnitLeaseSection(unitId: 'u1'),
            ),
          ),
        ),
        GoRoute(
          path: LeaseFormScreen.routePath,
          name: LeaseFormScreen.routeName,
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('LEASE_FORM_ROUTE'))),
        ),
        GoRoute(
          path: LeaseDetailScreen.routePath,
          name: LeaseDetailScreen.routeName,
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('LEASE_DETAIL_ROUTE'))),
        ),
        GoRoute(
          path: RentRequestScreen.routePath,
          name: RentRequestScreen.routeName,
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('RENT_REQUEST_ROUTE'))),
        ),
      ],
    );

    return ProviderScope(
      overrides: [leaseRepositoryProvider.overrideWithValue(repo)],
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

  testWidgets('shows the active lease: tenant, rent and next due', (tester) async {
    final repo = _FakeLeaseRepo(unitLease: activeLease, schedule: schedule);
    await tester.pumpWidget(harness(repo: repo));
    await tester.pumpAndSettle();

    // Heading + tenant.
    expect(find.text(l10n.unit_lease_active), findsOneWidget);
    expect(find.text('Karim Hossain'), findsOneWidget);
    expect(find.text(l10n.unit_tenant_verified), findsOneWidget);

    // The active status chip and the request-rent CTA.
    expect(find.text(l10n.lease_status_active), findsOneWidget);
    expect(find.text(l10n.unit_lease_request_rent), findsOneWidget);

    // The next-due period is the earliest unpaid row (2025-02), not the paid one.
    expect(
      find.text(l10n.unit_next_due_value('22,000', '2025-02')),
      findsOneWidget,
    );

    // Reads are unit-/lease-scoped.
    expect(repo.lastUnitId, 'u1');
    expect(repo.lastScheduleLeaseId, 'lease-1');
  });

  testWidgets('all-paid schedule shows the no-upcoming line', (tester) async {
    final paidOnly = [
      RentSchedule(
        id: 's1',
        leaseId: 'lease-1',
        period: '2025-01',
        amount: 22000,
        status: RentScheduleStatus.paid,
        dueDate: DateTime(2025, 1, 5),
      ),
    ];
    await tester.pumpWidget(
      harness(repo: _FakeLeaseRepo(unitLease: activeLease, schedule: paidOnly)),
    );
    await tester.pumpAndSettle();

    expect(find.text(l10n.unit_next_due_none), findsOneWidget);
  });

  testWidgets('no active lease shows the create-lease empty state',
      (tester) async {
    await tester.pumpWidget(harness(repo: _FakeLeaseRepo()));
    await tester.pumpAndSettle();

    expect(find.text(l10n.unit_lease_none), findsOneWidget);
    expect(find.text(l10n.unit_create_lease), findsOneWidget);
    // No active-lease content when there is no lease.
    expect(find.text(l10n.unit_lease_request_rent), findsNothing);
  });

  testWidgets('create-lease CTA routes to the lease form', (tester) async {
    await tester.pumpWidget(harness(repo: _FakeLeaseRepo()));
    await tester.pumpAndSettle();

    await tester.tap(find.text(l10n.unit_create_lease));
    await tester.pumpAndSettle();

    expect(find.text('LEASE_FORM_ROUTE'), findsOneWidget);
  });

  testWidgets('request-rent CTA routes to the rent-request screen',
      (tester) async {
    await tester.pumpWidget(
      harness(repo: _FakeLeaseRepo(unitLease: activeLease, schedule: schedule)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(l10n.unit_lease_request_rent));
    await tester.pumpAndSettle();

    expect(find.text('RENT_REQUEST_ROUTE'), findsOneWidget);
  });

  testWidgets('tapping the lease card opens lease detail', (tester) async {
    await tester.pumpWidget(
      harness(repo: _FakeLeaseRepo(unitLease: activeLease, schedule: schedule)),
    );
    await tester.pumpAndSettle();

    // Tap the tenant name (inside the tappable card) — avoid the CTA button.
    await tester.tap(find.text('Karim Hossain'));
    await tester.pumpAndSettle();

    expect(find.text('LEASE_DETAIL_ROUTE'), findsOneWidget);
  });
}
