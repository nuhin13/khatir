/// T-007 — Warnings data-layer unit tests (mocked HTTP).
///
/// Covers: Warning model parsing, WarningRepository.issueWarning /
/// listWarnings / generateNotice, providers (leaseWarningsProvider,
/// issueWarningProvider, warningNoticePdfProvider).
///
/// No real network; the Dio client's adapter is replaced with a
/// [_ScriptedAdapter] that returns canned JSON responses.
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khatir_mobile/core/network/api_endpoints.dart';
import 'package:khatir_mobile/core/network/api_exception.dart';
import 'package:khatir_mobile/core/network/dio_client.dart';
import 'package:khatir_mobile/core/storage/secure_storage.dart';
import 'package:khatir_mobile/features/warnings/data/models/models.dart';
import 'package:khatir_mobile/features/warnings/data/models/warning_enums.dart';
import 'package:khatir_mobile/features/warnings/data/providers.dart';
import 'package:khatir_mobile/features/warnings/data/warning_repository.dart';

// ── Test doubles ────────────────────────────────────────────────────────────

class _FakeSecureStorage implements SecureStorage {
  String? access = 'test-access';
  String? refresh = 'test-refresh';

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

/// Scriptable HTTP adapter: maps a request to a canned JSON response.
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

ResponseBody _bytes(Uint8List bytes, {int status = 200}) =>
    ResponseBody.fromBytes(
      bytes,
      status,
      headers: {
        Headers.contentTypeHeader: ['application/pdf'],
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

// ── Fixture data ─────────────────────────────────────────────────────────────

final _warningJson = {
  'id': 'w1',
  'lease_id': 'lease1',
  'tenant_id': 'tenant1',
  'landlord_id': 'landlord1',
  'warning_type': 'late_rent',
  'reason': 'Three months overdue',
  'issued_at': '2026-06-13T10:00:00Z',
  'notice_ref': '',
  'acknowledged_at': null,
};

final _noticeJson = {
  'warning_id': 'w1',
  'notice_ref': 'ref-abc',
  'signed_url': 'https://storage.example.com/notices/w1.pdf',
};

// ── Model tests ────────────────────────────────────────────────────────────

void main() {
  group('Warning.fromJson', () {
    test('parses all fields correctly', () {
      final w = Warning.fromJson(_warningJson);
      expect(w.id, 'w1');
      expect(w.leaseId, 'lease1');
      expect(w.tenantId, 'tenant1');
      expect(w.landlordId, 'landlord1');
      expect(w.warningType, WarningType.lateRent);
      expect(w.reason, 'Three months overdue');
      expect(w.issuedAt, isNotNull);
      expect(w.noticeRef, '');
      expect(w.acknowledgedAt, isNull);
    });

    test('unknown warning_type degrades to WarningType.other', () {
      final w = Warning.fromJson({..._warningJson, 'warning_type': 'unknown'});
      expect(w.warningType, WarningType.other);
    });

    test('null warning_type degrades to WarningType.other', () {
      final w = Warning.fromJson({..._warningJson, 'warning_type': null});
      expect(w.warningType, WarningType.other);
    });

    test('missing fields default gracefully', () {
      final w = Warning.fromJson({'id': 'x'});
      expect(w.id, 'x');
      expect(w.leaseId, '');
      expect(w.reason, '');
      expect(w.issuedAt, isNull);
    });

    test('copyWith preserves unchanged fields', () {
      final w = Warning.fromJson(_warningJson);
      final w2 = w.copyWith(reason: 'Updated');
      expect(w2.id, 'w1');
      expect(w2.reason, 'Updated');
      expect(w2.warningType, WarningType.lateRent);
    });
  });

  group('WarningType enum', () {
    test('wire values match backend snake_case', () {
      expect(WarningType.lateRent.wire, 'late_rent');
      expect(WarningType.leaseViolation.wire, 'lease_violation');
      expect(WarningType.noise.wire, 'noise');
      expect(WarningType.propertyDamage.wire, 'property_damage');
      expect(WarningType.other.wire, 'other');
    });

    test('fromWire round-trips all values', () {
      for (final type in WarningType.values) {
        expect(WarningType.fromWire(type.wire), type);
      }
    });

    test('fromWire(null) → other', () {
      expect(WarningType.fromWire(null), WarningType.other);
    });
  });

  group('WarningNotice.fromJson', () {
    test('parses all fields', () {
      final n = WarningNotice.fromJson(_noticeJson);
      expect(n.warningId, 'w1');
      expect(n.noticeRef, 'ref-abc');
      expect(n.signedUrl, 'https://storage.example.com/notices/w1.pdf');
    });
  });

  group('WarningRepository.issueWarning', () {
    test('POST /leases/{id}/warnings returns a Warning', () async {
      final adapter = _ScriptedAdapter((req) {
        expect(req.method, 'POST');
        expect(req.path, ApiEndpoints.leaseWarnings('lease1'));
        return _json(_warningJson);
      });

      final c = _container(adapter);
      final repo = c.read(warningRepositoryProvider);
      final warning = await repo.issueWarning(
        leaseId: 'lease1',
        warningType: WarningType.lateRent,
        reason: 'Three months overdue',
      );

      expect(warning.id, 'w1');
      expect(warning.warningType, WarningType.lateRent);
    });

    test('sends correct wire values in the request body', () async {
      final adapter = _ScriptedAdapter((_) => _json(_warningJson));
      final c = _container(adapter);
      final repo = c.read(warningRepositoryProvider);

      await repo.issueWarning(
        leaseId: 'lease1',
        warningType: WarningType.noise,
        reason: 'Loud music',
      );

      final body =
          adapter.requests.first.data as Map<String, dynamic>;
      expect(body['warning_type'], 'noise');
      expect(body['reason'], 'Loud music');
    });

    test('throws ApiException on 403 (feature disabled)', () async {
      final adapter = _ScriptedAdapter((_) => _json(
            {'code': 'feature_disabled'},
            status: 403,
          ));

      final c = _container(adapter);
      final repo = c.read(warningRepositoryProvider);

      await expectLater(
        repo.issueWarning(
          leaseId: 'lease1',
          warningType: WarningType.lateRent,
          reason: 'Reason',
        ),
        throwsA(isA<ApiException>()
            .having((e) => e.statusCode, 'statusCode', 403)),
      );
    });
  });

  group('WarningRepository.listWarnings', () {
    test('GET /leases/{id}/warnings returns list of Warnings', () async {
      final adapter = _ScriptedAdapter((_) => _json([_warningJson]));

      final c = _container(adapter);
      final repo = c.read(warningRepositoryProvider);
      final warnings = await repo.listWarnings('lease1');

      expect(warnings.length, 1);
      expect(warnings.first.id, 'w1');
    });

    test('handles results envelope correctly', () async {
      final adapter = _ScriptedAdapter(
          (_) => _json({'results': [_warningJson], 'count': 1}));

      final c = _container(adapter);
      final repo = c.read(warningRepositoryProvider);
      final warnings = await repo.listWarnings('lease1');

      expect(warnings.length, 1);
      expect(warnings.first.id, 'w1');
    });

    test('returns empty list when no warnings', () async {
      final adapter = _ScriptedAdapter((_) => _json([]));

      final c = _container(adapter);
      final repo = c.read(warningRepositoryProvider);
      final warnings = await repo.listWarnings('lease1');

      expect(warnings, isEmpty);
    });

    test('throws ApiException on 404 (foreign lease)', () async {
      final adapter = _ScriptedAdapter(
          (_) => _json({'detail': 'Not found'}, status: 404));

      final c = _container(adapter);
      final repo = c.read(warningRepositoryProvider);

      await expectLater(
        repo.listWarnings('foreign-lease'),
        throwsA(isA<ApiException>()
            .having((e) => e.statusCode, 'statusCode', 404)),
      );
    });
  });

  group('WarningRepository.generateNotice', () {
    test('POST /warnings/{id}/notice returns WarningNotice', () async {
      final adapter = _ScriptedAdapter((req) {
        expect(req.method, 'POST');
        expect(req.path, ApiEndpoints.warningNotice('w1'));
        return _json(_noticeJson);
      });

      final c = _container(adapter);
      final repo = c.read(warningRepositoryProvider);
      final notice = await repo.generateNotice('w1');

      expect(notice.warningId, 'w1');
      expect(notice.signedUrl, isNotEmpty);
    });
  });

  group('WarningRepository.fetchNoticePdfBytes', () {
    test('downloads bytes from a signed URL', () async {
      final pdfBytes = Uint8List.fromList([0x25, 0x50, 0x44, 0x46]); // %PDF
      final adapter = _ScriptedAdapter((_) => _bytes(pdfBytes));

      final c = _container(adapter);
      final repo = c.read(warningRepositoryProvider);
      final bytes = await repo.fetchNoticePdfBytes(
          'https://storage.example.com/notices/w1.pdf');

      expect(bytes, pdfBytes);
    });
  });

  group('leaseWarningsProvider', () {
    test('loads warnings for a lease', () async {
      final adapter = _ScriptedAdapter((_) => _json([_warningJson]));
      final c = _container(adapter);

      final sub = c.listen(
        leaseWarningsProvider('lease1'),
        (_, __) {},
        fireImmediately: true,
      );
      addTearDown(sub.close);

      await c.read(leaseWarningsProvider('lease1').future);
      final warnings = c.read(leaseWarningsProvider('lease1')).value!;
      expect(warnings.length, 1);
      expect(warnings.first.id, 'w1');
    });
  });

  group('issueWarningProvider', () {
    test('initial state is null (idle)', () async {
      final adapter = _ScriptedAdapter((_) => _json([]));
      final c = _container(adapter);

      final initial = await c.read(issueWarningProvider('lease1').future);
      expect(initial, isNull);
    });

    test('issue() stores the new warning in state', () async {
      // issueWarning returns w1; listWarnings refresh returns empty.
      final adapter = _ScriptedAdapter((req) {
        if (req.method == 'POST') return _json(_warningJson);
        return _json([]); // list refresh
      });
      final c = _container(adapter);

      final notifier = c.read(issueWarningProvider('lease1').notifier);
      final warning = await notifier.issue(
        warningType: WarningType.lateRent,
        reason: 'Rent overdue',
      );

      expect(warning.id, 'w1');
      expect(c.read(issueWarningProvider('lease1')).value?.id, 'w1');
    });
  });
}
