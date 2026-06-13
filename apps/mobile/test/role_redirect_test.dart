import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khatir_mobile/core/i18n/locale_provider.dart';
import 'package:khatir_mobile/core/network/api_endpoints.dart';
import 'package:khatir_mobile/core/network/dio_client.dart';
import 'package:khatir_mobile/core/router/app_router.dart';
import 'package:khatir_mobile/core/storage/secure_storage.dart';
import 'package:khatir_mobile/features/auth/presentation/screens/phone_entry_screen.dart';
import 'package:khatir_mobile/features/role/presentation/screens/role_chooser_screen.dart';
import 'package:khatir_mobile/features/shell/landlord_shell.dart';
import 'package:khatir_mobile/features/shell/manager_shell.dart';
import 'package:khatir_mobile/features/shell/tenant_shell.dart';
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

/// Adapter that resolves `/auth/me` to a session with the given [role]
/// (`null` => the `role` key is omitted, i.e. role-not-yet-chosen).
ScriptedAdapter _meAdapter(String? role) => ScriptedAdapter((options) {
      if (options.path == ApiEndpoints.me) {
        return _json({'id': 'u1', if (role != null) 'role': role});
      }
      return _json({}, status: 404);
    });

/// Builds the app harness driving the real [appRouterProvider] redirect with a
/// scripted `/auth/me` and an overridden onboarding-seen flag. Captures the
/// live [GoRouter] so tests can drive `go(...)` to exercise wrong-role bounce.
class _Harness {
  GoRouter? router;
}

Widget _buildApp({
  required SecureStorage storage,
  required HttpClientAdapter adapter,
  required _Harness harness,
}) {
  return ProviderScope(
    overrides: [
      secureStorageProvider.overrideWithValue(storage),
      onboardingSeenProvider.overrideWith((ref) async => true),
    ],
    child: Consumer(
      builder: (context, ref, _) {
        ref.read(dioClientProvider).httpClientAdapter = adapter;
        final router = ref.watch(appRouterProvider);
        harness.router = router;
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
  testWidgets('authenticated + no role → /role (role chooser)',
      (tester) async {
    final storage = FakeSecureStorage(access: 'a', refresh: 'r');
    final harness = _Harness();

    await tester.pumpWidget(
      _buildApp(storage: storage, adapter: _meAdapter(null), harness: harness),
    );
    await tester.pumpAndSettle();

    expect(find.byType(RoleChooserScreen), findsOneWidget);
    expect(find.byType(LandlordShell), findsNothing);
  });

  testWidgets('unauthenticated → /auth/phone', (tester) async {
    final storage = FakeSecureStorage(); // no tokens
    final harness = _Harness();

    await tester.pumpWidget(
      _buildApp(storage: storage, adapter: _meAdapter(null), harness: harness),
    );
    await tester.pumpAndSettle();

    expect(find.byType(PhoneEntryScreen), findsOneWidget);
  });

  testWidgets('authenticated landlord → /landlord/home (landlord shell)',
      (tester) async {
    final storage = FakeSecureStorage(access: 'a', refresh: 'r');
    final harness = _Harness();

    await tester.pumpWidget(
      _buildApp(
        storage: storage,
        adapter: _meAdapter('landlord'),
        harness: harness,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LandlordShell), findsOneWidget);
  });

  testWidgets('authenticated manager → manager shell', (tester) async {
    final storage = FakeSecureStorage(access: 'a', refresh: 'r');
    final harness = _Harness();

    await tester.pumpWidget(
      _buildApp(
        storage: storage,
        adapter: _meAdapter('manager'),
        harness: harness,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ManagerShell), findsOneWidget);
  });

  testWidgets('authenticated tenant → tenant shell', (tester) async {
    final storage = FakeSecureStorage(access: 'a', refresh: 'r');
    final harness = _Harness();

    await tester.pumpWidget(
      _buildApp(
        storage: storage,
        adapter: _meAdapter('tenant'),
        harness: harness,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(TenantShell), findsOneWidget);
  });

  testWidgets('landlord visiting /manager/* → bounced to landlord shell',
      (tester) async {
    final storage = FakeSecureStorage(access: 'a', refresh: 'r');
    final harness = _Harness();

    await tester.pumpWidget(
      _buildApp(
        storage: storage,
        adapter: _meAdapter('landlord'),
        harness: harness,
      ),
    );
    await tester.pumpAndSettle();

    // Lands in the landlord shell first.
    expect(find.byType(LandlordShell), findsOneWidget);

    // Try to wander into the manager shell → redirect bounces back.
    harness.router!.go('/manager/home');
    await tester.pumpAndSettle();

    expect(find.byType(LandlordShell), findsOneWidget);
    expect(find.byType(ManagerShell), findsNothing);
  });

  testWidgets('landlord can still reach /role (switch role from More)',
      (tester) async {
    final storage = FakeSecureStorage(access: 'a', refresh: 'r');
    final harness = _Harness();

    await tester.pumpWidget(
      _buildApp(
        storage: storage,
        adapter: _meAdapter('landlord'),
        harness: harness,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LandlordShell), findsOneWidget);

    // Re-entering the chooser intentionally must NOT be bounced away.
    harness.router!.go(RoleChooserScreen.routePath);
    await tester.pumpAndSettle();

    expect(find.byType(RoleChooserScreen), findsOneWidget);
    expect(find.byType(LandlordShell), findsNothing);
  });
}
