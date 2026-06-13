import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khatir_mobile/core/i18n/locale_provider.dart';
import 'package:khatir_mobile/features/maintenance/data/maintenance_repository.dart';
import 'package:khatir_mobile/features/maintenance/data/models/maintenance_enums.dart';
import 'package:khatir_mobile/features/maintenance/data/models/models.dart';
import 'package:khatir_mobile/features/maintenance/data/providers.dart';
import 'package:khatir_mobile/features/maintenance/presentation/screens/maintenance_queue_screen.dart';
import 'package:khatir_mobile/l10n/app_localizations.dart';

/// A maintenance repository that serves a fixed queue (or throws) and records
/// the resolve calls it receives, so the queue screen + resolve dialog can be
/// driven deterministically without a network.
class _FakeMaintenanceRepo extends MaintenanceRepository {
  _FakeMaintenanceRepo({this.requests = const [], this.fail = false})
      : super(Dio());

  final List<MaintenanceRequest> requests;
  final bool fail;
  final List<({String id, double cost, String? note})> resolveCalls = [];

  @override
  Future<List<MaintenanceRequest>> listQueue({
    MaintenanceStatus? status,
    String? unitId,
  }) async {
    if (fail) throw Exception('boom');
    return requests;
  }

  @override
  Future<MaintenanceRequest> getRequest(String id) async =>
      requests.firstWhere((r) => r.id == id);

  @override
  Future<MaintenanceRequest> resolve(
    String id, {
    required double cost,
    String? note,
  }) async {
    resolveCalls.add((id: id, cost: cost, note: note));
    return requests
        .firstWhere((r) => r.id == id)
        .copyWith(status: MaintenanceStatus.resolved, resolutionCost: cost);
  }
}

void main() {
  late AppLocalizations l10n;

  setUp(() async {
    l10n = await AppLocalizations.delegate.load(kLocaleEn);
  });

  final requests = [
    const MaintenanceRequest(
      id: 'm-1',
      unitId: '2C',
      category: MaintenanceCategory.plumbing,
      description: 'Water pipe leaking',
      status: MaintenanceStatus.open,
    ),
    const MaintenanceRequest(
      id: 'm-2',
      unitId: '4B',
      category: MaintenanceCategory.electrical,
      description: 'Bathroom light broken',
      status: MaintenanceStatus.open,
    ),
  ];

  Widget harness({
    required _FakeMaintenanceRepo repo,
    Future<void> Function(ResolveDraft draft)? onResolve,
  }) {
    return ProviderScope(
      overrides: [
        maintenanceRepositoryProvider.overrideWithValue(repo),
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
        home: MaintenanceQueueScreen(onResolve: onResolve),
      ),
    );
  }

  testWidgets('renders a card per open request with its description',
      (tester) async {
    await tester
        .pumpWidget(harness(repo: _FakeMaintenanceRepo(requests: requests)));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('maintenance-m-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('maintenance-m-2')), findsOneWidget);
    expect(find.text('Water pipe leaking'), findsOneWidget);
    expect(find.text('Bathroom light broken'), findsOneWidget);
    // Each open request offers a resolve action.
    expect(
      find.byKey(const ValueKey('maintenanceResolve-m-1')),
      findsOneWidget,
    );
  });

  testWidgets('shows the empty state when the queue is empty', (tester) async {
    await tester.pumpWidget(
      harness(repo: _FakeMaintenanceRepo(requests: const [])),
    );
    await tester.pumpAndSettle();

    expect(find.text(l10n.maintenance_empty), findsOneWidget);
    expect(find.byKey(const ValueKey('maintenance-m-1')), findsNothing);
  });

  testWidgets('shows the error state with a retry affordance', (tester) async {
    await tester.pumpWidget(harness(repo: _FakeMaintenanceRepo(fail: true)));
    await tester.pumpAndSettle();

    expect(find.text(l10n.common_network_error), findsOneWidget);
    expect(find.text(l10n.common_retry), findsOneWidget);
  });

  testWidgets(
      'resolving validates the cost, then fires the resolve callback with '
      'the entered cost + note', (tester) async {
    ResolveDraft? draft;
    await tester.pumpWidget(harness(
      repo: _FakeMaintenanceRepo(requests: requests),
      onResolve: (d) async => draft = d,
    ));
    await tester.pumpAndSettle();

    // Open the resolve dialog for the first request.
    await tester.tap(find.byKey(const ValueKey('maintenanceResolve-m-1')));
    await tester.pumpAndSettle();

    // Confirming with no cost surfaces the validation error and does not resolve.
    await tester.tap(find.byKey(const ValueKey('maintenanceResolveConfirm')));
    await tester.pumpAndSettle();
    expect(find.text(l10n.maintenance_err_cost), findsOneWidget);
    expect(draft, isNull);

    // Enter a valid cost + note and confirm.
    await tester.enterText(
      find.byKey(const ValueKey('maintenanceCost')),
      '3500',
    );
    await tester.enterText(
      find.byKey(const ValueKey('maintenanceNote')),
      'Replaced pipe',
    );
    await tester.tap(find.byKey(const ValueKey('maintenanceResolveConfirm')));
    await tester.pumpAndSettle();

    expect(draft, isNotNull);
    expect(draft!.requestId, 'm-1');
    expect(draft!.cost, 3500);
    expect(draft!.note, 'Replaced pipe');
  });

  testWidgets(
      'the real resolve flow records the cost on the repository '
      '(auto-creates one expense server-side)', (tester) async {
    final repo = _FakeMaintenanceRepo(requests: requests);
    await tester.pumpWidget(harness(repo: repo));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('maintenanceResolve-m-2')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('maintenanceCost')),
      '4200',
    );
    await tester.tap(find.byKey(const ValueKey('maintenanceResolveConfirm')));
    await tester.pumpAndSettle();

    expect(repo.resolveCalls.length, 1);
    expect(repo.resolveCalls.single.id, 'm-2');
    expect(repo.resolveCalls.single.cost, 4200);
    // The resolve confirmation is surfaced.
    expect(find.text(l10n.maintenance_resolved), findsOneWidget);
  });

  testWidgets('cancelling the resolve dialog does not resolve', (tester) async {
    final repo = _FakeMaintenanceRepo(requests: requests);
    await tester.pumpWidget(harness(repo: repo));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('maintenanceResolve-m-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('maintenanceResolveCancel')));
    await tester.pumpAndSettle();

    expect(repo.resolveCalls, isEmpty);
  });
}
