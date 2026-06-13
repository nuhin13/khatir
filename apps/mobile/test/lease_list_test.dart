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
import 'package:khatir_mobile/features/leases/presentation/screens/lease_list_screen.dart';
import 'package:khatir_mobile/l10n/app_localizations.dart';

/// A lease repository that serves a fixed lease list (or throws) without a
/// network, so the list screen's states can be driven deterministically.
class _FakeLeaseRepo extends LeaseRepository {
  _FakeLeaseRepo({this.leases = const [], this.fail = false}) : super(Dio());

  final List<Lease> leases;
  final bool fail;

  @override
  Future<List<Lease>> listLeases() async {
    if (fail) throw Exception('boom');
    return leases;
  }
}

void main() {
  late AppLocalizations l10n;

  setUp(() async {
    l10n = await AppLocalizations.delegate.load(kLocaleEn);
  });

  final leases = [
    const Lease(id: 'l-1', rent: 26000, status: LeaseStatus.active),
    const Lease(id: 'l-2', rent: 18000, status: LeaseStatus.ended),
  ];

  Widget harness({List<Lease> data = const [], bool fail = false}) {
    return ProviderScope(
      overrides: [
        leaseRepositoryProvider.overrideWithValue(
          _FakeLeaseRepo(leases: data, fail: fail),
        ),
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
        home: const LeaseListScreen(),
      ),
    );
  }

  testWidgets('renders a card per lease with its status chip', (tester) async {
    await tester.pumpWidget(harness(data: leases));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('lease-l-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('lease-l-2')), findsOneWidget);
    expect(find.text(l10n.lease_status_active), findsOneWidget);
    expect(find.text(l10n.lease_status_ended), findsOneWidget);
  });

  testWidgets('shows the empty state when there are no leases', (tester) async {
    await tester.pumpWidget(harness(data: const []));
    await tester.pumpAndSettle();

    expect(find.text(l10n.leases_empty_title), findsOneWidget);
    expect(find.byType(InkWell), findsNothing);
  });

  testWidgets('shows the error state with a retry affordance', (tester) async {
    await tester.pumpWidget(harness(fail: true));
    await tester.pumpAndSettle();

    expect(find.text(l10n.common_network_error), findsOneWidget);
    expect(find.text(l10n.common_retry), findsOneWidget);
  });
}
