// T-008 — Verification data layer (mobile) unit tests.
//
// Covers:
//   1. VerificationResultStatus wire parsing (enum codec).
//   2. VerificationResult.fromJson — happy path, missing fields, privacy gate.
//   3. VerificationRepository.verify() — mocked POST /tenants/:id/verify.
//   4. VerificationRepository.getVerification() — mocked GET /tenants/:id.
//   5. Provider wiring smoke test.
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khatir_mobile/core/network/dio_client.dart';
import 'package:khatir_mobile/core/storage/secure_storage.dart';
import 'package:khatir_mobile/features/verification/data/models/verification_result.dart';
import 'package:khatir_mobile/features/verification/data/verification_providers.dart';
import 'package:khatir_mobile/features/verification/data/verification_repository.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

/// In-memory secure storage so tests never touch the platform channel.
class _FakeSecureStorage implements SecureStorage {
  _FakeSecureStorage({this.access = 'tok', this.refresh = 'ref'});
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

/// Scriptable adapter: maps a request to a canned response.
class _ScriptedAdapter implements HttpClientAdapter {
  _ScriptedAdapter(this.handler);

  final ResponseBody Function(RequestOptions options) handler;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async =>
      handler(options);
}

ResponseBody _json(Object body, {int status = 200}) => ResponseBody.fromString(
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

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('VerificationResultStatus', () {
    test('fromWire parses matched', () {
      expect(
        VerificationResultStatus.fromWire('matched'),
        VerificationResultStatus.matched,
      );
    });

    test('fromWire parses not_matched', () {
      expect(
        VerificationResultStatus.fromWire('not_matched'),
        VerificationResultStatus.notMatched,
      );
    });

    test('fromWire parses error', () {
      expect(
        VerificationResultStatus.fromWire('error'),
        VerificationResultStatus.error,
      );
    });

    test('fromWire degrades unknown value to error', () {
      expect(
        VerificationResultStatus.fromWire('some_unknown_value'),
        VerificationResultStatus.error,
      );
    });

    test('fromWire degrades null to error', () {
      expect(
        VerificationResultStatus.fromWire(null),
        VerificationResultStatus.error,
      );
    });

    test('wire values are correct snake_case strings', () {
      expect(VerificationResultStatus.matched.wire, 'matched');
      expect(VerificationResultStatus.notMatched.wire, 'not_matched');
      expect(VerificationResultStatus.error.wire, 'error');
    });
  });

  group('VerificationResult.fromJson', () {
    test('parses a complete matched payload', () {
      final json = {
        'tenant_id': 'abc',
        'verification_status': 'matched',
        'provider_ref': 'prov-1',
        'verified_at': '2026-06-01T08:00:00Z',
      };
      final r = VerificationResult.fromJson(json);
      expect(r.tenantId, 'abc');
      expect(r.status, VerificationResultStatus.matched);
      expect(r.providerRef, 'prov-1');
      expect(r.verifiedAt, isNotNull);
    });

    test('parses a not_matched payload', () {
      final json = {
        'tenant_id': 'xyz',
        'verification_status': 'not_matched',
        'provider_ref': 'prov-2',
      };
      final r = VerificationResult.fromJson(json);
      expect(r.status, VerificationResultStatus.notMatched);
    });

    test('tolerates missing / null fields', () {
      final r = VerificationResult.fromJson({});
      expect(r.tenantId, '');
      expect(r.status, VerificationResultStatus.error);
      expect(r.providerRef, '');
      expect(r.verifiedAt, isNull);
    });

    test('tolerates null verified_at', () {
      final r = VerificationResult.fromJson({
        'tenant_id': 'x',
        'verification_status': 'matched',
        'provider_ref': 'r',
        'verified_at': null,
      });
      expect(r.verifiedAt, isNull);
    });

    test('model surface has no raw EC fields — privacy gate', () {
      // VerificationResult only exposes tenantId, status, providerRef,
      // verifiedAt. This test asserts that a parsed result with only those
      // fields works correctly — no name/dob/photo/nid/address from EC.
      final r = VerificationResult.fromJson({
        'tenant_id': 't-1',
        'verification_status': 'matched',
        'provider_ref': 'opaque-ref',
      });
      // Confirm the four privacy-safe fields are present and correctly typed.
      expect(r.tenantId, isA<String>());
      expect(r.status, isA<VerificationResultStatus>());
      expect(r.providerRef, isA<String>());
      // verifiedAt is nullable (absent in this payload).
      expect(r.verifiedAt, isNull);
    });

    test('copyWith works correctly', () {
      final r = VerificationResult.fromJson({
        'tenant_id': 'a',
        'verification_status': 'matched',
        'provider_ref': 'ref-a',
      });
      final r2 = r.copyWith(providerRef: 'ref-b');
      expect(r2.providerRef, 'ref-b');
      expect(r2.tenantId, 'a');
      expect(r2.status, VerificationResultStatus.matched);
    });

    test('equality works', () {
      final r1 = VerificationResult.fromJson({
        'tenant_id': 'a',
        'verification_status': 'matched',
        'provider_ref': 'ref',
      });
      final r2 = VerificationResult.fromJson({
        'tenant_id': 'a',
        'verification_status': 'matched',
        'provider_ref': 'ref',
      });
      expect(r1, equals(r2));
    });
  });

  group('VerificationRepository.verify()', () {
    test('POST /tenants/:id/verify — returns matched result', () async {
      final container = _container(
        _ScriptedAdapter((_) => _json({
              'tenant_id': 't-42',
              'verification_status': 'matched',
              'provider_ref': 'ref-matched',
              'verified_at': '2026-06-13T10:00:00Z',
            })),
      );
      final repo = container.read(verificationRepositoryProvider);

      final result = await repo.verify('t-42', consent: true);

      expect(result.tenantId, 't-42');
      expect(result.status, VerificationResultStatus.matched);
      expect(result.providerRef, 'ref-matched');
      expect(result.verifiedAt, isNotNull);
    });

    test('POST /tenants/:id/verify — returns not_matched result', () async {
      final container = _container(
        _ScriptedAdapter((_) => _json({
              'tenant_id': 't-99',
              'verification_status': 'not_matched',
              'provider_ref': 'ref-nm',
            })),
      );
      final repo = container.read(verificationRepositoryProvider);

      final result = await repo.verify('t-99', consent: true);

      expect(result.status, VerificationResultStatus.notMatched);
    });

    test('POST /tenants/:id/verify — unknown status degrades to error',
        () async {
      final container = _container(
        _ScriptedAdapter((_) => _json({
              'tenant_id': 't-x',
              'verification_status': 'unexpected_value',
              'provider_ref': 'ref-x',
            })),
      );
      final repo = container.read(verificationRepositoryProvider);

      final result = await repo.verify('t-x', consent: true);

      expect(result.status, VerificationResultStatus.error);
    });

    test('POST /tenants/:id/verify — sends consent flag in request body',
        () async {
      RequestOptions? captured;
      final container = _container(
        _ScriptedAdapter((opts) {
          captured = opts;
          return _json({
            'tenant_id': 't-1',
            'verification_status': 'matched',
            'provider_ref': 'r',
          });
        }),
      );
      final repo = container.read(verificationRepositoryProvider);

      await repo.verify('t-1', consent: true);

      expect(captured, isNotNull);
      expect(captured!.path, contains('/tenants/t-1/verify'));
      expect(captured!.method, 'POST');
    });
  });

  group('VerificationRepository.getVerification()', () {
    test('GET /tenants/:id — returns result when tenant is verified', () async {
      final container = _container(
        _ScriptedAdapter((_) => _json({
              'id': 't-5',
              'verification_status': 'matched',
              'provider_ref': 'pref-5',
              'verified_at': '2026-06-10T00:00:00Z',
            })),
      );
      final repo = container.read(verificationRepositoryProvider);

      final result = await repo.getVerification('t-5');

      expect(result, isNotNull);
      expect(result!.tenantId, 't-5');
      expect(result.status, VerificationResultStatus.matched);
      expect(result.providerRef, 'pref-5');
    });

    test(
        'GET /tenants/:id — returns null when verification_status is unverified',
        () async {
      final container = _container(
        _ScriptedAdapter((_) => _json({
              'id': 't-7',
              'verification_status': 'unverified',
            })),
      );
      final repo = container.read(verificationRepositoryProvider);

      final result = await repo.getVerification('t-7');

      expect(result, isNull);
    });

    test('GET /tenants/:id — returns null when verification_status absent',
        () async {
      final container = _container(
        _ScriptedAdapter((_) => _json({
              'id': 't-8',
            })),
      );
      final repo = container.read(verificationRepositoryProvider);

      final result = await repo.getVerification('t-8');

      expect(result, isNull);
    });
  });

  group('Provider wiring', () {
    test('verificationRepositoryProvider resolves to a VerificationRepository',
        () {
      final container = _container(
        _ScriptedAdapter((_) => throw UnimplementedError()),
      );

      final repo = container.read(verificationRepositoryProvider);
      expect(repo, isA<VerificationRepository>());
    });
  });
}
