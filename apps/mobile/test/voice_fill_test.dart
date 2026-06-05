import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khatir_mobile/core/config/public_config_provider.dart';
import 'package:khatir_mobile/core/i18n/locale_provider.dart';
import 'package:khatir_mobile/core/network/api_endpoints.dart';
import 'package:khatir_mobile/core/network/dio_client.dart';
import 'package:khatir_mobile/features/properties/data/models/property_enums.dart';
import 'package:khatir_mobile/features/tenants/data/tenants_providers.dart';
import 'package:khatir_mobile/features/tenants/presentation/screens/add_tenant_screen.dart';
import 'package:khatir_mobile/features/tenants/presentation/screens/ocr_review_args.dart';
import 'package:khatir_mobile/features/tenants/presentation/screens/voice_fill_screen.dart';
import 'package:khatir_mobile/l10n/app_localizations.dart';

/// Fake recorder: [start] reports whether permission was granted; [stop]
/// returns a canned clip (or nothing), tracking calls so tests can assert the
/// record lifecycle without a live microphone or the `record` plugin.
class _FakeRecorder implements AudioRecorderService {
  _FakeRecorder({
    this.permitted = true,
    this.clip,
    this.stopThrows = false,
  });

  final bool permitted;
  final RecordedAudio? clip;
  final bool stopThrows;
  int startCalls = 0;
  int stopCalls = 0;
  int disposeCalls = 0;

  @override
  Future<bool> start() async {
    startCalls++;
    return permitted;
  }

  @override
  Future<RecordedAudio?> stop() async {
    stopCalls++;
    if (stopThrows) throw Exception('record failure');
    return clip;
  }

  @override
  Future<void> cancel() async {}

  @override
  Future<void> dispose() async {
    disposeCalls++;
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

  // Voice response mirrors OCR minus photo_ref (T-006 §7).
  final okPayload = <String, dynamic>{
    'name': {'value': 'Rahim Uddin', 'confidence': 0.96},
    'nid_number': {'value': '1990443322', 'confidence': 0.9},
    'dob': {'value': '1990-08-05', 'confidence': 0.85},
    'address': {'value': 'Sripur, Cumilla', 'confidence': 0.8},
  };

  RecordedAudio cannedClip() => RecordedAudio(
        bytes: Uint8List.fromList([1, 2, 3, 4]),
        filename: 'voice.m4a',
      );

  void tallView(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 2800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  Widget harness({
    required AudioRecorderService recorder,
    required _ScriptedAdapter adapter,
    bool voiceEnabled = true,
  }) {
    final router = GoRouter(
      initialLocation:
          '${AddTenantScreen.routePath}/${VoiceFillScreen.routePath}',
      routes: [
        GoRoute(
          path: AddTenantScreen.routePath,
          name: AddTenantScreen.routeName,
          builder: (context, state) => const SizedBox.shrink(),
          routes: [
            GoRoute(
              path: VoiceFillScreen.routePath,
              name: AddTenantScreen.voiceRouteName,
              builder: (context, state) => VoiceFillScreen(
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
        audioRecorderServiceProvider.overrideWithValue(recorder),
        publicConfigProvider.overrideWith(
          (ref) async => PublicConfig.withVoice(
            voiceTenantEntry: voiceEnabled,
            areaOptions: Area.values,
          ),
        ),
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

  testWidgets('renders the record stage (mic + prompt)', (tester) async {
    final recorder = _FakeRecorder();
    final adapter = _ScriptedAdapter((_) => _json(okPayload));
    tallView(tester);
    await tester.pumpWidget(harness(recorder: recorder, adapter: adapter));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('voiceMic')), findsOneWidget);
    expect(find.text(l10n.voice_tap_to_record), findsWidgets);
    expect(adapter.requests, isEmpty);
  });

  testWidgets('record → release → upload to /tenants/voice → review prefilled',
      (tester) async {
    final recorder = _FakeRecorder(clip: cannedClip());
    final adapter = _ScriptedAdapter((opts) {
      expect(opts.path, ApiEndpoints.tenantVoice);
      expect(opts.data, isA<FormData>());
      return _json(okPayload);
    });

    tallView(tester);
    await tester.pumpWidget(harness(recorder: recorder, adapter: adapter));
    await tester.pumpAndSettle();

    // Hold-to-talk: press starts, release stops + uploads.
    final mic = find.byKey(const ValueKey('voiceMic'));
    final gesture = await tester.startGesture(tester.getCenter(mic));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(recorder.startCalls, 1);
    expect(recorder.stopCalls, 1);
    expect(adapter.requests.length, 1);
    expect(adapter.requests.single.path, ApiEndpoints.tenantVoice);

    // Reused OCR review carries the extracted fields; voice has no photo_ref.
    expect(find.text('REVIEW:Rahim Uddin::-'), findsOneWidget);
  });

  testWidgets('denied mic permission shows error + retry', (tester) async {
    final recorder = _FakeRecorder(permitted: false);
    final adapter = _ScriptedAdapter((_) => _json(okPayload));

    tallView(tester);
    await tester.pumpWidget(harness(recorder: recorder, adapter: adapter));
    await tester.pumpAndSettle();

    final gesture =
        await tester.startGesture(tester.getCenter(find.byKey(const ValueKey('voiceMic'))));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(recorder.startCalls, 1);
    expect(adapter.requests, isEmpty); // never reached the upload
    expect(find.byKey(const ValueKey('voiceError')), findsOneWidget);
  });

  testWidgets('upload failure shows error + retry', (tester) async {
    final recorder = _FakeRecorder(clip: cannedClip());
    final adapter = _ScriptedAdapter(
      (_) => _json(<String, dynamic>{'detail': 'boom'}, status: 500),
    );

    tallView(tester);
    await tester.pumpWidget(harness(recorder: recorder, adapter: adapter));
    await tester.pumpAndSettle();

    final gesture =
        await tester.startGesture(tester.getCenter(find.byKey(const ValueKey('voiceMic'))));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(recorder.stopCalls, 1);
    expect(find.byKey(const ValueKey('voiceError')), findsOneWidget);
    expect(find.byKey(const ValueKey('voiceRetry')), findsOneWidget);
  });

  testWidgets('recorder failure on stop shows error', (tester) async {
    final recorder = _FakeRecorder(stopThrows: true);
    final adapter = _ScriptedAdapter((_) => _json(okPayload));

    tallView(tester);
    await tester.pumpWidget(harness(recorder: recorder, adapter: adapter));
    await tester.pumpAndSettle();

    final gesture = await tester
        .startGesture(tester.getCenter(find.byKey(const ValueKey('voiceMic'))));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    expect(recorder.stopCalls, 1);
    expect(adapter.requests, isEmpty); // never reached the upload
    expect(find.byKey(const ValueKey('voiceError')), findsOneWidget);
  });

  testWidgets('flag off → recorder not reachable (unavailable state)',
      (tester) async {
    final recorder = _FakeRecorder(clip: cannedClip());
    final adapter = _ScriptedAdapter((_) => _json(okPayload));

    tallView(tester);
    await tester.pumpWidget(
      harness(recorder: recorder, adapter: adapter, voiceEnabled: false),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('voiceUnavailable')), findsOneWidget);
    expect(find.byKey(const ValueKey('voiceMic')), findsNothing);
    expect(recorder.startCalls, 0);
    expect(adapter.requests, isEmpty);
  });
}
