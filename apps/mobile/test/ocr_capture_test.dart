import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khatir_mobile/core/i18n/locale_provider.dart';
import 'package:khatir_mobile/core/network/api_endpoints.dart';
import 'package:khatir_mobile/core/network/dio_client.dart';
import 'package:khatir_mobile/features/tenants/data/tenants_providers.dart';
import 'package:khatir_mobile/features/tenants/presentation/screens/add_tenant_screen.dart';
import 'package:khatir_mobile/features/tenants/presentation/screens/ocr_capture_screen.dart';
import 'package:khatir_mobile/features/tenants/presentation/screens/ocr_review_args.dart';
import 'package:khatir_mobile/l10n/app_localizations.dart';

/// Fake picker that returns canned bytes (camera/gallery), nothing (cancel), or
/// throws (permission denied), depending on the configured behaviour.
class _FakePicker implements ImagePickerService {
  _FakePicker({this.result, this.throws = false});

  final PickedImage? result;
  final bool throws;
  int cameraCalls = 0;
  int galleryCalls = 0;

  @override
  Future<PickedImage?> pickFromCamera() async {
    cameraCalls++;
    if (throws) throw Exception('permission denied');
    return result;
  }

  @override
  Future<PickedImage?> pickFromGallery() async {
    galleryCalls++;
    if (throws) throw Exception('permission denied');
    return result;
  }
}

/// Scriptable adapter mapping a request to a canned response, recording calls.
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

ResponseBody _json(Map<String, dynamic> body, {int status = 200}) =>
    ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

void main() {
  late AppLocalizations l10n;

  setUp(() async {
    l10n = await AppLocalizations.delegate.load(kLocaleBn);
  });

  final okPayload = <String, dynamic>{
    'name': {'value': 'Karim Hossain', 'confidence': 0.97},
    'nid_number': {'value': '1992556677', 'confidence': 0.95},
    'dob': {'value': '1992-03-12', 'confidence': 0.9},
    'address': {'value': 'Mirpur 10, Dhaka', 'confidence': 0.8},
    'photo_ref': 'ref-abc123',
  };

  /// The capture screen is a scrollable [ListView]; a tall test viewport lets
  /// the (lazily built) action buttons render without scrolling.
  void tallView(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  Widget harness({
    required ImagePickerService picker,
    required _ScriptedAdapter adapter,
  }) {
    final router = GoRouter(
      initialLocation:
          '${AddTenantScreen.routePath}/${OcrCaptureScreen.routePath}',
      routes: [
        GoRoute(
          path: AddTenantScreen.routePath,
          name: AddTenantScreen.routeName,
          builder: (context, state) => const SizedBox.shrink(),
          routes: [
            GoRoute(
              path: OcrCaptureScreen.routePath,
              name: AddTenantScreen.ocrRouteName,
              builder: (context, state) => OcrCaptureScreen(
                unitId: state.uri.queryParameters['unit'],
              ),
              routes: [
                GoRoute(
                  path: OcrReviewArgs.routePath,
                  name: OcrReviewArgs.routeName,
                  builder: (context, state) {
                    final args = state.extra as OcrReviewArgs?;
                    return Scaffold(
                      body: Center(
                        child: Text(
                          'REVIEW:'
                          '${args?.extracted.name.value}:'
                          '${args?.extracted.photoRef}:'
                          '${args?.unitId ?? '-'}',
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        imagePickerServiceProvider.overrideWithValue(picker),
        // Bare dio (no auth interceptor) wired to the scripted adapter.
        dioClientProvider.overrideWith((ref) {
          return Dio(BaseOptions(baseUrl: 'http://test.local'))
            ..httpClientAdapter = adapter;
        }),
      ],
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

  testWidgets('renders the capture stage (frame + actions)', (tester) async {
    final picker = _FakePicker(result: null);
    final adapter = _ScriptedAdapter((_) => _json(okPayload));
    tallView(tester);
    await tester.pumpWidget(harness(picker: picker, adapter: adapter));
    await tester.pumpAndSettle();

    expect(find.text(l10n.ocr_take_photo), findsOneWidget);
    expect(find.text(l10n.ocr_from_gallery), findsOneWidget);
    expect(find.byKey(const ValueKey('ocrTakePhoto')), findsOneWidget);
  });

  testWidgets('capture → upload called → navigates to review with fields',
      (tester) async {
    final picker = _FakePicker(
      result: PickedImage(
        bytes: Uint8List.fromList([1, 2, 3, 4]),
        filename: 'nid.jpg',
      ),
    );
    final adapter = _ScriptedAdapter((opts) {
      expect(opts.path, ApiEndpoints.tenantOcr);
      expect(opts.data, isA<FormData>());
      return _json(okPayload);
    });

    tallView(tester);
    await tester.pumpWidget(harness(picker: picker, adapter: adapter));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('ocrTakePhoto')));
    await tester.pumpAndSettle();

    // Upload happened exactly once to /tenants/ocr.
    expect(picker.cameraCalls, 1);
    expect(adapter.requests.length, 1);
    expect(adapter.requests.single.path, ApiEndpoints.tenantOcr);

    // Navigated to review carrying the extracted fields + photo_ref.
    expect(find.text('REVIEW:Karim Hossain:ref-abc123:-'), findsOneWidget);
  });

  testWidgets('cancelling the picker keeps the capture stage', (tester) async {
    final picker = _FakePicker(result: null); // user cancelled
    final adapter = _ScriptedAdapter((_) => _json(okPayload));

    tallView(tester);
    await tester.pumpWidget(harness(picker: picker, adapter: adapter));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('ocrTakePhoto')));
    await tester.pumpAndSettle();

    expect(picker.cameraCalls, 1);
    expect(adapter.requests, isEmpty); // no upload
    expect(find.byKey(const ValueKey('ocrTakePhoto')), findsOneWidget);
  });

  testWidgets('picker error (e.g. denied permission) shows error + retry',
      (tester) async {
    final picker = _FakePicker(throws: true);
    final adapter = _ScriptedAdapter((_) => _json(okPayload));

    tallView(tester);
    await tester.pumpWidget(harness(picker: picker, adapter: adapter));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('ocrTakePhoto')));
    await tester.pumpAndSettle();

    expect(picker.cameraCalls, 1);
    expect(adapter.requests, isEmpty); // never reached the upload
    expect(find.byKey(const ValueKey('ocrError')), findsOneWidget);
  });

  testWidgets('upload failure shows error + retry', (tester) async {
    final picker = _FakePicker(
      result: PickedImage(
        bytes: Uint8List.fromList([9, 9]),
        filename: 'nid.jpg',
      ),
    );
    final adapter = _ScriptedAdapter(
      (_) => _json(<String, dynamic>{'detail': 'boom'}, status: 500),
    );

    tallView(tester);
    await tester.pumpWidget(harness(picker: picker, adapter: adapter));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('ocrTakePhoto')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('ocrError')), findsOneWidget);
    expect(find.byKey(const ValueKey('ocrRetry')), findsOneWidget);
  });
}
