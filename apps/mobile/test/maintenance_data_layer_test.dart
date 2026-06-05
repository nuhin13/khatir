import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khatir_mobile/core/network/api_endpoints.dart';
import 'package:khatir_mobile/core/network/api_exception.dart';
import 'package:khatir_mobile/core/network/dio_client.dart';
import 'package:khatir_mobile/core/storage/secure_storage.dart';
import 'package:khatir_mobile/features/maintenance/data/expense_repository.dart';
import 'package:khatir_mobile/features/maintenance/data/models/maintenance_enums.dart';
import 'package:khatir_mobile/features/maintenance/data/models/models.dart';
import 'package:khatir_mobile/features/maintenance/data/providers.dart';

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

ResponseBody _text(String body, {int status = 200}) =>
    ResponseBody.fromString(
      body,
      status,
      headers: {
        Headers.contentTypeHeader: ['text/csv'],
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

Map<String, dynamic> _requestJson({
  String id = 'm1',
  String status = 'open',
  Object? resolutionCost,
}) =>
    {
      'id': id,
      'unit_id': 'u1',
      'lease_id': 'l1',
      'category': 'plumbing',
      'description': 'Leaky tap',
      'photo_ref': '',
      'status': status,
      'resolved_at': status == 'resolved' ? '2026-06-05T00:00:00Z' : null,
      'resolution_cost': resolutionCost,
      'resolution_note': status == 'resolved' ? 'Fixed' : '',
      'created_at': '2026-06-01T00:00:00Z',
      'updated_at': '2026-06-02T00:00:00Z',
    };

Map<String, dynamic> _expenseJson({
  String id = 'e1',
  String source = 'manual',
}) =>
    {
      'id': id,
      'unit_id': 'u1',
      'request_id': source == 'request' ? 'm1' : null,
      'category': 'paint',
      'amount': '2500.00',
      'date': '2026-06-03',
      'source': source,
      'note': 'Annual paint',
      'receipt_ref': '',
      'created_at': '2026-06-03T00:00:00Z',
      'updated_at': '2026-06-03T00:00:00Z',
    };

void main() {
  group('MaintenanceRepository', () {
    test('listQueue unwraps results and applies the status filter', () async {
      RequestOptions? get;
      final adapter = _ScriptedAdapter((options) {
        if (options.path == ApiEndpoints.maintenance &&
            options.method == 'GET') {
          get = options;
          return _json({
            'results': [_requestJson(), _requestJson(id: 'm2')],
            'pagination': {'next': null, 'previous': null, 'count': 2},
          });
        }
        return _json(<String, dynamic>{}, status: 404);
      });
      final container = _container(adapter);

      final rows = await container
          .read(maintenanceRepositoryProvider)
          .listQueue(status: MaintenanceStatus.open, unitId: 'u1');

      expect(get!.queryParameters['status'], 'open');
      expect(get!.queryParameters['unit'], 'u1');
      expect(rows, hasLength(2));
      expect(rows.first.id, 'm1');
      expect(rows.first.category, MaintenanceCategory.plumbing);
      expect(rows.first.status, MaintenanceStatus.open);
      expect(rows.first.resolutionCost, isNull);
    });

    test('createRequest posts unit_id + description and parses 201', () async {
      RequestOptions? post;
      final adapter = _ScriptedAdapter((options) {
        if (options.path == ApiEndpoints.maintenance &&
            options.method == 'POST') {
          post = options;
          return _json(_requestJson(), status: 201);
        }
        return _json(<String, dynamic>{}, status: 404);
      });
      final container = _container(adapter);

      final req =
          await container.read(maintenanceRepositoryProvider).createRequest(
                unitId: 'u1',
                description: 'Leaky tap',
                category: MaintenanceCategory.plumbing,
              );

      final body = post!.data as Map<String, dynamic>;
      expect(body['unit_id'], 'u1');
      expect(body['description'], 'Leaky tap');
      expect(body['category'], 'plumbing');
      // photo_ref / lease_id not supplied → omitted.
      expect(body.containsKey('photo_ref'), isFalse);
      expect(body.containsKey('lease_id'), isFalse);

      expect(req.id, 'm1');
      expect(req.unitId, 'u1');
      expect(req.status, MaintenanceStatus.open);
    });

    test('updateRequest sends only the provided fields', () async {
      RequestOptions? patch;
      final adapter = _ScriptedAdapter((options) {
        if (options.path == ApiEndpoints.maintenanceRequest('m1') &&
            options.method == 'PATCH') {
          patch = options;
          return _json(_requestJson());
        }
        return _json(<String, dynamic>{}, status: 404);
      });
      final container = _container(adapter);

      await container
          .read(maintenanceRepositoryProvider)
          .updateRequest('m1', description: 'New desc');

      final body = patch!.data as Map<String, dynamic>;
      expect(body, {'description': 'New desc'});
      expect(body.containsKey('category'), isFalse);
    });

    test('resolve posts the cost + note and parses the resolved request',
        () async {
      RequestOptions? post;
      final adapter = _ScriptedAdapter((options) {
        if (options.path == ApiEndpoints.maintenanceResolve('m1') &&
            options.method == 'POST') {
          post = options;
          return _json(
            _requestJson(status: 'resolved', resolutionCost: '1800.00'),
          );
        }
        return _json(<String, dynamic>{}, status: 404);
      });
      final container = _container(adapter);

      final req = await container
          .read(maintenanceRepositoryProvider)
          .resolve('m1', cost: 1800, note: 'Fixed');

      final body = post!.data as Map<String, dynamic>;
      expect(body['cost'], 1800);
      expect(body['note'], 'Fixed');

      expect(req.status, MaintenanceStatus.resolved);
      expect(req.resolutionCost, 1800.0);
      expect(req.resolvedAt, isNotNull);
    });

    test('getRequest surfaces a foreign/unknown id 404 as ApiException',
        () async {
      final adapter =
          _ScriptedAdapter((_) => _json(<String, dynamic>{}, status: 404));
      final container = _container(adapter);

      expect(
        () =>
            container.read(maintenanceRepositoryProvider).getRequest('missing'),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 404),
        ),
      );
    });
  });

  group('ExpenseRepository', () {
    test('listExpenses unwraps results and applies the filter params',
        () async {
      RequestOptions? get;
      final adapter = _ScriptedAdapter((options) {
        if (options.path == ApiEndpoints.expenses && options.method == 'GET') {
          get = options;
          return _json({
            'results': [_expenseJson(), _expenseJson(id: 'e2', source: 'request')],
            'pagination': {'next': null, 'previous': null, 'count': 2},
          });
        }
        return _json(<String, dynamic>{}, status: 404);
      });
      final container = _container(adapter);

      final rows = await container.read(expenseRepositoryProvider).listExpenses(
            filter: ExpenseFilter(
              unitId: 'u1',
              buildingId: 'b1',
              dateFrom: DateTime(2026, 6, 1),
              dateTo: DateTime(2026, 6, 30),
            ),
          );

      expect(get!.queryParameters['unit'], 'u1');
      expect(get!.queryParameters['building'], 'b1');
      expect(get!.queryParameters['date_from'], '2026-06-01');
      expect(get!.queryParameters['date_to'], '2026-06-30');

      expect(rows, hasLength(2));
      expect(rows.first.id, 'e1');
      expect(rows.first.category, ExpenseCategory.paint);
      expect(rows.first.amount, 2500.0);
      expect(rows.first.source, ExpenseSource.manual);
      expect(rows.last.source, ExpenseSource.request);
      expect(rows.last.requestId, 'm1');
    });

    test('createExpense posts the manual body and parses 201', () async {
      RequestOptions? post;
      final adapter = _ScriptedAdapter((options) {
        if (options.path == ApiEndpoints.expenses && options.method == 'POST') {
          post = options;
          return _json(_expenseJson(), status: 201);
        }
        return _json(<String, dynamic>{}, status: 404);
      });
      final container = _container(adapter);

      final expense =
          await container.read(expenseRepositoryProvider).createExpense(
                unitId: 'u1',
                amount: 2500,
                date: DateTime(2026, 6, 3),
                category: ExpenseCategory.paint,
                note: 'Annual paint',
              );

      final body = post!.data as Map<String, dynamic>;
      expect(body['unit_id'], 'u1');
      expect(body['amount'], 2500);
      expect(body['date'], '2026-06-03');
      expect(body['category'], 'paint');
      expect(body['note'], 'Annual paint');
      // source is never client-set; receipt_ref omitted.
      expect(body.containsKey('source'), isFalse);
      expect(body.containsKey('receipt_ref'), isFalse);

      expect(expense.id, 'e1');
      expect(expense.amount, 2500.0);
      expect(expense.date, DateTime(2026, 6, 3));
    });

    test('updateExpense sends only the provided fields', () async {
      RequestOptions? patch;
      final adapter = _ScriptedAdapter((options) {
        if (options.path == ApiEndpoints.expense('e1') &&
            options.method == 'PATCH') {
          patch = options;
          return _json(_expenseJson());
        }
        return _json(<String, dynamic>{}, status: 404);
      });
      final container = _container(adapter);

      await container
          .read(expenseRepositoryProvider)
          .updateExpense('e1', amount: 3000);

      final body = patch!.data as Map<String, dynamic>;
      expect(body, {'amount': 3000});
      expect(body.containsKey('category'), isFalse);
    });

    test('deleteExpense issues a DELETE and tolerates 204', () async {
      RequestOptions? del;
      final adapter = _ScriptedAdapter((options) {
        if (options.path == ApiEndpoints.expense('e1') &&
            options.method == 'DELETE') {
          del = options;
          return _json(<String, dynamic>{}, status: 204);
        }
        return _json(<String, dynamic>{}, status: 404);
      });
      final container = _container(adapter);

      await container.read(expenseRepositoryProvider).deleteExpense('e1');

      expect(del, isNotNull);
    });

    test('summary parses by_category and by_month totals', () async {
      final adapter = _ScriptedAdapter((options) {
        if (options.path == ApiEndpoints.expensesSummary &&
            options.method == 'GET') {
          return _json({
            'by_category': [
              {'category': 'paint', 'total': '2500.00'},
              {'category': 'plumbing', 'total': '1800.00'},
            ],
            'by_month': [
              {'month': '2026-06-01', 'total': '4300.00'},
            ],
          });
        }
        return _json(<String, dynamic>{}, status: 404);
      });
      final container = _container(adapter);

      final summary =
          await container.read(expenseRepositoryProvider).summary();

      expect(summary.byCategory, hasLength(2));
      expect(summary.byCategory.first.category, ExpenseCategory.paint);
      expect(summary.byCategory.first.total, 2500.0);
      expect(summary.byMonth, hasLength(1));
      expect(summary.byMonth.first.month, DateTime(2026, 6, 1));
      expect(summary.byMonth.first.total, 4300.0);
    });

    test('exportCsv returns the raw CSV text', () async {
      RequestOptions? get;
      final adapter = _ScriptedAdapter((options) {
        if (options.path == ApiEndpoints.expensesExport &&
            options.method == 'GET') {
          get = options;
          return _text('id,amount\ne1,2500.00\n');
        }
        return _json(<String, dynamic>{}, status: 404);
      });
      final container = _container(adapter);

      final csv = await container
          .read(expenseRepositoryProvider)
          .exportCsv(filter: const ExpenseFilter(unitId: 'u1'));

      expect(get!.queryParameters['unit'], 'u1');
      expect(csv, contains('id,amount'));
      expect(csv, contains('e1,2500.00'));
    });

    test('getExpense surfaces a foreign/unknown id 404 as ApiException',
        () async {
      final adapter =
          _ScriptedAdapter((_) => _json(<String, dynamic>{}, status: 404));
      final container = _container(adapter);

      expect(
        () => container.read(expenseRepositoryProvider).getExpense('missing'),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 404),
        ),
      );
    });
  });

  group('model + enum parsing', () {
    test('MaintenanceRequest tolerates missing fields and null cost', () {
      final req = MaintenanceRequest.fromJson({'id': 'm9'});
      expect(req.id, 'm9');
      expect(req.category, MaintenanceCategory.other);
      expect(req.status, MaintenanceStatus.open);
      expect(req.resolutionCost, isNull);
      expect(req.resolvedAt, isNull);
    });

    test('Expense tolerates missing money/source and null date', () {
      final expense = Expense.fromJson({'id': 'e9'});
      expect(expense.id, 'e9');
      expect(expense.amount, 0);
      expect(expense.category, ExpenseCategory.other);
      expect(expense.source, ExpenseSource.manual);
      expect(expense.date, isNull);
    });

    test('ExpenseSummary degrades absent buckets to empty lists', () {
      final summary = ExpenseSummary.fromJson(<String, dynamic>{});
      expect(summary.byCategory, isEmpty);
      expect(summary.byMonth, isEmpty);
    });

    test('enums degrade unknown/null to their defaults', () {
      expect(MaintenanceCategory.fromWire('weird'), MaintenanceCategory.other);
      expect(MaintenanceCategory.fromWire(null), MaintenanceCategory.other);
      expect(MaintenanceStatus.fromWire('weird'), MaintenanceStatus.open);
      expect(MaintenanceStatus.fromWire('resolved'), MaintenanceStatus.resolved);
      expect(ExpenseCategory.fromWire('weird'), ExpenseCategory.other);
      expect(ExpenseSource.fromWire('weird'), ExpenseSource.manual);
      expect(ExpenseSource.fromWire('request'), ExpenseSource.request);
    });
  });
}
