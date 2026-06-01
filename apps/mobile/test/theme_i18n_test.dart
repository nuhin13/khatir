import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khatir_mobile/app.dart';
import 'package:khatir_mobile/core/i18n/bangla_numerals.dart';
import 'package:khatir_mobile/core/i18n/locale_provider.dart';
import 'package:khatir_mobile/core/network/api_endpoints.dart';
import 'package:khatir_mobile/core/network/dio_client.dart';
import 'package:khatir_mobile/core/router/app_router.dart';
import 'package:khatir_mobile/core/storage/secure_storage.dart';
import 'package:khatir_mobile/core/theme/app_theme.dart';
import 'package:khatir_mobile/features/home_placeholder/presentation/screens/home_placeholder_screen.dart';
import 'package:khatir_tokens/khatir_tokens.dart';

/// In-memory secure storage so tests don't touch the platform keychain.
class _FakeSecureStorage extends FlutterSecureStorage {
  _FakeSecureStorage() : super();
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

/// In-memory token store (auth controller side) so bootstrap can resolve an
/// authenticated session and the app lands on the home placeholder.
class _FakeTokenStorage implements SecureStorage {
  _FakeTokenStorage({this.access, this.refresh});
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

ResponseBody _json(Map<String, dynamic> body, {int status = 200}) =>
    ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

void main() {
  ProviderContainer? container;

  Widget app() => UncontrolledProviderScope(
        container: container!,
        child: const KhatirApp(),
      );

  /// Boots [KhatirApp] straight into the authenticated home placeholder by
  /// scripting a passing `/auth/me` and marking onboarding seen, so theme and
  /// locale can be asserted on a stable screen.
  void seedAuthenticatedHome() {
    container = ProviderContainer(
      overrides: [
        localeStorageProvider.overrideWithValue(_FakeSecureStorage()),
        secureStorageProvider
            .overrideWithValue(_FakeTokenStorage(access: 'a', refresh: 'r')),
        onboardingSeenProvider.overrideWith((ref) async => true),
      ],
    );
    container!.read(dioClientProvider).httpClientAdapter =
        _ScriptedAdapter((options) {
      if (options.path == ApiEndpoints.me) {
        return _json({'id': 'u1', 'role': 'landlord'});
      }
      return _json({}, status: 404);
    });
  }

  setUp(() {
    container = ProviderContainer(
      overrides: [
        localeStorageProvider.overrideWithValue(_FakeSecureStorage()),
      ],
    );
  });

  tearDown(() => container?.dispose());

  testWidgets('app builds with the token-driven Notun Din theme',
      (tester) async {
    seedAuthenticatedHome();
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(find.byType(HomePlaceholderScreen), findsOneWidget);
    final ctx = tester.element(find.byType(Scaffold).first);
    expect(Theme.of(ctx).colorScheme.primary, KhatirColors.sage);
    expect(Theme.of(ctx).scaffoldBackgroundColor, KhatirColors.cream);
  });

  testWidgets('defaults to Bangla, locale toggle switches the rendered string',
      (tester) async {
    seedAuthenticatedHome();
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    // Bangla default (home placeholder welcome copy).
    expect(find.text('আপনি সাইন ইন করেছেন'), findsOneWidget);
    expect(find.text("You're signed in"), findsNothing);

    // Switch locale via the controller (the launch UI no longer hosts a toggle
    // button after T-012 removed the EPIC-00 placeholder screen).
    await container!.read(localeProvider.notifier).setLocale(kLocaleEn);
    await tester.pumpAndSettle();

    // Now English.
    expect(find.text("You're signed in"), findsOneWidget);
    expect(find.text('আপনি সাইন ইন করেছেন'), findsNothing);
  });

  test('locale choice persists across a fresh controller', () async {
    final storage = _FakeSecureStorage();
    final c1 = ProviderContainer(
      overrides: [localeStorageProvider.overrideWithValue(storage)],
    );
    await c1.read(localeProvider.notifier).setLocale(kLocaleEn);
    c1.dispose();

    // A new controller reading the same storage should load English.
    final controller = LocaleController(storage);
    // Let the async _load() complete.
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(controller.state.languageCode, kLocaleEn.languageCode);
    controller.dispose();
  });

  test('Bangla numeral helper renders Bengali digits', () {
    expect(BanglaNumerals.toBangla('2026'), '২০২৬');
    expect(BanglaNumerals.format(2026, 'en'), '2,026');
  });

  test('soft shadow token is defined for cards/nav', () {
    expect(AppTheme.softShadow, isNotEmpty);
  });
}
