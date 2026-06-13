import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khatir_mobile/core/auth/auth_controller.dart';
import 'package:khatir_mobile/core/auth/auth_state.dart';
import 'package:khatir_mobile/core/network/api_endpoints.dart';
import 'package:khatir_mobile/core/network/api_exception.dart';
import 'package:khatir_mobile/core/network/dio_client.dart';
import 'package:khatir_mobile/core/storage/secure_storage.dart';

import 'auth_controller_test.dart' show FakeSecureStorage, ScriptedAdapter;

ResponseBody _json(Map<String, dynamic> body, {int status = 200}) =>
    ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

const _protected = '${ApiEndpoints.apiPrefix}/properties';

ProviderContainer _container(SecureStorage storage, HttpClientAdapter adapter) {
  final container = ProviderContainer(
    overrides: [secureStorageProvider.overrideWithValue(storage)],
  );
  addTearDown(container.dispose);
  container.read(dioClientProvider).httpClientAdapter = adapter;
  return container;
}

void main() {
  test('request interceptor attaches the access token', () async {
    final storage = FakeSecureStorage(access: 'tok-1', refresh: 'r-1');
    final adapter = ScriptedAdapter((_) => _json({'ok': true}));
    final container = _container(storage, adapter);

    await container.read(dioClientProvider).get<dynamic>(_protected);

    expect(adapter.requests.single.headers['Authorization'], 'Bearer tok-1');
  });

  test('401 triggers a single refresh, then retries with the new token',
      () async {
    final storage = FakeSecureStorage(access: 'stale', refresh: 'r-1');
    var protectedCalls = 0;
    var refreshCalls = 0;
    final adapter = ScriptedAdapter((options) {
      if (options.path == ApiEndpoints.refresh) {
        refreshCalls++;
        return _json({'access': 'fresh', 'refresh': 'r-2'});
      }
      if (options.path == _protected) {
        protectedCalls++;
        // First (stale token) → 401; retry (fresh token) → 200.
        if (options.headers['Authorization'] == 'Bearer fresh') {
          return _json({'ok': true});
        }
        return _json({'detail': 'expired'}, status: 401);
      }
      return _json({}, status: 404);
    });
    final container = _container(storage, adapter);

    final res = await container.read(dioClientProvider).get<dynamic>(_protected);

    expect(res.statusCode, 200);
    expect(refreshCalls, 1, reason: 'exactly one refresh');
    expect(protectedCalls, 2, reason: 'original + retry');
    // Rotated tokens persisted.
    expect(storage.access, 'fresh');
    expect(storage.refresh, 'r-2');
  });

  test('concurrent 401s share a single refresh', () async {
    final storage = FakeSecureStorage(access: 'stale', refresh: 'r-1');
    var refreshCalls = 0;
    final adapter = ScriptedAdapter((options) {
      if (options.path == ApiEndpoints.refresh) {
        refreshCalls++;
        return _json({'access': 'fresh', 'refresh': 'r-2'});
      }
      if (options.headers['Authorization'] == 'Bearer fresh') {
        return _json({'ok': true});
      }
      return _json({'detail': 'expired'}, status: 401);
    });
    final container = _container(storage, adapter);
    final dio = container.read(dioClientProvider);

    await Future.wait([
      dio.get<dynamic>('${ApiEndpoints.apiPrefix}/a'),
      dio.get<dynamic>('${ApiEndpoints.apiPrefix}/b'),
      dio.get<dynamic>('${ApiEndpoints.apiPrefix}/c'),
    ]);

    expect(refreshCalls, 1, reason: 'mutex collapses concurrent refreshes');
  });

  test('refresh failure clears tokens and logs out', () async {
    final storage = FakeSecureStorage(access: 'stale', refresh: 'bad');
    final adapter = ScriptedAdapter((options) {
      if (options.path == ApiEndpoints.refresh) {
        return _json({'detail': 'invalid refresh'}, status: 401);
      }
      return _json({'detail': 'expired'}, status: 401);
    });
    final container = _container(storage, adapter);

    // Resolve initial auth build first (no /me — tokens present, but we
    // exercise the interceptor below which will log us out).
    final dio = container.read(dioClientProvider);

    await expectLater(
      dio.get<dynamic>(_protected),
      throwsA(
        isA<DioException>().having(
          (e) => e.error,
          'error',
          isA<ApiException>(),
        ),
      ),
    );

    // Tokens cleared.
    expect(storage.access, isNull);
    expect(storage.refresh, isNull);
    // Auth state flipped to unauthenticated.
    expect(
      container.read(authControllerProvider).value?.status,
      AuthStatus.unauthenticated,
    );
  });
}
