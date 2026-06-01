import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khatir_mobile/core/config/public_config_provider.dart';
import 'package:khatir_mobile/core/i18n/locale_provider.dart';
import 'package:khatir_mobile/features/onboarding/data/onboarding_prefs.dart';
import 'package:khatir_mobile/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:khatir_mobile/features/onboarding/presentation/widgets/slide.dart';
import 'package:khatir_mobile/l10n/app_localizations.dart';

/// In-memory secure storage so tests don't touch the platform keychain.
class _FakeSecureStorage extends FlutterSecureStorage {
  _FakeSecureStorage() : super();
  final Map<String, String> store = {};

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
      store[key];

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
      store.remove(key);
    } else {
      store[key] = value;
    }
  }
}

void main() {
  late _FakeSecureStorage storage;
  late GoRouter router;

  Widget harness({bool skipAllowed = true}) {
    router = GoRouter(
      initialLocation: OnboardingScreen.routePath,
      routes: [
        GoRoute(
          path: OnboardingScreen.routePath,
          builder: (context, state) => const OnboardingScreen(),
        ),
        GoRoute(
          path: OnboardingScreen.nextRoutePath,
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('PHONE_ENTRY')),
          ),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        localeStorageProvider.overrideWithValue(storage),
        publicConfigProvider.overrideWith(
          (ref) async => PublicConfig(introSlideSkipAllowed: skipAllowed),
        ),
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

  setUp(() => storage = _FakeSecureStorage());

  testWidgets('renders three onboarding slides via the PageView',
      (tester) async {
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    expect(find.byType(PageView), findsOneWidget);

    final l10n = await AppLocalizations.delegate.load(kLocaleBn);

    // First slide visible.
    expect(find.text(l10n.onboarding_slide1_title), findsOneWidget);

    // Swipe to slide 2.
    await tester.fling(find.byType(PageView), const Offset(-400, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.text(l10n.onboarding_slide2_title), findsOneWidget);

    // Swipe to slide 3 — last slide shows Get-started.
    await tester.fling(find.byType(PageView), const Offset(-400, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.text(l10n.onboarding_slide3_title), findsOneWidget);
    expect(find.text(l10n.onboarding_start), findsOneWidget);
  });

  testWidgets('Skip routes onward to phone entry and marks onboarding seen',
      (tester) async {
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    final l10n = await AppLocalizations.delegate.load(kLocaleBn);
    await tester.tap(find.text(l10n.onboarding_skip));
    await tester.pumpAndSettle();

    expect(find.text('PHONE_ENTRY'), findsOneWidget);
    expect(storage.store[OnboardingPrefs.seenKeyForTest], 'true');
  });

  testWidgets('Skip hidden when config disallows skipping', (tester) async {
    await tester.pumpWidget(harness(skipAllowed: false));
    await tester.pumpAndSettle();

    final l10n = await AppLocalizations.delegate.load(kLocaleBn);
    expect(find.text(l10n.onboarding_skip), findsNothing);
  });

  testWidgets('Get-started on the last slide routes onward', (tester) async {
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    final l10n = await AppLocalizations.delegate.load(kLocaleBn);

    await tester.fling(find.byType(PageView), const Offset(-400, 0), 1000);
    await tester.pumpAndSettle();
    await tester.fling(find.byType(PageView), const Offset(-400, 0), 1000);
    await tester.pumpAndSettle();

    await tester.tap(find.text(l10n.onboarding_start));
    await tester.pumpAndSettle();

    expect(find.text('PHONE_ENTRY'), findsOneWidget);
    expect(find.byType(OnboardingSlide), findsNothing);
  });
}
