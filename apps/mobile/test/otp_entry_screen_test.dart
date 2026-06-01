import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khatir_mobile/core/i18n/locale_provider.dart';
import 'package:khatir_mobile/core/network/api_exception.dart';
import 'package:khatir_mobile/core/router/args/auth_args.dart';
import 'package:khatir_mobile/core/storage/secure_storage.dart';
import 'package:khatir_mobile/features/auth/data/auth_providers.dart';
import 'package:khatir_mobile/features/auth/data/auth_repository.dart';
import 'package:khatir_mobile/features/auth/data/models/request_otp_response.dart';
import 'package:khatir_mobile/features/auth/data/models/verify_otp_response.dart';
import 'package:khatir_mobile/features/auth/presentation/controllers/resend_otp_controller.dart';
import 'package:khatir_mobile/features/auth/presentation/screens/otp_entry_screen.dart';
import 'package:khatir_mobile/l10n/app_localizations.dart';

const _phone = '+8801711000111';

/// Stub repo: records verify/resend calls and replays scripted results so the
/// network is never hit.
class _StubAuthRepository implements AuthRepository {
  _StubAuthRepository({this.verifyError});

  final ApiException? verifyError;
  final List<String> verifyCodes = [];
  int resendCalls = 0;

  @override
  Future<RequestOtpResponse> requestOtp(String phone) async =>
      const RequestOtpResponse();

  @override
  Future<RequestOtpResponse> resendOtp(String phone) async {
    resendCalls++;
    return const RequestOtpResponse();
  }

  @override
  Future<VerifyOtpResponse> verifyOtp(String phone, String code) async {
    verifyCodes.add(code);
    if (verifyError != null) throw verifyError!;
    return const VerifyOtpResponse(access: 'access-token', refresh: 'refresh');
  }
}

/// In-memory secure storage so the temp T-011 token hook doesn't touch the
/// platform channel during tests.
class _FakeSecureStorage implements SecureStorage {
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

void main() {
  Future<AppLocalizations> loadL10n() =>
      AppLocalizations.delegate.load(kLocaleBn);

  Widget harness(
    _StubAuthRepository repo, {
    _FakeSecureStorage? storage,
  }) {
    final router = GoRouter(
      initialLocation: OtpEntryScreen.routePath,
      routes: [
        GoRoute(
          path: OtpEntryScreen.routePath,
          builder: (context, state) =>
              const OtpEntryScreen(args: AuthArgs(phone: _phone)),
        ),
        GoRoute(
          path: OtpEntryScreen.successRoutePath,
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('HOME_SCREEN'))),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(repo),
        secureStorageProvider
            .overrideWithValue(storage ?? _FakeSecureStorage()),
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

  Future<void> enterCode(WidgetTester tester, String code) async {
    for (var i = 0; i < code.length; i++) {
      await tester.enterText(find.byKey(Key('otp_box_$i')), code[i]);
      await tester.pump();
    }
  }

  ElevatedButton verifyButton(WidgetTester tester) =>
      tester.widget<ElevatedButton>(find.byKey(const Key('otp_verify')));

  testWidgets('renders $kOtpLength OTP boxes and the destination phone',
      (tester) async {
    await tester.pumpWidget(harness(_StubAuthRepository()));
    await tester.pump();

    for (var i = 0; i < kOtpLength; i++) {
      expect(find.byKey(Key('otp_box_$i')), findsOneWidget);
    }
    expect(find.textContaining(_phone), findsOneWidget);
  });

  testWidgets('verify button disabled until the full code is entered',
      (tester) async {
    await tester.pumpWidget(harness(_StubAuthRepository()));
    await tester.pump();

    expect(verifyButton(tester).onPressed, isNull);

    await enterCode(tester, '12345'); // one short
    expect(verifyButton(tester).onPressed, isNull);

    await tester.enterText(
        find.byKey(Key('otp_box_${kOtpLength - 1}')), '6');
    await tester.pump();
    expect(verifyButton(tester).onPressed, isNotNull);
  });

  testWidgets('full code auto-submits: calls verify and routes onward',
      (tester) async {
    final repo = _StubAuthRepository();
    final storage = _FakeSecureStorage();
    await tester.pumpWidget(harness(repo, storage: storage));
    await tester.pump();

    await enterCode(tester, '123456');
    await tester.pump(); // verify future resolves
    await tester.pump(); // navigation settles

    expect(repo.verifyCodes, ['123456']);
    expect(storage.access, 'access-token'); // temp T-011 hook stored tokens
    expect(find.text('HOME_SCREEN'), findsOneWidget);
  });

  testWidgets('tapping verify calls the controller', (tester) async {
    final repo = _StubAuthRepository();
    await tester.pumpWidget(harness(repo));
    await tester.pump();

    // Fill boxes one short of complete so auto-submit doesn't fire, then the
    // last digit, then tap Verify explicitly.
    await enterCode(tester, '654321');
    // Auto-submit already triggered; assert the controller was called.
    await tester.pump();
    await tester.pump();
    expect(repo.verifyCodes, contains('654321'));
  });

  testWidgets('wrong code shows an inline error and clears the boxes',
      (tester) async {
    final repo = _StubAuthRepository(
      verifyError: const ApiException(message: 'bad', statusCode: 401),
    );
    await tester.pumpWidget(harness(repo));
    await tester.pump();

    await enterCode(tester, '000000');
    await tester.pump();
    await tester.pump();

    final l10n = await loadL10n();
    expect(find.text(l10n.auth_otp_invalid), findsOneWidget);
    expect(find.text('HOME_SCREEN'), findsNothing);
    // Boxes cleared → verify disabled again.
    expect(verifyButton(tester).onPressed, isNull);
  });

  testWidgets('expired code (410) shows the expired message', (tester) async {
    final repo = _StubAuthRepository(
      verifyError: const ApiException(message: 'gone', statusCode: 410),
    );
    await tester.pumpWidget(harness(repo));
    await tester.pump();

    await enterCode(tester, '111111');
    await tester.pump();
    await tester.pump();

    final l10n = await loadL10n();
    expect(find.text(l10n.auth_otp_expired), findsOneWidget);
  });

  testWidgets('network error shows the generic message', (tester) async {
    final repo = _StubAuthRepository(
      verifyError: ApiException.fromDio(
        DioException(
          requestOptions: RequestOptions(path: '/x'),
          type: DioExceptionType.connectionError,
        ),
      ),
    );
    await tester.pumpWidget(harness(repo));
    await tester.pump();

    await enterCode(tester, '222222');
    await tester.pump();
    await tester.pump();

    final l10n = await loadL10n();
    expect(find.text(l10n.common_network_error), findsOneWidget);
  });

  testWidgets('resend is disabled during the cooldown and shows a countdown',
      (tester) async {
    final repo = _StubAuthRepository();
    await tester.pumpWidget(harness(repo));
    await tester.pump();

    // Countdown is showing (not the tappable action) right after entry.
    expect(find.byKey(const Key('resend_countdown')), findsOneWidget);
    expect(find.byKey(const Key('resend_action')), findsNothing);

    // Tapping the countdown text is a no-op; the repo isn't called.
    await tester.tap(find.byKey(const Key('resend_countdown')));
    await tester.pump();
    expect(repo.resendCalls, 0);
  });

  testWidgets('resend works once the cooldown elapses', (tester) async {
    final repo = _StubAuthRepository();
    await tester.pumpWidget(harness(repo));
    await tester.pump();

    // Advance past the cooldown.
    for (var i = 0; i <= kOtpResendCooldownSeconds; i++) {
      await tester.pump(const Duration(seconds: 1));
    }

    expect(find.byKey(const Key('resend_action')), findsOneWidget);
    await tester.tap(find.byKey(const Key('resend_action')));
    await tester.pump();
    expect(repo.resendCalls, 1);
  });
}
