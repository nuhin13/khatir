import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khatir_mobile/core/network/api_endpoints.dart';
import 'package:khatir_mobile/core/network/api_exception.dart';
import 'package:khatir_mobile/core/network/dio_client.dart';
import 'package:khatir_mobile/core/storage/secure_storage.dart';
import 'package:khatir_mobile/features/dashboard/data/dashboard_model.dart';
import 'package:khatir_mobile/features/dashboard/data/dashboard_providers.dart';
import 'package:khatir_mobile/features/maintenance/data/models/maintenance_enums.dart';

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

Map<String, dynamic> _dashboardJson() => {
      'total_collected': '12000.00',
      'total_pending': '3000.00',
      'total_overdue': '1500.00',
      'collection_rate': 0.8,
      'occupied_units': 8,
      'total_units': 10,
      'occupancy_rate': 0.8,
      'total_income': '12000.00',
      'total_expense': '4300.00',
      'net': '7700.00',
      'late_payer_count': 2,
      'monthly_series': [
        {'period': '2026-05', 'collected': '10000.00', 'expense': '2000.00'},
        {'period': '2026-06', 'collected': '12000.00', 'expense': '4300.00'},
      ],
      'top_expense_categories': [
        {'category': 'paint', 'amount': '2500.00'},
        {'category': 'plumbing', 'amount': '1800.00'},
      ],
    };

void main() {
  group('DashboardRepository', () {
    test('fetchDashboard reads /dashboard and parses every metric', () async {
      RequestOptions? get;
      final adapter = _ScriptedAdapter((options) {
        if (options.path == ApiEndpoints.dashboard && options.method == 'GET') {
          get = options;
          return _json(_dashboardJson());
        }
        return _json(<String, dynamic>{}, status: 404);
      });
      final container = _container(adapter);

      final data = await container
          .read(dashboardRepositoryProvider)
          .fetchDashboard();

      // No months supplied → the param is omitted (server default applies).
      expect(get!.queryParameters.containsKey('months'), isFalse);

      expect(data.totalCollected, 12000.0);
      expect(data.totalPending, 3000.0);
      expect(data.totalOverdue, 1500.0);
      expect(data.collectionRate, 0.8);
      expect(data.occupiedUnits, 8);
      expect(data.totalUnits, 10);
      expect(data.occupancyRate, 0.8);
      expect(data.totalIncome, 12000.0);
      expect(data.totalExpense, 4300.0);
      expect(data.net, 7700.0);
      expect(data.latePayerCount, 2);

      expect(data.monthlySeries, hasLength(2));
      expect(data.monthlySeries.first.period, '2026-05');
      expect(data.monthlySeries.first.collected, 10000.0);
      expect(data.monthlySeries.last.expense, 4300.0);

      expect(data.topExpenseCategories, hasLength(2));
      expect(data.topExpenseCategories.first.category, ExpenseCategory.paint);
      expect(data.topExpenseCategories.first.amount, 2500.0);
      expect(data.topExpenseCategories.last.category, ExpenseCategory.plumbing);
    });

    test('fetchDashboard passes the months window as ?months=N', () async {
      RequestOptions? get;
      final adapter = _ScriptedAdapter((options) {
        if (options.path == ApiEndpoints.dashboard && options.method == 'GET') {
          get = options;
          return _json(_dashboardJson());
        }
        return _json(<String, dynamic>{}, status: 404);
      });
      final container = _container(adapter);

      await container
          .read(dashboardRepositoryProvider)
          .fetchDashboard(months: 12);

      expect(get!.queryParameters['months'], 12);
    });

    test('fetchDashboard surfaces a non-2xx as ApiException', () async {
      final adapter =
          _ScriptedAdapter((_) => _json(<String, dynamic>{}, status: 403));
      final container = _container(adapter);

      expect(
        () => container.read(dashboardRepositoryProvider).fetchDashboard(),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 403),
        ),
      );
    });
  });

  group('dashboardProvider', () {
    test('exposes the fetched dashboard as AsyncValue.data', () async {
      final adapter = _ScriptedAdapter((options) {
        if (options.path == ApiEndpoints.dashboard && options.method == 'GET') {
          return _json(_dashboardJson());
        }
        return _json(<String, dynamic>{}, status: 404);
      });
      final container = _container(adapter);

      final data = await container.read(dashboardProvider(null).future);
      expect(data.net, 7700.0);
      expect(data.monthlySeries, hasLength(2));
    });

    test('refresh re-fetches into state', () async {
      var calls = 0;
      final adapter = _ScriptedAdapter((options) {
        if (options.path == ApiEndpoints.dashboard && options.method == 'GET') {
          calls += 1;
          return _json(_dashboardJson());
        }
        return _json(<String, dynamic>{}, status: 404);
      });
      final container = _container(adapter);

      await container.read(dashboardProvider(6).future);
      expect(calls, 1);

      await container.read(dashboardProvider(6).notifier).refresh();
      expect(calls, 2);
      expect(container.read(dashboardProvider(6)).value, isNotNull);
    });
  });

  group('model + parsing', () {
    test('DashboardData degrades an empty payload to safe defaults', () {
      final data = DashboardData.fromJson(<String, dynamic>{});
      expect(data.totalCollected, 0);
      expect(data.collectionRate, 0);
      expect(data.occupiedUnits, 0);
      expect(data.latePayerCount, 0);
      expect(data.monthlySeries, isEmpty);
      expect(data.topExpenseCategories, isEmpty);
    });

    test('CategoryTotal degrades an unknown category to other', () {
      final row = CategoryTotal.fromJson({'category': 'weird', 'amount': null});
      expect(row.category, ExpenseCategory.other);
      expect(row.amount, 0);
    });

    test('MonthPoint tolerates missing money fields', () {
      final point = MonthPoint.fromJson({'period': '2026-06'});
      expect(point.period, '2026-06');
      expect(point.collected, 0);
      expect(point.expense, 0);
    });

    test('numeric fields tolerate string and null inputs', () {
      final data = DashboardData.fromJson({
        'total_collected': '999.50',
        'occupied_units': '5',
        'collection_rate': null,
      });
      expect(data.totalCollected, 999.5);
      expect(data.occupiedUnits, 5);
      expect(data.collectionRate, 0);
    });
  });
}
