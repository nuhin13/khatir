import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khatir_mobile/core/i18n/locale_provider.dart';
import 'package:khatir_mobile/core/network/api_endpoints.dart';
import 'package:khatir_mobile/core/network/dio_client.dart';
import 'package:khatir_mobile/core/router/app_router.dart';
import 'package:khatir_mobile/core/storage/secure_storage.dart';
import 'package:khatir_mobile/features/auth/presentation/screens/phone_entry_screen.dart';
import 'package:khatir_mobile/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:khatir_mobile/features/shell/landlord_shell.dart';
import 'package:khatir_mobile/features/splash/presentation/screens/splash_screen.dart';
import 'package:khatir_mobile/l10n/app_localizations.dart';

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

/// Scriptable adapter: maps a request path to a canned response.
class ScriptedAdapter implements HttpClientAdapter {
  ScriptedAdapter(this.handler);

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

/// Builds the app harness driving the real [appRouterProvider] redirect with
/// scripted auth + a directly-overridden onboarding-seen flag.
Widget _harness({
  required bool seen,
  required SecureStorage storage,
  required HttpClientAdapter adapter,
}) {
  return ProviderScope(
    overrides: [
      secureStorageProvider.overrideWithValue(storage),
      onboardingSeenProvider.overrideWith((ref) async => seen),
    ],
    child: Consumer(
      builder: (context, ref, _) {
        // Install the scripted adapter on the shared dio client.
        ref.read(dioClientProvider).httpClientAdapter = adapter;
        final router = ref.watch(appRouterProvider);
        return MaterialApp.router(
          routerConfig: router,
          locale: kLocaleBn,
          supportedLocales: kSupportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
        );
      },
    ),
  );
}

void main() {
  testWidgets('first launch (onboarding not seen) → /onboarding',
      (tester) async {
    final storage = FakeSecureStorage();
    final adapter = ScriptedAdapter((_) => _json({}));

    await tester.pumpWidget(
      _harness(seen: false, storage: storage, adapter: adapter),
    );
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.byType(SplashScreen), findsNothing);
  });

  testWidgets('seen + unauthenticated → /auth/phone', (tester) async {
    // No tokens → bootstrap resolves unauthenticated, no network call.
    final storage = FakeSecureStorage();
    final adapter = ScriptedAdapter((_) => _json({}, status: 404));

    await tester.pumpWidget(
      _harness(seen: true, storage: storage, adapter: adapter),
    );
    await tester.pumpAndSettle();

    expect(find.byType(PhoneEntryScreen), findsOneWidget);
    expect(find.byType(LandlordShell), findsNothing);
  });

  testWidgets('seen + authenticated landlord → landlord shell', (tester) async {
    // Stored tokens + a passing /auth/me → bootstrap resolves authenticated.
    final storage = FakeSecureStorage(access: 'a', refresh: 'r');
    final adapter = ScriptedAdapter((options) {
      if (options.path == ApiEndpoints.me) {
        return _json({'id': 'u1', 'role': 'landlord'});
      }
      return _json({}, status: 404);
    });

    await tester.pumpWidget(
      _harness(seen: true, storage: storage, adapter: adapter),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LandlordShell), findsOneWidget);
    expect(find.byType(PhoneEntryScreen), findsNothing);
  });
}
