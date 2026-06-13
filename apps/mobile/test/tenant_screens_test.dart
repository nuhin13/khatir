import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khatir_mobile/core/i18n/locale_provider.dart';
import 'package:khatir_mobile/features/tenant/data/models/models.dart';
import 'package:khatir_mobile/features/tenant/data/models/tenant_enums.dart';
import 'package:khatir_mobile/features/tenant/data/tenant_providers.dart';
import 'package:khatir_mobile/features/tenant/presentation/screens/ten_home_screen.dart';
import 'package:khatir_mobile/features/tenant/presentation/screens/ten_lease_screen.dart';
import 'package:khatir_mobile/features/tenant/presentation/screens/ten_maint_screen.dart';
import 'package:khatir_mobile/features/tenant/presentation/screens/ten_receipts_screen.dart';
import 'package:khatir_mobile/features/tenant/presentation/screens/ten_record_screen.dart';
import 'package:khatir_mobile/l10n/app_localizations.dart';

// ── Test fixtures ──────────────────────────────────────────────────────────

final _stubLease = TenantLease(
  id: 'l1',
  unitId: 'u1',
  unitLabel: 'Flat 4B',
  buildingLabel: 'Karim Manzil',
  landlordName: 'Abdul Karim',
  landlordPhone: '01711-000111',
  monthlyRent: 26000,
  advanceAmount: 52000,
  startDate: DateTime(2026, 3, 1),
  noticePeriod: '2 months',
);

final _stubRent = TenantRent(
  id: 'r1',
  period: '2026-06',
  status: RentStatus.due,
  amountDue: 26000,
  amountPaid: 0,
  dueDate: DateTime(2026, 6, 5),
);

final _stubReceiptPaid = TenantReceipt(
  id: 'rc1',
  period: '2026-05',
  amount: 26000,
  receiptRef: 'https://storage.example.com/rc1.pdf',
  verifiedAt: DateTime(2026, 5, 10),
);

final _stubRecord = TenantRecord(
  id: 'rec1',
  rating: 4,
  notes: 'Good experience',
  consent: RecordConsent.private,
  onTimeMonths: 3,
  completedLeases: 1,
  averageRating: 4.2,
  disputes: 0,
);

// ── Test helpers ───────────────────────────────────────────────────────────

Widget _wrap(
  Widget child, {
  List<Override> overrides = const [],
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('bn')],
      locale: kLocaleEn,
      home: child,
    ),
  );
}

// ── Tests ──────────────────────────────────────────────────────────────────

void main() {
  group('TenHomeScreen', () {
    testWidgets('renders rent hero when rent is due', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const TenHomeScreen(),
          overrides: [
            myRentProvider.overrideWith(
              (ref) async => _stubRent,
            ),
            myLeaseProvider.overrideWith(
              (ref) async => _stubLease,
            ),
            myReceiptsProvider.overrideWith(
              (ref) async => [_stubReceiptPaid],
            ),
          ],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Greeting should appear.
      expect(find.textContaining('আসসালামু'), findsOneWidget);
      // Lease label should appear.
      expect(find.textContaining('আমার লিজ'), findsOneWidget);
    });

    testWidgets('renders paid state when rent is paid', (tester) async {
      final paidRent = TenantRent(
        id: 'r1',
        period: '2026-06',
        status: RentStatus.paid,
        amountDue: 0,
        amountPaid: 26000,
      );
      await tester.pumpWidget(
        _wrap(
          const TenHomeScreen(),
          overrides: [
            myRentProvider.overrideWith((ref) async => paidRent),
            myLeaseProvider.overrideWith((ref) async => _stubLease),
            myReceiptsProvider.overrideWith((ref) async => []),
          ],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Paid chip label should appear.
      expect(find.textContaining('পরিশোধিত'), findsWidgets);
    });

    testWidgets('renders empty lease state gracefully', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const TenHomeScreen(),
          overrides: [
            myRentProvider.overrideWith((ref) async => null),
            myLeaseProvider.overrideWith((ref) async => null),
            myReceiptsProvider.overrideWith((ref) async => []),
          ],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.textContaining('No active lease'), findsOneWidget);
    });

    testWidgets('shows quick actions grid', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const TenHomeScreen(),
          overrides: [
            myRentProvider.overrideWith((ref) async => _stubRent),
            myLeaseProvider.overrideWith((ref) async => _stubLease),
            myReceiptsProvider.overrideWith((ref) async => []),
          ],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.textContaining('দ্রুত কাজ'), findsOneWidget);
      expect(find.textContaining('মেরামত চাই'), findsOneWidget);
    });
  });

  group('TenLeaseScreen', () {
    testWidgets('renders lease details from provider', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const TenLeaseScreen(),
          overrides: [
            myLeaseProvider.overrideWith((ref) async => _stubLease),
          ],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.textContaining('৳26000'), findsOneWidget);
      expect(find.textContaining('Abdul Karim'), findsOneWidget);
      expect(find.textContaining('চলমান'), findsWidgets);
    });

    testWidgets('renders empty state when no lease', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const TenLeaseScreen(),
          overrides: [
            myLeaseProvider.overrideWith((ref) async => null),
          ],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.textContaining('কোনো সক্রিয় লিজ নেই'), findsOneWidget);
    });

    testWidgets('does NOT show PDF button when leaseDocumentRef is null',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          const TenLeaseScreen(),
          overrides: [
            myLeaseProvider.overrideWith((ref) async => _stubLease),
          ],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // _stubLease has no leaseDocumentRef → PDF button must not appear.
      expect(find.textContaining('চুক্তি PDF'), findsNothing);
    });

    testWidgets('shows PDF button when leaseDocumentRef is set', (tester) async {
      final leaseWithDoc = _stubLease.copyWith(
        leaseDocumentRef: 'https://storage.example.com/lease.pdf',
      );
      await tester.pumpWidget(
        _wrap(
          const TenLeaseScreen(),
          overrides: [
            myLeaseProvider.overrideWith((ref) async => leaseWithDoc),
          ],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.textContaining('চুক্তি PDF'), findsOneWidget);
    });
  });

  group('TenMaintScreen', () {
    testWidgets('renders form with category chips and description field',
        (tester) async {
      await tester.pumpWidget(_wrap(const TenMaintScreen()));
      await tester.pump();

      expect(find.textContaining('🚿'), findsOneWidget);
      expect(find.textContaining('💡'), findsOneWidget);
      expect(find.textContaining('🔧'), findsOneWidget);
      expect(find.textContaining('What needs fixing?'), findsOneWidget);
    });

    testWidgets('submit button is present', (tester) async {
      await tester.pumpWidget(_wrap(const TenMaintScreen()));
      await tester.pump();

      expect(find.textContaining('অনুরোধ পাঠান'), findsOneWidget);
    });
  });

  group('TenReceiptsScreen', () {
    testWidgets('renders paid receipt rows', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const TenReceiptsScreen(),
          overrides: [
            myReceiptsProvider.overrideWith(
              (ref) async => [_stubReceiptPaid],
            ),
          ],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.textContaining('2026-05'), findsOneWidget);
      expect(find.textContaining('✓ পরিশোধিত'), findsOneWidget);
    });

    testWidgets('renders empty state when no receipts', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const TenReceiptsScreen(),
          overrides: [
            myReceiptsProvider.overrideWith((ref) async => []),
          ],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.textContaining('কোনো রসিদ নেই'), findsOneWidget);
    });
  });

  group('TenRecordScreen', () {
    testWidgets('renders star rating and notes field for existing record',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          const TenRecordScreen(),
          overrides: [
            myRecordControllerProvider.overrideWith(
              () => _FakeRecordController(_stubRecord),
            ),
          ],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.textContaining('রেটিং'), findsOneWidget);
      // Good experience note.
      expect(find.textContaining('Good experience'), findsOneWidget);
      // Consent toggle row.
      expect(find.textContaining('পরবর্তী মালিককে'), findsOneWidget);
      // Save button.
      expect(find.textContaining('সংরক্ষণ'), findsOneWidget);
    });

    testWidgets('renders first-time empty form gracefully', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const TenRecordScreen(),
          overrides: [
            myRecordControllerProvider.overrideWith(
              () => _FakeRecordController(null),
            ),
          ],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.textContaining('রেটিং'), findsOneWidget);
      expect(find.textContaining('সংরক্ষণ'), findsOneWidget);
    });

    testWidgets('displays privacy note', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const TenRecordScreen(),
          overrides: [
            myRecordControllerProvider.overrideWith(
              () => _FakeRecordController(_stubRecord),
            ),
          ],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Privacy notice.
      expect(find.textContaining('শুধু আপনার সম্মতিতে'), findsOneWidget);
    });
  });
}

/// Fake controller that returns a canned record so tests never hit the network.
class _FakeRecordController extends MyRecordController {
  _FakeRecordController(this._record);

  final TenantRecord? _record;

  @override
  Future<TenantRecord?> build() async => _record;

  @override
  Future<void> save({
    required int rating,
    required String notes,
    required RecordConsent consent,
  }) async {
    state = AsyncValue.data(_record);
  }
}
