import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/i18n/locale_provider.dart';

/// Persists the "user has seen the onboarding slides" flag in secure storage so
/// the intro is shown only on first launch. Splash routing (T-012) reads this.
class OnboardingPrefs {
  OnboardingPrefs(this._storage);

  final FlutterSecureStorage _storage;

  static const _seenKey = 'onboarding_seen';

  /// Storage key for the seen flag, exposed for tests.
  static const String seenKeyForTest = _seenKey;

  Future<bool> hasSeenOnboarding() async =>
      (await _storage.read(key: _seenKey)) == 'true';

  Future<void> markSeen() => _storage.write(key: _seenKey, value: 'true');
}

/// App-wide [OnboardingPrefs]. Reuses [localeStorageProvider]'s secure storage
/// so tests can override a single in-memory fake.
final onboardingPrefsProvider = Provider<OnboardingPrefs>(
  (ref) => OnboardingPrefs(ref.watch(localeStorageProvider)),
);
