import 'dart:ui';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Locales the app supports. Bangla is the default; English is the toggle.
const Locale kLocaleBn = Locale('bn');
const Locale kLocaleEn = Locale('en');
const List<Locale> kSupportedLocales = [kLocaleBn, kLocaleEn];

/// Provides the [FlutterSecureStorage] used to persist the locale choice.
/// Overridable in tests with an in-memory fake.
final localeStorageProvider = Provider<FlutterSecureStorage>(
  (ref) => const FlutterSecureStorage(),
);

/// Holds the active [Locale], persisting the choice to secure storage so it
/// survives restarts. Defaults to Bangla until a stored choice is loaded.
class LocaleController extends StateNotifier<Locale> {
  LocaleController(this._storage) : super(kLocaleBn) {
    _load();
  }

  final FlutterSecureStorage _storage;
  static const _key = 'app_locale';

  Future<void> _load() async {
    final code = await _storage.read(key: _key);
    if (code == kLocaleEn.languageCode) {
      state = kLocaleEn;
    } else if (code == kLocaleBn.languageCode) {
      state = kLocaleBn;
    }
  }

  /// Sets the active locale and persists it.
  Future<void> setLocale(Locale locale) async {
    if (!kSupportedLocales.contains(locale)) return;
    state = locale;
    await _storage.write(key: _key, value: locale.languageCode);
  }

  /// Toggles between Bangla and English.
  Future<void> toggle() {
    final next = state.languageCode == kLocaleBn.languageCode
        ? kLocaleEn
        : kLocaleBn;
    return setLocale(next);
  }
}

/// Runtime locale state for the whole app.
final localeProvider = StateNotifierProvider<LocaleController, Locale>(
  (ref) => LocaleController(ref.watch(localeStorageProvider)),
);
