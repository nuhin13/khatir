import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khatir_mobile/core/network/api_endpoints.dart';
import 'package:khatir_mobile/core/network/api_exception.dart';
import 'package:khatir_mobile/core/network/dio_client.dart';
import 'package:khatir_mobile/core/storage/secure_storage.dart';
import 'package:khatir_mobile/features/leases/data/models/lease_enums.dart';
import 'package:khatir_mobile/features/leases/data/models/models.dart';
import 'package:khatir_mobile/features/leases/data/providers.dart';
import 'package:khatir_mobile/features/tenants/data/models/tenant_enums.dart';

/// In-memory secure storage so tests never touch the platform channel.
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

/// Scriptable adapter: maps a request to a canned response (or status).
class _ScriptedAdapter implements HttpClientAdapter {
  _ScriptedAdapter(this.handler);

  final ResponseBody Function(RequestOptions options) handler;
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

Map<String, dynamic> _leaseJson({
  String id = 'l1',
  String status = 'draft',
}) =>
    {
      'id': id,
      'unit_id': 'u1',
      'tenant_id': 't1',
      'landlord_id': 'o1',
      'start_date': '2026-01-01',
      'end_date': '2026-12-31',
      'rent': '15000.00',
      'advance': '30000.00',
      'status': status,
      'signed_pdf_ref': '',
      'created_at': '2026-01-01T00:00:00Z',
      'updated_at': '2026-01-02T00:00:00Z',
    };

void main() {
  group('LeaseRepository', () {
    test('createLease posts a draft body and parses 201', () async {
      RequestOptions? post;
      final adapter = _ScriptedAdapter((options) {
        if (options.path == ApiEndpoints.leases && options.method == 'POST') {
          post = options;
          return _json(_leaseJson(), status: 201);
        }
        return _json(<String, dynamic>{}, status: 404);
      });
      final container = _container(adapter);

      final lease = await container.read(leaseRepositoryProvider).createLease(
            unitId: 'u1',
            tenantId: 't1',
            startDate: DateTime(2026, 1, 1),
            endDate: DateTime(2026, 12, 31),
            rent: 15000,
          );

      final body = post!.data as Map<String, dynamic>;
      expect(body['unit_id'], 'u1');
      expect(body['tenant_id'], 't1');
      expect(body['start_date'], '2026-01-01');
      expect(body['end_date'], '2026-12-31');
      expect(body['rent'], 15000);
      // advance was not supplied → omitted from the body.
      expect(body.containsKey('advance'), isFalse);

      expect(lease.id, 'l1');
      expect(lease.unitId, 'u1');
      expect(lease.tenantId, 't1');
      expect(lease.landlordId, 'o1');
      expect(lease.rent, 15000.0);
      expect(lease.advance, 30000.0);
      expect(lease.status, LeaseStatus.draft);
      expect(lease.startDate, DateTime(2026, 1, 1));
    });

    test('createLease includes advance when supplied', () async {
      RequestOptions? post;
      final adapter = _ScriptedAdapter((options) {
        if (options.path == ApiEndpoints.leases && options.method == 'POST') {
          post = options;
          return _json(_leaseJson(), status: 201);
        }
        return _json(<String, dynamic>{}, status: 404);
      });
      final container = _container(adapter);

      await container.read(leaseRepositoryProvider).createLease(
            unitId: 'u1',
            tenantId: 't1',
            startDate: DateTime(2026, 1, 1),
            endDate: DateTime(2026, 12, 31),
            rent: 15000,
            advance: 30000,
          );

      final body = post!.data as Map<String, dynamic>;
      expect(body['advance'], 30000);
    });

    test('activateLease posts and parses the activated lease', () async {
      final adapter = _ScriptedAdapter((options) {
        if (options.path == ApiEndpoints.leaseActivate('l1') &&
            options.method == 'POST') {
          return _json(_leaseJson(status: 'active'));
        }
        return _json(<String, dynamic>{}, status: 404);
      });
      final container = _container(adapter);

      final lease =
          await container.read(leaseRepositoryProvider).activateLease('l1');

      expect(lease.status, LeaseStatus.active);
    });

    test('terminateLease sends the chosen status', () async {
      RequestOptions? post;
      final adapter = _ScriptedAdapter((options) {
        if (options.path == ApiEndpoints.leaseTerminate('l1') &&
            options.method == 'POST') {
          post = options;
          return _json(_leaseJson(status: 'ended'));
        }
        return _json(<String, dynamic>{}, status: 404);
      });
      final container = _container(adapter);

      final lease = await container
          .read(leaseRepositoryProvider)
          .terminateLease('l1', status: LeaseStatus.ended);

      expect((post!.data as Map<String, dynamic>)['status'], 'ended');
      expect(lease.status, LeaseStatus.ended);
    });

    test('terminateLease omits status when not given', () async {
      RequestOptions? post;
      final adapter = _ScriptedAdapter((options) {
        if (options.path == ApiEndpoints.leaseTerminate('l1') &&
            options.method == 'POST') {
          post = options;
          return _json(_leaseJson(status: 'terminated'));
        }
        return _json(<String, dynamic>{}, status: 404);
      });
      final container = _container(adapter);

      await container.read(leaseRepositoryProvider).terminateLease('l1');

      expect((post!.data as Map<String, dynamic>).containsKey('status'), isFalse);
    });

    test('updateLease sends only the provided fields', () async {
      RequestOptions? patch;
      final adapter = _ScriptedAdapter((options) {
        if (options.path == ApiEndpoints.lease('l1') &&
            options.method == 'PATCH') {
          patch = options;
          return _json(_leaseJson());
        }
        return _json(<String, dynamic>{}, status: 404);
      });
      final container = _container(adapter);

      await container
          .read(leaseRepositoryProvider)
          .updateLease('l1', rent: 16000);

      final body = patch!.data as Map<String, dynamic>;
      expect(body, {'rent': 16000});
      expect(body.containsKey('advance'), isFalse);
      expect(body.containsKey('start_date'), isFalse);
    });

    test('getSchedule parses a bare array of read-only rows', () async {
      final adapter = _ScriptedAdapter((options) {
        if (options.path == ApiEndpoints.leaseSchedule('l1') &&
            options.method == 'GET') {
          return _json([
            {
              'id': 's1',
              'lease_id': 'l1',
              'period': '2026-01',
              'due_day': 5,
              'due_date': '2026-01-05',
              'amount': '15000.00',
              'status': 'pending',
              'sent_at': null,
              'created_at': '2026-01-01T00:00:00Z',
              'updated_at': '2026-01-01T00:00:00Z',
            },
            {
              'id': 's2',
              'lease_id': 'l1',
              'period': '2026-02',
              'due_day': 5,
              'due_date': '2026-02-05',
              'amount': '15000.00',
              'status': 'paid',
              'sent_at': '2026-02-01T00:00:00Z',
            },
          ]);
        }
        return _json(<String, dynamic>{}, status: 404);
      });
      final container = _container(adapter);

      final rows =
          await container.read(leaseRepositoryProvider).getSchedule('l1');

      expect(rows, hasLength(2));
      expect(rows.first.id, 's1');
      expect(rows.first.period, '2026-01');
      expect(rows.first.dueDay, 5);
      expect(rows.first.amount, 15000.0);
      expect(rows.first.status, RentScheduleStatus.pending);
      expect(rows.first.sentAt, isNull);
      expect(rows.last.status, RentScheduleStatus.paid);
      expect(rows.last.sentAt, isNotNull);
    });

    test('getUnitLease parses the lease + embedded tenant summary', () async {
      final adapter = _ScriptedAdapter((options) {
        if (options.path == ApiEndpoints.unitLease('u1') &&
            options.method == 'GET') {
          final body = _leaseJson(status: 'active');
          body['tenant'] = {
            'id': 't1',
            'name': 'Karim',
            'nid_number_masked': '****7788',
            'verification_status': 'matched',
          };
          return _json(body);
        }
        return _json(<String, dynamic>{}, status: 404);
      });
      final container = _container(adapter);

      final unitLease =
          await container.read(leaseRepositoryProvider).getUnitLease('u1');

      expect(unitLease.lease.id, 'l1');
      expect(unitLease.lease.status, LeaseStatus.active);
      expect(unitLease.tenant, isNotNull);
      expect(unitLease.tenant!.name, 'Karim');
      expect(unitLease.tenant!.nidNumberMasked, '****7788');
      expect(
        unitLease.tenant!.verificationStatus,
        VerificationStatus.matched,
      );
    });

    test('getUnitLease surfaces the no-active-lease 404 as ApiException',
        () async {
      final adapter =
          _ScriptedAdapter((_) => _json(<String, dynamic>{}, status: 404));
      final container = _container(adapter);

      expect(
        () => container.read(leaseRepositoryProvider).getUnitLease('u1'),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 404),
        ),
      );
    });

    test('getLease surfaces a foreign/unknown id 404 as ApiException',
        () async {
      final adapter =
          _ScriptedAdapter((_) => _json(<String, dynamic>{}, status: 404));
      final container = _container(adapter);

      expect(
        () => container.read(leaseRepositoryProvider).getLease('missing'),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 404),
        ),
      );
    });
  });

  group('Lease model parsing', () {
    test('tolerates missing money/status and null dates', () {
      final lease = Lease.fromJson({'id': 'l9'});
      expect(lease.id, 'l9');
      expect(lease.rent, 0);
      expect(lease.advance, 0);
      expect(lease.status, LeaseStatus.draft);
      expect(lease.startDate, isNull);
    });

    test('UnitLease tolerates an absent tenant object', () {
      final unitLease = UnitLease.fromJson(_leaseJson());
      expect(unitLease.lease.id, 'l1');
      expect(unitLease.tenant, isNull);
    });

    test('RentScheduleStatus.fromWire degrades unknown to pending', () {
      expect(RentScheduleStatus.fromWire('whoknows'), RentScheduleStatus.pending);
      expect(RentScheduleStatus.fromWire(null), RentScheduleStatus.pending);
      expect(RentScheduleStatus.fromWire('overdue'), RentScheduleStatus.overdue);
    });

    test('LeaseStatus.fromWire degrades unknown to draft', () {
      expect(LeaseStatus.fromWire('weird'), LeaseStatus.draft);
      expect(LeaseStatus.fromWire('terminated'), LeaseStatus.terminated);
    });
  });
}
