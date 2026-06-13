import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khatir_mobile/core/network/api_endpoints.dart';
import 'package:khatir_mobile/core/network/api_exception.dart';
import 'package:khatir_mobile/core/network/dio_client.dart';
import 'package:khatir_mobile/core/storage/secure_storage.dart';
import 'package:khatir_mobile/features/tenant/data/models/models.dart';
import 'package:khatir_mobile/features/tenant/data/models/tenant_enums.dart';
import 'package:khatir_mobile/features/tenant/data/tenant_providers.dart';

// ── In-memory secure storage ───────────────────────────────────────────────

class _FakeSecureStorage implements SecureStorage {
  String? access = 'a';
  String? refresh = 'r';

  @override
  Future<void> writeTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    access = accessToken;
    refresh = refreshToken;
  }

  @override
  Future<String?> readAccessToken() async => access;
  @override
  Future<String?> readRefreshToken() async => refresh;
  @override
  Future<void> clear() async {
    access = null;
    refresh = null;
  }
}

// ── Scripted adapter ───────────────────────────────────────────────────────

class _ScriptedAdapter implements HttpClientAdapter {
  _ScriptedAdapter(this.handler);

  final ResponseBody Function(RequestOptions) handler;
  final List<RequestOptions> requests = [];

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return handler(options);
  }
}

ResponseBody _json(Object body, {int status = 200}) =>
    ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

ProviderContainer _container(HttpClientAdapter adapter) {
  final container = ProviderContainer(
    overrides: [
      secureStorageProvider.overrideWithValue(_FakeSecureStorage()),
    ],
  );
  addTearDown(container.dispose);
  container.read(dioClientProvider).httpClientAdapter = adapter;
  return container;
}

// ── Fixture helpers ────────────────────────────────────────────────────────

Map<String, dynamic> _leaseJson({String id = 'l1', String status = 'active'}) =>
    {
      'id': id,
      'unit_id': 'u1',
      'unit_label': 'Flat 4B',
      'building_label': 'Karim Manzil',
      'landlord_name': 'Abdul Karim',
      'landlord_phone': '01711-000111',
      'monthly_rent': '26000.00',
      'advance_amount': '52000.00',
      'start_date': '2026-03-01',
      'end_date': null,
      'notice_period': '2 months',
      'terms': '',
      'lease_document_ref': null,
      'created_at': '2026-03-01T00:00:00Z',
      'updated_at': '2026-03-01T00:00:00Z',
    };

Map<String, dynamic> _rentJson({String status = 'due'}) => {
      'id': 'r1',
      'period': '2026-06',
      'status': status,
      'amount_due': '26000.00',
      'amount_paid': '0.00',
      'due_date': '2026-06-05',
      'paid_at': null,
      'created_at': '2026-06-01T00:00:00Z',
      'updated_at': '2026-06-01T00:00:00Z',
    };

Map<String, dynamic> _receiptJson({String id = 'rc1', String period = '2026-05'}) =>
    {
      'id': id,
      'period': period,
      'amount': '26000.00',
      'receipt_ref': 'https://storage.example.com/rc1.pdf',
      'verified_at': '2026-05-10T00:00:00Z',
      'created_at': '2026-05-01T00:00:00Z',
      'updated_at': '2026-05-10T00:00:00Z',
    };

Map<String, dynamic> _recordJson({int rating = 4, String consent = 'private'}) =>
    {
      'id': 'rec1',
      'rating': rating,
      'notes': 'Good experience',
      'consent': consent,
      'on_time_months': 3,
      'completed_leases': 1,
      'average_rating': 4.2,
      'disputes': 0,
      'created_at': '2026-06-01T00:00:00Z',
      'updated_at': '2026-06-01T00:00:00Z',
    };

Map<String, dynamic> _maintJson({String id = 'm1'}) => {
      'id': id,
      'description': 'Leaky tap',
      'category': 'plumbing',
      'photo_ref': '',
      'status': 'open',
      'created_at': '2026-06-01T00:00:00Z',
      'updated_at': '2026-06-01T00:00:00Z',
    };

// ── Tests ──────────────────────────────────────────────────────────────────

void main() {
  group('TenantRepository', () {
    test('myLease returns parsed TenantLease on 200', () async {
      final adapter = _ScriptedAdapter((opts) {
        if (opts.path == ApiEndpoints.myLease && opts.method == 'GET') {
          return _json(_leaseJson());
        }
        return _json(<String, dynamic>{}, status: 404);
      });
      final container = _container(adapter);
      final repo = container.read(tenantRepositoryProvider);

      final lease = await repo.myLease();

      expect(lease, isNotNull);
      expect(lease!.id, 'l1');
      expect(lease.landlordName, 'Abdul Karim');
      expect(lease.monthlyRent, 26000.0);
      expect(lease.advanceAmount, 52000.0);
      expect(lease.startDate, DateTime(2026, 3, 1));
    });

    test('myLease returns null on 404', () async {
      final adapter =
          _ScriptedAdapter((_) => _json(<String, dynamic>{}, status: 404));
      final container = _container(adapter);
      final repo = container.read(tenantRepositoryProvider);

      final lease = await repo.myLease();

      expect(lease, isNull);
    });

    test('myRent returns parsed TenantRent with correct status', () async {
      final adapter = _ScriptedAdapter((opts) {
        if (opts.path == ApiEndpoints.myRent && opts.method == 'GET') {
          return _json(_rentJson(status: 'overdue'));
        }
        return _json(<String, dynamic>{}, status: 404);
      });
      final container = _container(adapter);
      final repo = container.read(tenantRepositoryProvider);

      final rent = await repo.myRent();

      expect(rent, isNotNull);
      expect(rent!.status, RentStatus.overdue);
      expect(rent.amountDue, 26000.0);
    });

    test('myReceipts unwraps results list', () async {
      final adapter = _ScriptedAdapter((opts) {
        if (opts.path == ApiEndpoints.myReceipts && opts.method == 'GET') {
          return _json({
            'results': [
              _receiptJson(id: 'rc1', period: '2026-05'),
              _receiptJson(id: 'rc2', period: '2026-04'),
            ],
            'pagination': {'next': null, 'previous': null, 'count': 2},
          });
        }
        return _json(<String, dynamic>{}, status: 404);
      });
      final container = _container(adapter);
      final repo = container.read(tenantRepositoryProvider);

      final receipts = await repo.myReceipts();

      expect(receipts, hasLength(2));
      expect(receipts.first.id, 'rc1');
      expect(receipts.first.amount, 26000.0);
      expect(receipts.last.period, '2026-04');
    });

    test('myRecord returns parsed TenantRecord', () async {
      final adapter = _ScriptedAdapter((opts) {
        if (opts.path == ApiEndpoints.myRecord && opts.method == 'GET') {
          return _json(_recordJson());
        }
        return _json(<String, dynamic>{}, status: 404);
      });
      final container = _container(adapter);
      final repo = container.read(tenantRepositoryProvider);

      final record = await repo.myRecord();

      expect(record, isNotNull);
      expect(record!.rating, 4);
      expect(record.consent, RecordConsent.private);
      expect(record.onTimeMonths, 3);
    });

    test('createRecord sends correct body and returns TenantRecord', () async {
      RequestOptions? post;
      final adapter = _ScriptedAdapter((opts) {
        if (opts.path == ApiEndpoints.myRecord && opts.method == 'POST') {
          post = opts;
          return _json(_recordJson(rating: 5, consent: 'shared'), status: 201);
        }
        return _json(<String, dynamic>{}, status: 404);
      });
      final container = _container(adapter);
      final repo = container.read(tenantRepositoryProvider);

      final record = await repo.createRecord(
        rating: 5,
        notes: 'Great',
        consent: RecordConsent.shared,
      );

      final body = post!.data as Map<String, dynamic>;
      expect(body['rating'], 5);
      expect(body['consent'], 'shared');
      expect(record.rating, 5);
      expect(record.consent, RecordConsent.shared);
    });

    test('updateRecord sends only provided fields', () async {
      RequestOptions? patch;
      final adapter = _ScriptedAdapter((opts) {
        if (opts.path == ApiEndpoints.myRecord && opts.method == 'PATCH') {
          patch = opts;
          return _json(_recordJson());
        }
        return _json(<String, dynamic>{}, status: 404);
      });
      final container = _container(adapter);
      final repo = container.read(tenantRepositoryProvider);

      await repo.updateRecord(rating: 3);

      final body = patch!.data as Map<String, dynamic>;
      expect(body, {'rating': 3});
      expect(body.containsKey('notes'), isFalse);
      expect(body.containsKey('consent'), isFalse);
    });

    test('reportMaintenance posts description + category', () async {
      RequestOptions? post;
      final adapter = _ScriptedAdapter((opts) {
        if (opts.path == ApiEndpoints.myMaintenanceReports &&
            opts.method == 'POST') {
          post = opts;
          return _json(_maintJson(), status: 201);
        }
        return _json(<String, dynamic>{}, status: 404);
      });
      final container = _container(adapter);
      final repo = container.read(tenantRepositoryProvider);

      final report = await repo.reportMaintenance(
        description: 'Leaky tap',
        category: TenantMaintenanceCategory.plumbing,
      );

      final body = post!.data as Map<String, dynamic>;
      expect(body['description'], 'Leaky tap');
      expect(body['category'], 'plumbing');
      expect(body.containsKey('photo_ref'), isFalse);
      expect(report.id, 'm1');
      expect(report.category, TenantMaintenanceCategory.plumbing);
    });

    test('submitProof posts proof_type and value', () async {
      RequestOptions? post;
      final adapter = _ScriptedAdapter((opts) {
        if (opts.path == ApiEndpoints.myRentPay('r1') &&
            opts.method == 'POST') {
          post = opts;
          return _json(_rentJson(status: 'pending_verification'));
        }
        return _json(<String, dynamic>{}, status: 404);
      });
      final container = _container(adapter);
      final repo = container.read(tenantRepositoryProvider);

      await repo.submitProof(
        rentId: 'r1',
        proofType: PayProofType.txnId,
        value: 'TXN123',
      );

      final body = post!.data as Map<String, dynamic>;
      expect(body['proof_type'], 'txn_id');
      expect(body['value'], 'TXN123');
    });
  });

  group('model + enum parsing', () {
    test('TenantLease tolerates missing fields', () {
      final lease = TenantLease.fromJson({'id': 'x'});
      expect(lease.id, 'x');
      expect(lease.monthlyRent, 0);
      expect(lease.landlordName, '');
      expect(lease.leaseDocumentRef, isNull);
    });

    test('TenantRent degrades unknown status to due', () {
      final rent = TenantRent.fromJson({'id': 'r', 'status': 'totally_new'});
      expect(rent.status, RentStatus.due);
    });

    test('TenantRent parses paid status', () {
      final rent = TenantRent.fromJson({'id': 'r', 'status': 'paid'});
      expect(rent.status, RentStatus.paid);
    });

    test('TenantReceipt parses amount string', () {
      final receipt = TenantReceipt.fromJson({'id': 'rc', 'amount': '1200.50'});
      expect(receipt.amount, 1200.5);
    });

    test('TenantRecord defaults to private consent', () {
      final record = TenantRecord.fromJson({'id': 'rec'});
      expect(record.consent, RecordConsent.private);
      expect(record.rating, 0);
    });

    test('RecordConsent.shared parses correctly', () {
      final record = TenantRecord.fromJson({'id': 'rec', 'consent': 'shared'});
      expect(record.consent, RecordConsent.shared);
    });

    test('TenantMaintenanceReport defaults to other category', () {
      final report = TenantMaintenanceReport.fromJson({'id': 'm'});
      expect(report.category, TenantMaintenanceCategory.other);
      expect(report.status, TenantMaintenanceStatus.open);
    });

    test('enum degrades handle unknown values', () {
      expect(RentStatus.fromWire('mystery'), RentStatus.due);
      expect(TenantMaintenanceCategory.fromWire(null), TenantMaintenanceCategory.other);
      expect(TenantMaintenanceStatus.fromWire('mystery'), TenantMaintenanceStatus.open);
      expect(RecordConsent.fromWire('mystery'), RecordConsent.private);
      expect(PayProofType.fromWire('mystery'), PayProofType.note);
      expect(PayProofType.fromWire('txn_id'), PayProofType.txnId);
    });
  });
}
