import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khatir_mobile/core/network/api_endpoints.dart';
import 'package:khatir_mobile/core/network/api_exception.dart';
import 'package:khatir_mobile/core/network/dio_client.dart';
import 'package:khatir_mobile/core/storage/secure_storage.dart';
import 'package:khatir_mobile/features/properties/data/models/property_enums.dart';
import 'package:khatir_mobile/features/properties/data/properties_providers.dart';

/// In-memory secure storage so tests never touch the platform channel.
class _FakeSecureStorage implements SecureStorage {
  _FakeSecureStorage({this.access = 'a', this.refresh = 'r'});
  String? access;
  String? refresh;

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

void main() {
  group('BuildingRepository', () {
    test('listBuildings parses the paginated envelope', () async {
      final adapter = _ScriptedAdapter((options) {
        if (options.path == ApiEndpoints.buildings &&
            options.method == 'GET') {
          return _json({
            'results': [
              {
                'id': 'b1',
                'owner_id': 'u1',
                'name': 'Karim Manzil',
                'area': 'uttara',
                'address': 'Road 5, Sector 7',
                'lat': '23.874100',
                'lng': '90.379900',
                'created_at': '2026-01-01T00:00:00Z',
                'updated_at': '2026-01-02T00:00:00Z',
              },
            ],
            'pagination': {'next': null, 'previous': null, 'count': 1},
          });
        }
        return _json(<String, dynamic>{}, status: 404);
      });
      final container = _container(adapter);

      final buildings =
          await container.read(buildingRepositoryProvider).listBuildings();

      expect(buildings, hasLength(1));
      final b = buildings.single;
      expect(b.id, 'b1');
      expect(b.ownerId, 'u1');
      expect(b.name, 'Karim Manzil');
      expect(b.area, Area.uttara);
      expect(b.lat, closeTo(23.8741, 1e-6));
      expect(b.lng, closeTo(90.3799, 1e-6));
    });

    test('getBuilding parses a single building (lat/lng null)', () async {
      final adapter = _ScriptedAdapter((options) {
        if (options.path == ApiEndpoints.building('b1') &&
            options.method == 'GET') {
          return _json({
            'id': 'b1',
            'owner_id': 'u1',
            'name': 'No Pin',
            'area': 'old_dhaka',
            'address': 'Old town',
            'lat': null,
            'lng': null,
          });
        }
        return _json(<String, dynamic>{}, status: 404);
      });
      final container = _container(adapter);

      final b =
          await container.read(buildingRepositoryProvider).getBuilding('b1');

      expect(b.area, Area.oldDhaka);
      expect(b.lat, isNull);
      expect(b.lng, isNull);
    });

    test('createBuilding sends only the provided fields and parses 201',
        () async {
      RequestOptions? post;
      final adapter = _ScriptedAdapter((options) {
        if (options.path == ApiEndpoints.buildings &&
            options.method == 'POST') {
          post = options;
          return _json({
            'id': 'b2',
            'owner_id': 'u1',
            'name': 'New Block',
            'area': 'mirpur',
            'address': 'Block C',
          }, status: 201);
        }
        return _json(<String, dynamic>{}, status: 404);
      });
      final container = _container(adapter);

      final b = await container.read(buildingRepositoryProvider).createBuilding(
            name: 'New Block',
            area: Area.mirpur,
            address: 'Block C',
          );

      final body = post!.data as Map<String, dynamic>;
      expect(body, {'name': 'New Block', 'area': 'mirpur', 'address': 'Block C'});
      expect(body.containsKey('lat'), isFalse);
      expect(b.id, 'b2');
      expect(b.area, Area.mirpur);
    });

    test('getBuilding surfaces a 404 as ApiException', () async {
      final adapter =
          _ScriptedAdapter((_) => _json(<String, dynamic>{}, status: 404));
      final container = _container(adapter);

      expect(
        () => container.read(buildingRepositoryProvider).getBuilding('missing'),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 404),
        ),
      );
    });
  });

  group('UnitRepository', () {
    test('listUnits parses the paginated envelope (rent as string)', () async {
      final adapter = _ScriptedAdapter((options) {
        if (options.path == ApiEndpoints.buildingUnits('b1') &&
            options.method == 'GET') {
          return _json({
            'results': [
              {
                'id': 'u1',
                'building_id': 'b1',
                'label': '1A',
                'type': 'apartment',
                'rent': '15000.00',
                'amenities': ['lift', 'parking'],
                'status': 'vacant',
                'available_from': '2026-07-01',
              },
            ],
            'pagination': {'next': null, 'previous': null, 'count': 1},
          });
        }
        return _json(<String, dynamic>{}, status: 404);
      });
      final container = _container(adapter);

      final units =
          await container.read(unitRepositoryProvider).listUnits('b1');

      expect(units, hasLength(1));
      final u = units.single;
      expect(u.label, '1A');
      expect(u.type, UnitType.apartment);
      expect(u.rent, 15000.0);
      expect(u.amenities, ['lift', 'parking']);
      expect(u.status, UnitStatus.vacant);
      expect(u.availableFrom, DateTime(2026, 7, 1));
    });

    test('createUnit sends label + wire enums', () async {
      RequestOptions? post;
      final adapter = _ScriptedAdapter((options) {
        if (options.path == ApiEndpoints.buildingUnits('b1') &&
            options.method == 'POST') {
          post = options;
          return _json({
            'id': 'u9',
            'building_id': 'b1',
            'label': '2B',
            'type': 'room',
            'status': 'occupied',
          }, status: 201);
        }
        return _json(<String, dynamic>{}, status: 404);
      });
      final container = _container(adapter);

      final u = await container.read(unitRepositoryProvider).createUnit(
            'b1',
            label: '2B',
            type: UnitType.room,
            status: UnitStatus.occupied,
            rent: 9000,
          );

      final body = post!.data as Map<String, dynamic>;
      expect(body['label'], '2B');
      expect(body['type'], 'room');
      expect(body['status'], 'occupied');
      expect(body['rent'], 9000);
      expect(u.id, 'u9');
      expect(u.type, UnitType.room);
    });

    test('generateUnits posts floors/per_floor/scheme and parses the list',
        () async {
      RequestOptions? post;
      final adapter = _ScriptedAdapter((options) {
        if (options.path == ApiEndpoints.buildingUnitsGenerate('b1') &&
            options.method == 'POST') {
          post = options;
          return _json([
            {'id': 'g1', 'building_id': 'b1', 'label': '1A'},
            {'id': 'g2', 'building_id': 'b1', 'label': '1B'},
            {'id': 'g3', 'building_id': 'b1', 'label': '2A'},
          ], status: 201);
        }
        return _json(<String, dynamic>{}, status: 404);
      });
      final container = _container(adapter);

      final units = await container.read(unitRepositoryProvider).generateUnits(
            'b1',
            floors: 2,
            perFloor: 2,
            scheme: UnitScheme.letter,
            removed: ['2B'],
          );

      final body = post!.data as Map<String, dynamic>;
      expect(body['floors'], 2);
      expect(body['per_floor'], 2);
      expect(body['scheme'], 'letter');
      expect(body['removed'], ['2B']);
      expect(units.map((u) => u.label), ['1A', '1B', '2A']);
    });

    test('updateUnit sends only provided fields', () async {
      RequestOptions? patch;
      final adapter = _ScriptedAdapter((options) {
        if (options.path == ApiEndpoints.unit('u1') &&
            options.method == 'PATCH') {
          patch = options;
          return _json({
            'id': 'u1',
            'building_id': 'b1',
            'label': '1A',
            'status': 'maintenance',
          });
        }
        return _json(<String, dynamic>{}, status: 404);
      });
      final container = _container(adapter);

      final u = await container
          .read(unitRepositoryProvider)
          .updateUnit('u1', status: UnitStatus.maintenance);

      final body = patch!.data as Map<String, dynamic>;
      expect(body, {'status': 'maintenance'});
      expect(u.status, UnitStatus.maintenance);
    });
  });

  group('PortfolioRepository', () {
    test('getPortfolio parses buildings + totals (rent strings)', () async {
      final adapter = _ScriptedAdapter((options) {
        if (options.path == ApiEndpoints.portfolio &&
            options.method == 'GET') {
          return _json({
            'buildings': [
              {
                'id': 'b1',
                'name': 'Karim Manzil',
                'area': 'uttara',
                'total_units': 6,
                'occupied': 4,
                'vacant': 1,
                'maintenance': 1,
                'total_rent': '90000.00',
              },
            ],
            'totals': {
              'buildings': 1,
              'total_units': 6,
              'occupied': 4,
              'vacant': 1,
              'maintenance': 1,
              'total_rent': '90000.00',
            },
          });
        }
        return _json(<String, dynamic>{}, status: 404);
      });
      final container = _container(adapter);

      final portfolio =
          await container.read(portfolioRepositoryProvider).getPortfolio();

      expect(portfolio.buildings, hasLength(1));
      final b = portfolio.buildings.single;
      expect(b.name, 'Karim Manzil');
      expect(b.area, Area.uttara);
      expect(b.totalUnits, 6);
      expect(b.occupied, 4);
      expect(b.totalRent, 90000.0);
      expect(portfolio.totals.buildings, 1);
      expect(portfolio.totals.totalRent, 90000.0);
    });
  });

  group('Providers', () {
    test('buildingsProvider exposes the fetched list as AsyncValue.data',
        () async {
      final adapter = _ScriptedAdapter((options) {
        if (options.path == ApiEndpoints.buildings) {
          return _json({
            'results': [
              {'id': 'b1', 'name': 'A', 'area': 'banani', 'address': 'x'},
            ],
            'pagination': {'next': null, 'previous': null, 'count': 1},
          });
        }
        return _json(<String, dynamic>{}, status: 404);
      });
      final container = _container(adapter);

      final list = await container.read(buildingsProvider.future);
      expect(list, hasLength(1));
      expect(list.single.area, Area.banani);
    });

    test('portfolioProvider exposes the summary as AsyncValue.data', () async {
      final adapter = _ScriptedAdapter((options) {
        if (options.path == ApiEndpoints.portfolio) {
          return _json({
            'buildings': const [],
            'totals': {
              'buildings': 0,
              'total_units': 0,
              'occupied': 0,
              'vacant': 0,
              'maintenance': 0,
              'total_rent': '0.00',
            },
          });
        }
        return _json(<String, dynamic>{}, status: 404);
      });
      final container = _container(adapter);

      final summary = await container.read(portfolioProvider.future);
      expect(summary.buildings, isEmpty);
      expect(summary.totals.totalRent, 0);
    });
  });
}
