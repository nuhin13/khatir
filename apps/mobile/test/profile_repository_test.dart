import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khatir_mobile/core/auth/auth_controller.dart';
import 'package:khatir_mobile/core/enums/role.dart';
import 'package:khatir_mobile/core/i18n/locale_provider.dart';
import 'package:khatir_mobile/core/network/api_endpoints.dart';
import 'package:khatir_mobile/core/network/dio_client.dart';
import 'package:khatir_mobile/core/storage/secure_storage.dart';
import 'package:khatir_mobile/features/profile/data/profile_providers.dart';

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

/// In-memory locale store so setLocale() never hits the platform keychain.
class FakeLocaleStorage extends FlutterSecureStorage {
  FakeLocaleStorage() : super();
  final Map<String, String> _store = {};

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async =>
      _store[key];

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value == null) {
      _store.remove(key);
    } else {
      _store[key] = value;
    }
  }
}

/// Scriptable adapter: maps a request to a canned response (or status).
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

ProviderContainer _container(
  SecureStorage storage,
  HttpClientAdapter adapter, {
  List<Override> overrides = const [],
}) {
  final container = ProviderContainer(
    overrides: [
      secureStorageProvider.overrideWithValue(storage),
      ...overrides,
    ],
  );
  addTearDown(container.dispose);
  container.read(dioClientProvider).httpClientAdapter = adapter;
  return container;
}

void main() {
  group('ProfileRepository', () {
    test('getProfile parses the /profile payload', () async {
      final storage = FakeSecureStorage(access: 'a', refresh: 'r');
      final adapter = ScriptedAdapter((options) {
        if (options.path == ApiEndpoints.profile &&
            options.method == 'GET') {
          return _json({
            'id': 'u1',
            'phone': '+8801711000111',
            'name': 'Karim',
            'role': 'landlord',
            'language': 'bn',
          });
        }
        return _json({}, status: 404);
      });
      final container = _container(storage, adapter);

      final repo = container.read(profileRepositoryProvider);
      final profile = await repo.getProfile();

      expect(profile.id, 'u1');
      expect(profile.name, 'Karim');
      expect(profile.role, Role.landlord);
      expect(profile.language, 'bn');
    });

    test('updateProfile PATCHes only the provided fields', () async {
      final storage = FakeSecureStorage(access: 'a', refresh: 'r');
      RequestOptions? patch;
      final adapter = ScriptedAdapter((options) {
        if (options.path == ApiEndpoints.profile &&
            options.method == 'PATCH') {
          patch = options;
          return _json({
            'id': 'u1',
            'role': 'manager',
            'language': 'en',
          });
        }
        return _json({}, status: 404);
      });
      final container = _container(storage, adapter);

      final repo = container.read(profileRepositoryProvider);
      final updated =
          await repo.updateProfile(role: Role.manager, language: 'en');

      final body = patch!.data as Map<String, dynamic>;
      expect(body, {'role': 'manager', 'language': 'en'});
      expect(body.containsKey('name'), isFalse);
      expect(updated.role, Role.manager);
      expect(updated.language, 'en');
    });
  });

  group('ProfileController propagation', () {
    test('setLanguage updates auth state + locale', () async {
      final storage = FakeSecureStorage(access: 'a', refresh: 'r');
      final adapter = ScriptedAdapter((options) {
        if (options.path == ApiEndpoints.me) {
          return _json({'id': 'u1', 'role': 'landlord', 'language': 'bn'});
        }
        if (options.path == ApiEndpoints.profile &&
            options.method == 'GET') {
          return _json({'id': 'u1', 'role': 'landlord', 'language': 'bn'});
        }
        if (options.path == ApiEndpoints.profile &&
            options.method == 'PATCH') {
          return _json({'id': 'u1', 'role': 'landlord', 'language': 'en'});
        }
        return _json({}, status: 404);
      });
      final container = _container(
        storage,
        adapter,
        overrides: [
          localeStorageProvider.overrideWithValue(FakeLocaleStorage()),
        ],
      );

      // Resolve auth + profile.
      await container.read(authControllerProvider.future);
      await container.read(profileProvider.future);

      await container.read(profileProvider.notifier).setLanguage('en');

      // Auth state carries the new language.
      final auth = container.read(authControllerProvider).requireValue;
      expect(auth.user?.language, 'en');
      // Locale provider flipped to English.
      expect(container.read(localeProvider), kLocaleEn);
    });

    test('setRole refetches /auth/me and updates the role in auth state',
        () async {
      final storage = FakeSecureStorage(access: 'a', refresh: 'r');
      var meCalls = 0;
      final adapter = ScriptedAdapter((options) {
        if (options.path == ApiEndpoints.me) {
          meCalls += 1;
          // First call (bootstrap) = tenant; after role change = manager.
          final role = meCalls <= 1 ? 'tenant' : 'manager';
          return _json({'id': 'u1', 'role': role, 'language': 'bn'});
        }
        if (options.path == ApiEndpoints.profile &&
            options.method == 'GET') {
          return _json({'id': 'u1', 'role': 'tenant', 'language': 'bn'});
        }
        if (options.path == ApiEndpoints.profile &&
            options.method == 'PATCH') {
          return _json({'id': 'u1', 'role': 'manager', 'language': 'bn'});
        }
        return _json({}, status: 404);
      });
      final container = _container(storage, adapter);

      final initial = await container.read(authControllerProvider.future);
      expect(initial.role, Role.tenant);
      await container.read(profileProvider.future);

      await container.read(profileProvider.notifier).setRole(Role.manager);

      // /auth/me was re-fetched (bootstrap + refresh after role change).
      expect(meCalls, 2);
      final auth = container.read(authControllerProvider).requireValue;
      expect(auth.role, Role.manager);
    });
  });
}
