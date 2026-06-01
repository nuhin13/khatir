import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khatir_mobile/app.dart';
import 'package:khatir_mobile/core/i18n/bangla_numerals.dart';
import 'package:khatir_mobile/core/i18n/locale_provider.dart';
import 'package:khatir_mobile/core/theme/app_theme.dart';
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

void main() {
  ProviderContainer? container;

  Widget app() => UncontrolledProviderScope(
        container: container!,
        child: const KhatirApp(),
      );

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
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    final ctx = tester.element(find.byType(Scaffold).first);
    expect(Theme.of(ctx).colorScheme.primary, KhatirColors.sage);
    expect(Theme.of(ctx).scaffoldBackgroundColor, KhatirColors.cream);
  });

  testWidgets('defaults to Bangla, toggle switches the rendered string to English',
      (tester) async {
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    // Bangla default.
    expect(find.text('খাতিরে স্বাগতম'), findsOneWidget);
    expect(find.text('Welcome to Khatir'), findsNothing);

    // Tap the locale toggle.
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    // Now English.
    expect(find.text('Welcome to Khatir'), findsOneWidget);
    expect(find.text('খাতিরে স্বাগতম'), findsNothing);
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
