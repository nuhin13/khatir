import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:khatir_mobile/core/config/flags_provider.dart';
import 'package:khatir_mobile/core/config/public_config_provider.dart';

/// Reads [flagsProvider] from a [ProviderContainer] whose [publicConfigProvider]
/// is overridden with [config].
Flags _flagsFor(PublicConfig config) {
  final container = ProviderContainer(
    overrides: [
      publicConfigProvider.overrideWith((ref) async => config),
    ],
  );
  addTearDown(container.dispose);
  // The synchronous Provider reads the AsyncValue; before the future settles it
  // is in the loading state, so flagsProvider falls back to const PublicConfig()
  // (empty flags). We assert both the resolved and unresolved behaviour below.
  return container.read(flagsProvider);
}

void main() {
  group('Flags.isEnabled', () {
    test('reflects an enabled flag from the config map', () {
      const flags = Flags({'voice_tenant_entry': true});
      expect(flags.isEnabled('voice_tenant_entry'), isTrue);
    });

    test('reflects a disabled flag from the config map', () {
      const flags = Flags({'voice_tenant_entry': false});
      expect(flags.isEnabled('voice_tenant_entry'), isFalse);
    });

    test('returns false by default for an absent flag', () {
      const flags = Flags(<String, bool>{});
      expect(flags.isEnabled('unknown_flag'), isFalse);
    });

    test('honours a caller-supplied orElse default for an absent flag', () {
      const flags = Flags(<String, bool>{});
      expect(flags.isEnabled('voice_tenant_entry', orElse: true), isTrue);
    });

    test('a present flag wins over orElse', () {
      const flags = Flags({'voice_tenant_entry': false});
      expect(flags.isEnabled('voice_tenant_entry', orElse: true), isFalse);
    });
  });

  group('PublicConfig flags parsing', () {
    test('parses a flags block of bools and string-encoded bools', () {
      final config = PublicConfig.fromJson({
        'flags': {
          'voice_tenant_entry': true,
          'dmp_enabled': 'false',
          'ai_lease': 'true',
          'ignored': 42,
        },
      });
      expect(config.flags['voice_tenant_entry'], isTrue);
      expect(config.flags['dmp_enabled'], isFalse);
      expect(config.flags['ai_lease'], isTrue);
      // Unparseable values are dropped so the per-flag default applies.
      expect(config.flags.containsKey('ignored'), isFalse);
    });

    test('an absent flags block yields an empty map', () {
      final config = PublicConfig.fromJson({'intro_slide_skip_allowed': true});
      expect(config.flags, isEmpty);
    });

    test('voiceTenantEntry getter defaults on when unseeded', () {
      const config = PublicConfig();
      expect(config.voiceTenantEntry, isTrue);
    });

    test('voiceTenantEntry getter reflects the flags map', () {
      final config = PublicConfig.fromJson({
        'flags': {'voice_tenant_entry': false},
      });
      expect(config.voiceTenantEntry, isFalse);
    });
  });

  group('flagsProvider', () {
    test('exposes flags once the config resolves', () async {
      final container = ProviderContainer(
        overrides: [
          publicConfigProvider.overrideWith(
            (ref) async =>
                PublicConfig.fromJson({'flags': {'voice_tenant_entry': false}}),
          ),
        ],
      );
      addTearDown(container.dispose);

      // Drive the FutureProvider to completion.
      await container.read(publicConfigProvider.future);

      final flags = container.read(flagsProvider);
      expect(flags.isEnabled('voice_tenant_entry', orElse: true), isFalse);
    });

    test('falls back to empty flags while the config is loading', () {
      // Synchronous read before the future settles → empty flag map → orElse
      // default applies.
      final flags = _flagsFor(
        PublicConfig.fromJson({'flags': {'voice_tenant_entry': false}}),
      );
      expect(flags.isEnabled('voice_tenant_entry', orElse: true), isTrue);
    });
  });
}
