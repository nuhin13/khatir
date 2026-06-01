import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khatir_mobile/core/i18n/locale_provider.dart';
import 'package:khatir_mobile/core/network/api_exception.dart';
import 'package:khatir_mobile/features/auth/data/auth_providers.dart';
import 'package:khatir_mobile/features/auth/data/auth_repository.dart';
import 'package:khatir_mobile/features/auth/data/models/request_otp_response.dart';
import 'package:khatir_mobile/features/auth/presentation/screens/phone_entry_screen.dart';
import 'package:khatir_mobile/l10n/app_localizations.dart';

/// Stub repository: records the phone it was asked for and replays a scripted
/// result so we never hit the network.
class _StubAuthRepository implements AuthRepository {
  _StubAuthRepository({this.throwError});

  final ApiException? throwError;
  final List<String> calls = [];

  @override
  Future<RequestOtpResponse> requestOtp(String phone) async {
    calls.add(phone);
    if (throwError != null) throw throwError!;
    return const RequestOtpResponse();
  }
}

void main() {
  Future<AppLocalizations> loadL10n() => AppLocalizations.delegate.load(kLocaleBn);

  Widget harness(_StubAuthRepository repo) {
    final router = GoRouter(
      initialLocation: PhoneEntryScreen.routePath,
      routes: [
        GoRoute(
          path: PhoneEntryScreen.routePath,
          builder: (context, state) => const PhoneEntryScreen(),
        ),
        GoRoute(
          path: PhoneEntryScreen.otpRoutePath,
          builder: (context, state) =>
              const Scaffold(body: Center(child: Text('OTP_SCREEN'))),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(repo),
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

  ElevatedButton submitButton(WidgetTester tester) =>
      tester.widget<ElevatedButton>(find.byType(ElevatedButton));

  testWidgets('submit is disabled until a valid BD phone is entered',
      (tester) async {
    final repo = _StubAuthRepository();
    await tester.pumpWidget(harness(repo));
    await tester.pumpAndSettle();

    // Initially empty → disabled.
    expect(submitButton(tester).onPressed, isNull);

    // Too short → still disabled.
    await tester.enterText(find.byKey(const Key('phone_field')), '01711');
    await tester.pump();
    expect(submitButton(tester).onPressed, isNull);

    // Valid 11-digit number → enabled.
    await tester.enterText(
        find.byKey(const Key('phone_field')), '01711000111');
    await tester.pump();
    expect(submitButton(tester).onPressed, isNotNull);
  });

  testWidgets('invalid prefix keeps submit disabled and shows inline error',
      (tester) async {
    final repo = _StubAuthRepository();
    await tester.pumpWidget(harness(repo));
    await tester.pumpAndSettle();

    // 11 digits but invalid operator prefix (01[3-9]) → 0121... is invalid.
    await tester.enterText(
        find.byKey(const Key('phone_field')), '01211000111');
    await tester.pump();
    expect(submitButton(tester).onPressed, isNull);

    final l10n = await loadL10n();
    expect(find.text(l10n.auth_phone_invalid), findsOneWidget);
  });

  testWidgets('valid phone calls the controller and navigates to OTP, '
      'normalising to E.164', (tester) async {
    final repo = _StubAuthRepository();
    await tester.pumpWidget(harness(repo));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const Key('phone_field')), '01711000111');
    await tester.pump();
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    expect(repo.calls, ['+8801711000111']);
    expect(find.text('OTP_SCREEN'), findsOneWidget);
  });

  testWidgets('rate-limited (429) shows the friendly message and stays put',
      (tester) async {
    final repo = _StubAuthRepository(
      throwError: const ApiException(message: 'rate', statusCode: 429),
    );
    await tester.pumpWidget(harness(repo));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const Key('phone_field')), '01711000111');
    await tester.pump();
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    final l10n = await loadL10n();
    expect(find.text(l10n.auth_rate_limited), findsOneWidget);
    expect(find.text('OTP_SCREEN'), findsNothing);
  });

  testWidgets('network error shows the generic message', (tester) async {
    final repo = _StubAuthRepository(
      throwError: ApiException.fromDio(
        DioException(
          requestOptions: RequestOptions(path: '/x'),
          type: DioExceptionType.connectionError,
        ),
      ),
    );
    await tester.pumpWidget(harness(repo));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byKey(const Key('phone_field')), '01711000111');
    await tester.pump();
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    final l10n = await loadL10n();
    expect(find.text(l10n.common_network_error), findsOneWidget);
  });
}
