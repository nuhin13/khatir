import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khatir_mobile/core/network/api_endpoints.dart';
import 'package:khatir_mobile/core/network/api_exception.dart';
import 'package:khatir_mobile/core/network/dio_client.dart';
import 'package:khatir_mobile/core/storage/secure_storage.dart';
import 'package:khatir_mobile/features/tenants/data/models/extracted_tenant.dart';
import 'package:khatir_mobile/features/tenants/data/models/family_member.dart';
import 'package:khatir_mobile/features/tenants/data/models/tenant.dart';
import 'package:khatir_mobile/features/tenants/data/models/tenant_enums.dart';
import 'package:khatir_mobile/features/tenants/data/tenants_providers.dart';

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

Map<String, dynamic> _maskedTenant({
  String id = 't1',
  String name = 'Karim Uddin',
  String masked = '****7788',
  List<Map<String, dynamic>> family = const [],
}) =>
    <String, dynamic>{
      'id': id,
      'name': name,
      'nid_number_masked': masked,
      'dob': '1990-05-10',
      'address': 'Road 5, Uttara',
      'photo_ref': 'nid/abc123',
      'verification_status': 'unverified',
      'verified_at': null,
      'is_app_user': false,
      'family_members': family,
      'created_at': '2026-06-01T00:00:00Z',
      'updated_at': '2026-06-02T00:00:00Z',
    };

void main() {
  group('Tenant model', () {
    test('fromJson parses masked NID, family, status, dates', () {
      final tenant = Tenant.fromJson(
        _maskedTenant(
          family: [
            {'id': 'f1', 'name': 'Ayesha', 'relation': 'spouse'},
            {'id': 'f2', 'name': 'Rafi', 'relation': 'child'},
          ],
        ),
      );

      expect(tenant.id, 't1');
      expect(tenant.name, 'Karim Uddin');
      expect(tenant.nidNumberMasked, '****7788');
      expect(tenant.dob, DateTime(1990, 5, 10));
      expect(tenant.verificationStatus, VerificationStatus.unverified);
      expect(tenant.isAppUser, isFalse);
      expect(tenant.familyMembers, hasLength(2));
      expect(tenant.familyMembers.first.name, 'Ayesha');
      expect(tenant.familyMembers.first.relation, 'spouse');
    });

    test('fromJson tolerates missing/null fields', () {
      final tenant = Tenant.fromJson(<String, dynamic>{'id': 9, 'name': 'X'});
      expect(tenant.id, '9');
      expect(tenant.nidNumberMasked, '');
      expect(tenant.dob, isNull);
      expect(tenant.verificationStatus, VerificationStatus.unverified);
      expect(tenant.familyMembers, isEmpty);
    });

    test('VerificationStatus.fromWire maps wire values and degrades safely', () {
      expect(VerificationStatus.fromWire('matched'), VerificationStatus.matched);
      expect(
        VerificationStatus.fromWire('not_matched'),
        VerificationStatus.notMatched,
      );
      expect(VerificationStatus.fromWire('error'), VerificationStatus.error);
      expect(
        VerificationStatus.fromWire('bogus'),
        VerificationStatus.unverified,
      );
      expect(VerificationStatus.fromWire(null), VerificationStatus.unverified);
    });
  });

  group('FamilyMember model', () {
    test('toCreateJson omits the server-assigned id', () {
      const member = FamilyMember(id: 'f1', name: 'Ayesha', relation: 'spouse');
      expect(FamilyMember.toCreateJson(member), {
        'name': 'Ayesha',
        'relation': 'spouse',
      });
    });
  });

  group('TenantRepository', () {
    test('ocrExtract posts the image field and parses fields + photo_ref',
        () async {
      RequestOptions? post;
      final adapter = _ScriptedAdapter((options) {
        if (options.path == ApiEndpoints.tenantOcr &&
            options.method == 'POST') {
          post = options;
          return _json({
            'name': {'value': 'Karim Uddin', 'confidence': 0.97},
            'nid_number': {'value': '1234567788', 'confidence': 0.81},
            'dob': {'value': '1990-05-10', 'confidence': null},
            'address': {'value': 'Uttara', 'confidence': 0.6},
            'photo_ref': 'nid/abc123',
          });
        }
        return _json(<String, dynamic>{}, status: 404);
      });
      final container = _container(adapter);

      final extracted = await container
          .read(tenantRepositoryProvider)
          .ocrExtract(Uint8List.fromList([1, 2, 3]), filename: 'nid.jpg');

      expect(post!.data, isA<FormData>());
      expect((post!.data as FormData).files.map((f) => f.key), ['image']);
      expect(extracted, isA<ExtractedTenant>());
      expect(extracted.name.value, 'Karim Uddin');
      expect(extracted.nidNumber.confidence, closeTo(0.81, 1e-9));
      expect(extracted.photoRef, 'nid/abc123');
    });

    test('createTenant sends only provided fields + nested family, parses 201',
        () async {
      RequestOptions? post;
      final adapter = _ScriptedAdapter((options) {
        if (options.path == ApiEndpoints.tenants && options.method == 'POST') {
          post = options;
          return _json(
            _maskedTenant(
              family: [
                {'id': 'f1', 'name': 'Ayesha', 'relation': 'spouse'},
              ],
            ),
            status: 201,
          );
        }
        return _json(<String, dynamic>{}, status: 404);
      });
      final container = _container(adapter);

      final tenant = await container.read(tenantRepositoryProvider).createTenant(
            name: 'Karim Uddin',
            nidNumber: '1990123456788',
            dob: DateTime(1990, 5, 10),
            photoRef: 'nid/abc123',
            familyMembers: const [
              FamilyMember(name: 'Ayesha', relation: 'spouse'),
            ],
          );

      final body = post!.data as Map<String, dynamic>;
      expect(body['name'], 'Karim Uddin');
      expect(body['nid_number'], '1990123456788');
      expect(body['dob'], '1990-05-10');
      expect(body['photo_ref'], 'nid/abc123');
      expect(body['family_members'], [
        {'name': 'Ayesha', 'relation': 'spouse'},
      ]);
      // address was not supplied → omitted from the body.
      expect(body.containsKey('address'), isFalse);
      // The response is masked: the full NID never comes back.
      expect(tenant.nidNumberMasked, '****7788');
      expect(body.containsKey('nid_number_masked'), isFalse);
      expect(tenant.familyMembers.single.name, 'Ayesha');
    });

    test('createTenant omits an empty NID', () async {
      RequestOptions? post;
      final adapter = _ScriptedAdapter((options) {
        if (options.path == ApiEndpoints.tenants && options.method == 'POST') {
          post = options;
          return _json(_maskedTenant(masked: ''), status: 201);
        }
        return _json(<String, dynamic>{}, status: 404);
      });
      final container = _container(adapter);

      await container
          .read(tenantRepositoryProvider)
          .createTenant(name: 'No NID', nidNumber: '');

      final body = post!.data as Map<String, dynamic>;
      expect(body, {'name': 'No NID'});
      expect(body.containsKey('nid_number'), isFalse);
    });

    test('listUnitTenants parses a bare JSON array (no envelope)', () async {
      final adapter = _ScriptedAdapter((options) {
        if (options.path == ApiEndpoints.unitTenants('u1') &&
            options.method == 'GET') {
          return _json([
            _maskedTenant(id: 't1', name: 'Karim'),
            _maskedTenant(id: 't2', name: 'Rahim'),
          ]);
        }
        return _json(<String, dynamic>{}, status: 404);
      });
      final container = _container(adapter);

      final tenants =
          await container.read(tenantRepositoryProvider).listUnitTenants('u1');

      expect(tenants.map((t) => t.id), ['t1', 't2']);
      expect(tenants.first.nidNumberMasked, '****7788');
    });

    test('listUnitTenants surfaces a 404 as ApiException', () async {
      final adapter =
          _ScriptedAdapter((_) => _json(<String, dynamic>{}, status: 404));
      final container = _container(adapter);

      expect(
        () =>
            container.read(tenantRepositoryProvider).listUnitTenants('missing'),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 404),
        ),
      );
    });
  });

  group('Providers', () {
    test('unitTenantsProvider exposes the fetched list as AsyncValue.data',
        () async {
      final adapter = _ScriptedAdapter((options) {
        if (options.path == ApiEndpoints.unitTenants('u1')) {
          return _json([_maskedTenant(id: 't1', name: 'Karim')]);
        }
        return _json(<String, dynamic>{}, status: 404);
      });
      final container = _container(adapter);

      final list = await container.read(unitTenantsProvider('u1').future);
      expect(list, hasLength(1));
      expect(list.single.name, 'Karim');
    });

    test('UnitTenantsController.create posts then refreshes the list',
        () async {
      var listCalls = 0;
      final adapter = _ScriptedAdapter((options) {
        if (options.path == ApiEndpoints.tenants && options.method == 'POST') {
          return _json(_maskedTenant(id: 't9', name: 'New'), status: 201);
        }
        if (options.path == ApiEndpoints.unitTenants('u1') &&
            options.method == 'GET') {
          listCalls++;
          // First fetch empty; after create, the new tenant is present.
          return _json(
            listCalls == 1
                ? <Map<String, dynamic>>[]
                : [_maskedTenant(id: 't9', name: 'New')],
          );
        }
        return _json(<String, dynamic>{}, status: 404);
      });
      final container = _container(adapter);

      // Prime the controller (initial fetch → empty).
      final initial = await container.read(unitTenantsProvider('u1').future);
      expect(initial, isEmpty);

      final created = await container
          .read(unitTenantsProvider('u1').notifier)
          .create(name: 'New', nidNumber: '123456788');
      expect(created.id, 't9');

      final after = container.read(unitTenantsProvider('u1')).requireValue;
      expect(after.map((t) => t.id), ['t9']);
      expect(listCalls, 2);
    });
  });
}
