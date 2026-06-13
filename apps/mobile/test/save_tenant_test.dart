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
import 'package:khatir_mobile/core/storage/secure_storage.dart';
import 'package:khatir_mobile/features/tenants/data/models/extracted_tenant.dart';
import 'package:khatir_mobile/features/tenants/presentation/screens/dmp_placeholder_screen.dart';
import 'package:khatir_mobile/features/tenants/presentation/screens/manual_tenant_screen.dart';
import 'package:khatir_mobile/features/tenants/presentation/screens/ocr_review_args.dart';
import 'package:khatir_mobile/features/tenants/presentation/screens/ocr_review_screen.dart';
import 'package:khatir_mobile/l10n/app_localizations.dart';

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

/// Scriptable adapter: maps a request to a canned response and records calls.
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

Map<String, dynamic> _maskedTenant({
  String id = 't1',
  Map<String, dynamic> extra = const {},
}) =>
    <String, dynamic>{
      'id': id,
      'name': 'Karim Uddin',
      'nid_number_masked': '****7788',
      'dob': '1990-05-10',
      'address': 'Road 5, Uttara',
      'photo_ref': 'nid/abc123',
      'verification_status': 'unverified',
      'verified_at': null,
      'is_app_user': false,
      'family_members': <Map<String, dynamic>>[],
      'created_at': '2026-06-01T00:00:00Z',
      'updated_at': '2026-06-02T00:00:00Z',
      ...extra,
    };

void main() {
  late AppLocalizations l10n;

  setUp(() async {
    l10n = await AppLocalizations.delegate.load(kLocaleBn);
  });

  void tallView(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  /// A `MaterialApp.router` rooted at a single screen, with the DMP placeholder
  /// route registered so the convergent save action can navigate there. The dio
  /// client is overridden with [adapter] so creates hit the scripted server.
  Widget harness({
    required Widget screen,
    required String initialPath,
    required _ScriptedAdapter adapter,
  }) {
    final router = GoRouter(
      initialLocation: initialPath,
      routes: [
        GoRoute(path: initialPath, builder: (context, state) => screen),
        GoRoute(
          path: '/dmpform/:tenantId',
          name: DmpPlaceholderScreen.routeName,
          builder: (context, state) => DmpPlaceholderScreen(
            tenantId: state.pathParameters['tenantId'] ?? '',
          ),
        ),
      ],
    );

    final container = ProviderContainer(
      overrides: [
        secureStorageProvider.overrideWithValue(_FakeSecureStorage()),
      ],
    );
    addTearDown(container.dispose);
    container.read(dioClientProvider).httpClientAdapter = adapter;

    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        routerConfig: router,
        locale: kLocaleBn,
        supportedLocales: kSupportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
      ),
    );
  }

  testWidgets(
      'manual save: POSTs merged fields and routes to the DMP form (no unit)',
      (tester) async {
    RequestOptions? post;
    final adapter = _ScriptedAdapter((options) {
      if (options.path == ApiEndpoints.tenants && options.method == 'POST') {
        post = options;
        return _json(_maskedTenant(id: 't9'), status: 201);
      }
      return _json(<String, dynamic>{}, status: 404);
    });

    tallView(tester);
    await tester.pumpWidget(
      harness(
        screen: const ManualTenantScreen(),
        initialPath: '/manual',
        adapter: adapter,
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('manualName')),
      'Karim Uddin',
    );
    await tester.enterText(
      find.byKey(const ValueKey('manualNid')),
      '1990123456788',
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('manualProceed')));
    await tester.pumpAndSettle();

    // The reviewed fields reached the create endpoint.
    expect(post, isNotNull);
    final body = post!.data as Map<String, dynamic>;
    expect(body['name'], 'Karim Uddin');
    expect(body['nid_number'], '1990123456788');

    // Success → navigated to the DMP placeholder for the created tenant.
    expect(find.byType(DmpPlaceholderScreen), findsOneWidget);
    expect(find.text(l10n.dmp_placeholder_heading), findsOneWidget);
  });

  testWidgets(
      'manual save: routes through the unit-scoped create when a unit is set',
      (tester) async {
    var createCalls = 0;
    var listCalls = 0;
    final adapter = _ScriptedAdapter((options) {
      if (options.path == ApiEndpoints.tenants && options.method == 'POST') {
        createCalls++;
        return _json(_maskedTenant(id: 't9'), status: 201);
      }
      if (options.path == ApiEndpoints.unitTenants('u7') &&
          options.method == 'GET') {
        listCalls++;
        return _json(<Map<String, dynamic>>[]);
      }
      return _json(<String, dynamic>{}, status: 404);
    });

    tallView(tester);
    await tester.pumpWidget(
      harness(
        screen: const ManualTenantScreen(unitId: 'u7'),
        initialPath: '/manual',
        adapter: adapter,
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('manualName')),
      'Karim Uddin',
    );
    await tester.enterText(
      find.byKey(const ValueKey('manualNid')),
      '1990123456788',
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('manualProceed')));
    await tester.pumpAndSettle();

    expect(createCalls, 1);
    // The unit-scoped controller refreshes the unit's list after the create.
    expect(listCalls, greaterThanOrEqualTo(1));
    expect(find.byType(DmpPlaceholderScreen), findsOneWidget);
  });

  testWidgets('save surfaces the free-tier toast when the server reports usage',
      (tester) async {
    final adapter = _ScriptedAdapter((options) {
      if (options.path == ApiEndpoints.tenants && options.method == 'POST') {
        return _json(
          _maskedTenant(
            id: 't9',
            extra: {
              'tenants_used': 1,
              'free_limit': 2,
              'is_over_free': false,
            },
          ),
          status: 201,
        );
      }
      return _json(<String, dynamic>{}, status: 404);
    });

    tallView(tester);
    await tester.pumpWidget(
      harness(
        screen: const ManualTenantScreen(),
        initialPath: '/manual',
        adapter: adapter,
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('manualName')),
      'Karim Uddin',
    );
    await tester.enterText(
      find.byKey(const ValueKey('manualNid')),
      '1990123456788',
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('manualProceed')));
    await tester.pumpAndSettle();

    expect(find.text(l10n.tenant_free_tier_status(1, 2)), findsOneWidget);
  });

  testWidgets('save shows an error snackbar and stays on the form on failure',
      (tester) async {
    final adapter = _ScriptedAdapter((options) {
      if (options.path == ApiEndpoints.tenants && options.method == 'POST') {
        return _json({'detail': 'boom'}, status: 500);
      }
      return _json(<String, dynamic>{}, status: 404);
    });

    tallView(tester);
    await tester.pumpWidget(
      harness(
        screen: const ManualTenantScreen(),
        initialPath: '/manual',
        adapter: adapter,
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('manualName')),
      'Karim Uddin',
    );
    await tester.enterText(
      find.byKey(const ValueKey('manualNid')),
      '1990123456788',
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('manualProceed')));
    await tester.pumpAndSettle();

    // Error surfaced, no navigation, the form is still shown and re-enabled.
    expect(find.text(l10n.tenant_save_error), findsOneWidget);
    expect(find.byType(DmpPlaceholderScreen), findsNothing);
    expect(find.byKey(const ValueKey('manualProceed')), findsOneWidget);
  });

  testWidgets('OCR/voice review save routes to the DMP form with photo_ref',
      (tester) async {
    RequestOptions? post;
    final adapter = _ScriptedAdapter((options) {
      if (options.path == ApiEndpoints.tenants && options.method == 'POST') {
        post = options;
        return _json(_maskedTenant(id: 't5'), status: 201);
      }
      return _json(<String, dynamic>{}, status: 404);
    });

    const extracted = ExtractedTenant(
      name: ExtractedField(value: 'Karim Uddin'),
      nidNumber: ExtractedField(value: '1990123456788'),
      dob: ExtractedField(value: '1990-05-10'),
      address: ExtractedField(value: 'Uttara'),
      photoRef: 'nid/abc123',
    );

    tallView(tester);
    await tester.pumpWidget(
      harness(
        screen: const OcrReviewScreen(
          args: OcrReviewArgs(extracted: extracted),
        ),
        initialPath: '/review',
        adapter: adapter,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('ocrProceed')));
    await tester.pumpAndSettle();

    expect(post, isNotNull);
    final body = post!.data as Map<String, dynamic>;
    expect(body['name'], 'Karim Uddin');
    expect(body['photo_ref'], 'nid/abc123');
    expect(find.byType(DmpPlaceholderScreen), findsOneWidget);
  });
}
