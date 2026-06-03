import 'dart:ui';

import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/enums/role.dart';
import '../../../core/i18n/locale_provider.dart';
import '../../../core/network/dio_client.dart';
import 'models/profile.dart';
import 'profile_repository.dart';

/// The shared [ProfileRepository], backed by the app-wide dio client.
final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(ref.watch(dioClientProvider)),
);

/// Loads and mutates the current user's profile, propagating changes app-wide.
///
/// * [build] fetches `GET /profile`.
/// * [updateProfile]/[setLanguage]/[setRole] `PATCH` then mirror the change into
///   the auth state (so the router and role shells react) and, for language,
///   into the [localeProvider] so the app locale updates immediately.
/// * After a role change the auth controller re-fetches `/auth/me` so the cached
///   role matches the DB (the documented source of truth).
class ProfileController extends AsyncNotifier<Profile> {
  @override
  Future<Profile> build() => _repo.getProfile();

  ProfileRepository get _repo => ref.read(profileRepositoryProvider);

  /// Applies a partial update and propagates it. Returns the updated profile.
  Future<Profile> updateProfile({
    String? name,
    Role? role,
    String? language,
  }) async {
    final updated = await _repo.updateProfile(
      name: name,
      role: role,
      language: language,
    );
    state = AsyncValue.data(updated);

    // Mirror into auth state so role/language/name changes propagate app-wide.
    ref.read(authControllerProvider.notifier).applyProfile(
          name: updated.name,
          role: updated.role,
          language: updated.language,
        );

    // Locale change reflects immediately in the running app.
    if (language != null) {
      await ref.read(localeProvider.notifier).setLocale(_localeFor(language));
    }

    // Role is DB-authoritative: re-fetch /auth/me so the cached role (and any
    // re-issued claims) match the server, not a stale token.
    if (role != null) {
      await ref.read(authControllerProvider.notifier).refreshMe();
    }

    return updated;
  }

  /// PATCHes [language], updates the local locale + auth state.
  Future<Profile> setLanguage(String language) =>
      updateProfile(language: language);

  /// PATCHes [role], updates auth state, then re-fetches `/auth/me` so the role
  /// matches the DB.
  Future<Profile> setRole(Role role) => updateProfile(role: role);

  static Locale _localeFor(String code) =>
      code == kLocaleEn.languageCode ? kLocaleEn : kLocaleBn;
}

/// App-wide profile state.
final profileProvider =
    AsyncNotifierProvider<ProfileController, Profile>(ProfileController.new);
