import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khatir_mobile/core/network/api_endpoints.dart';
import 'package:khatir_mobile/core/network/api_exception.dart';
import 'package:khatir_mobile/core/network/dio_client.dart';
import 'package:khatir_mobile/core/storage/secure_storage.dart';
import 'package:khatir_mobile/features/dmpform/data/dmpform_providers.dart';
import 'package:khatir_mobile/features/dmpform/data/models/dmp_data.dart';
import 'package:khatir_mobile/features/dmpform/data/models/dmp_record.dart';

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

Map<String, dynamic> _assembled() => <String, dynamic>{
      'tenant_name': 'Karim Uddin',
      // Masked server-side — the full NID never crosses the wire.
      'nid_number': '**** **** 7788',
      'dob': '1990-05-10',
      'permanent_address': 'Vill: Daudkandi, Comilla',
      'present_address': 'Road 5, Uttara',
      'building_address': 'House 12, Road 5, Uttara',
      'building_area': 'Uttara',
      'landlord_name': 'Rahim Mia',
      'landlord_phone': '01710000000',
      'family_members': [
        {'name': 'Ayesha', 'relation': 'spouse'},
        {'name': 'Rafi', 'relation': 'child'},
      ],
    };

Map<String, dynamic> _record({String id = 'r1'}) => <String, dynamic>{
      'id': id,
      'tenant': 't1',
      'template_version': 'dmp-v1',
      'pdf_ref': 'dmp/r1.pdf',
      'generated_by': 'u9',
      'generated_at': '2026-06-04T10:00:00Z',
      'created_at': '2026-06-04T10:00:00Z',
    };

void main() {
  group('DmpData model', () {
    test('fromJson parses fields + nested family; NID stays masked', () {
      final data = DmpData.fromJson(_assembled());

      expect(data.tenantName, 'Karim Uddin');
      expect(data.nidNumber, '**** **** 7788');
      expect(data.dob, '1990-05-10');
      expect(data.permanentAddress, 'Vill: Daudkandi, Comilla');
      expect(data.buildingArea, 'Uttara');
      expect(data.landlordName, 'Rahim Mia');
      expect(data.familyMembers, hasLength(2));
      expect(data.familyMembers.first.name, 'Ayesha');
      expect(data.familyMembers.first.relation, 'spouse');
      // The masked value carries no plaintext digits beyond the last group.
      expect(data.nidNumber.contains('1234'), isFalse);
    });

    test('fromJson tolerates missing/empty payload', () {
      final data = DmpData.fromJson(<String, dynamic>{});
      expect(data.tenantName, '');
      expect(data.nidNumber, '');
      expect(data.familyMembers, isEmpty);
    });
  });

  group('DmpRecord model', () {
    test('fromJson parses metadata + signed url; no field payload/NID', () {
      final record = DmpRecord.fromJson(<String, dynamic>{
        ..._record(),
        'signed_url': 'https://s3.example/dmp/r1.pdf?sig=abc',
      });

      expect(record.id, 'r1');
      expect(record.tenantId, 't1');
      expect(record.templateVersion, 'dmp-v1');
      expect(record.pdfRef, 'dmp/r1.pdf');
      expect(record.generatedBy, 'u9');
      expect(record.generatedAt, DateTime.utc(2026, 6, 4, 10));
      expect(record.signedUrl, 'https://s3.example/dmp/r1.pdf?sig=abc');
    });

    test('fromGenerateJson folds top-level signed_url onto the record', () {
      final record = DmpRecord.fromGenerateJson(<String, dynamic>{
        'record': _record(id: 'r9'),
        'signed_url': 'https://s3.example/dmp/r9.pdf?sig=z',
      });
      expect(record.id, 'r9');
      expect(record.signedUrl, 'https://s3.example/dmp/r9.pdf?sig=z');
    });

    test('fromGenerateJson tolerates an absent record', () {
      final record = DmpRecord.fromGenerateJson(<String, dynamic>{
        'signed_url': 'https://s3.example/x.pdf',
      });
      expect(record.id, '');
      expect(record.signedUrl, 'https://s3.example/x.pdf');
    });
  });

  group('DmpFormRepository (typed layer)', () {
    test('getDmpData GETs the dmpform path and parses masked DmpData', () async {
      RequestOptions? got;
      final adapter = _ScriptedAdapter((options) {
        if (options.path == ApiEndpoints.tenantDmpForm('t1') &&
            options.method == 'GET') {
          got = options;
          return _json(_assembled());
        }
        return _json(<String, dynamic>{}, status: 404);
      });
      final container = _container(adapter);

      final data =
          await container.read(dmpFormRepositoryProvider).getDmpData('t1');

      expect(got, isNotNull);
      expect(data.tenantName, 'Karim Uddin');
      expect(data.nidNumber, '**** **** 7788');
      expect(data.familyMembers, hasLength(2));
    });

    test('getDmpData surfaces a cross-user 404 as ApiException', () async {
      final adapter =
          _ScriptedAdapter((_) => _json(<String, dynamic>{}, status: 404));
      final container = _container(adapter);

      expect(
        () => container.read(dmpFormRepositoryProvider).getDmpData('foreign'),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 404),
        ),
      );
    });

    test('generateRecord POSTs the pdf path and parses record + signed url',
        () async {
      RequestOptions? post;
      final adapter = _ScriptedAdapter((options) {
        if (options.path == ApiEndpoints.tenantDmpFormPdf('t1') &&
            options.method == 'POST') {
          post = options;
          return _json(
            {
              'record': _record(id: 'r5'),
              'signed_url': 'https://s3.example/dmp/r5.pdf?sig=q',
            },
            status: 201,
          );
        }
        return _json(<String, dynamic>{}, status: 404);
      });
      final container = _container(adapter);

      final record = await container
          .read(dmpFormRepositoryProvider)
          .generateRecord('t1');

      expect(post, isNotNull);
      expect(record.id, 'r5');
      expect(record.signedUrl, 'https://s3.example/dmp/r5.pdf?sig=q');
    });

    test('getRecord GETs the record path and parses the typed record',
        () async {
      RequestOptions? got;
      final adapter = _ScriptedAdapter((options) {
        if (options.path == ApiEndpoints.dmpRecord('r1') &&
            options.method == 'GET') {
          got = options;
          return _json({
            ..._record(),
            'signed_url': 'https://s3.example/dmp/r1.pdf?sig=fresh',
          });
        }
        return _json(<String, dynamic>{}, status: 404);
      });
      final container = _container(adapter);

      final record =
          await container.read(dmpFormRepositoryProvider).getRecord('r1');

      expect(got, isNotNull);
      expect(record.id, 'r1');
      expect(record.signedUrl, 'https://s3.example/dmp/r1.pdf?sig=fresh');
    });

    test('getRecord surfaces a 404 as ApiException', () async {
      final adapter =
          _ScriptedAdapter((_) => _json(<String, dynamic>{}, status: 404));
      final container = _container(adapter);

      expect(
        () => container.read(dmpFormRepositoryProvider).getRecord('missing'),
        throwsA(
          isA<ApiException>().having((e) => e.statusCode, 'statusCode', 404),
        ),
      );
    });
  });

  group('Providers', () {
    test('dmpDataProvider exposes assembled data as AsyncValue.data', () async {
      final adapter = _ScriptedAdapter((options) {
        if (options.path == ApiEndpoints.tenantDmpForm('t1')) {
          return _json(_assembled());
        }
        return _json(<String, dynamic>{}, status: 404);
      });
      final container = _container(adapter);

      final data = await container.read(dmpDataProvider('t1').future);
      expect(data.tenantName, 'Karim Uddin');
      expect(data.familyMembers, hasLength(2));
    });

    test('dmpRecordProvider exposes the fetched record as AsyncValue.data',
        () async {
      final adapter = _ScriptedAdapter((options) {
        if (options.path == ApiEndpoints.dmpRecord('r1')) {
          return _json({
            ..._record(),
            'signed_url': 'https://s3.example/dmp/r1.pdf?sig=p',
          });
        }
        return _json(<String, dynamic>{}, status: 404);
      });
      final container = _container(adapter);

      final record = await container.read(dmpRecordProvider('r1').future);
      expect(record.id, 'r1');
      expect(record.signedUrl, 'https://s3.example/dmp/r1.pdf?sig=p');
    });
  });
}
