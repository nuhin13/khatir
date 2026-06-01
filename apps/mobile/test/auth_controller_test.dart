import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khatir_mobile/core/auth/auth_controller.dart';
import 'package:khatir_mobile/core/auth/auth_state.dart';
import 'package:khatir_mobile/core/enums/role.dart';
import 'package:khatir_mobile/core/network/api_endpoints.dart';
import 'package:khatir_mobile/core/network/dio_client.dart';
import 'package:khatir_mobile/core/storage/secure_storage.dart';

/// In-memory secure storage so tests never touch the platform channel.
class FakeSecureStorage implements SecureStorage {
  FakeSecureStorage({this.access, this.refresh});
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

/// Scriptable adapter: maps a request path to a canned response (or status).
class ScriptedAdapter implements HttpClientAdapter {
  ScriptedAdapter(this.handler);

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

ResponseBody _json(Map<String, dynamic> body, {int status = 200}) =>
    ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

ProviderContainer _container(SecureStorage storage, HttpClientAdapter adapter) {
  final container = ProviderContainer(
    overrides: [
      secureStorageProvider.overrideWithValue(storage),
    ],
  );
  addTearDown(container.dispose);
  // Install the scripted adapter on the shared dio client.
  container.read(dioClientProvider).httpClientAdapter = adapter;
  return container;
}

void main() {
  group('AuthController.setSession', () {
    test('persists tokens and flips state to authenticated', () async {
      final storage = FakeSecureStorage();
      final adapter = ScriptedAdapter((_) => _json({}));
      final container = _container(storage, adapter);

      // Resolve the initial (unauthenticated) build.
      await container.read(authControllerProvider.future);

      await container.read(authControllerProvider.notifier).setSession(
            access: 'access-1',
            refresh: 'refresh-1',
            user: const SessionUser(id: 'u1', role: Role.landlord),
          );

      // Tokens persisted.
      expect(storage.access, 'access-1');
      expect(storage.refresh, 'refresh-1');

      // State authenticated with the seeded user.
      final state = container.read(authControllerProvider).requireValue;
      expect(state.status, AuthStatus.authenticated);
      expect(state.user?.id, 'u1');
      expect(state.user?.role, Role.landlord);
    });
  });

  group('AuthController.build (bootstrap)', () {
    test('no tokens → unauthenticated, no network call', () async {
      final storage = FakeSecureStorage();
      final adapter = ScriptedAdapter((_) => _json({}));
      final container = _container(storage, adapter);

      final state = await container.read(authControllerProvider.future);
      expect(state.status, AuthStatus.unauthenticated);
      expect(adapter.requests, isEmpty);
    });

    test('stored tokens + /auth/me → authenticated with restored user',
        () async {
      final storage = FakeSecureStorage(access: 'a', refresh: 'r');
      final adapter = ScriptedAdapter((options) {
        if (options.path == ApiEndpoints.me) {
          return _json({
            'id': 'u9',
            'phone': '+8801711000111',
            'role': 'manager',
            'name': 'Karim',
            'language': 'bn',
          });
        }
        return _json({}, status: 404);
      });
      final container = _container(storage, adapter);

      final state = await container.read(authControllerProvider.future);
      expect(state.status, AuthStatus.authenticated);
      expect(state.user?.id, 'u9');
      expect(state.user?.role, Role.manager);
      expect(state.user?.name, 'Karim');
      // /auth/me carried the bearer token.
      final meReq =
          adapter.requests.firstWhere((r) => r.path == ApiEndpoints.me);
      expect(meReq.headers['Authorization'], 'Bearer a');
    });
  });

  group('AuthController.logout', () {
    test('clears tokens, calls /auth/logout, sets unauthenticated', () async {
      final storage = FakeSecureStorage(access: 'a', refresh: 'r');
      var logoutHit = false;
      final adapter = ScriptedAdapter((options) {
        if (options.path == ApiEndpoints.me) {
          return _json({'id': 'u1', 'role': 'landlord'});
        }
        if (options.path == ApiEndpoints.logout) {
          logoutHit = true;
          return _json({}, status: 205);
        }
        return _json({}, status: 404);
      });
      final container = _container(storage, adapter);

      await container.read(authControllerProvider.future);
      await container.read(authControllerProvider.notifier).logout();

      expect(logoutHit, isTrue);
      expect(storage.access, isNull);
      expect(storage.refresh, isNull);
      expect(
        container.read(authControllerProvider).requireValue.status,
        AuthStatus.unauthenticated,
      );
    });
  });
}
