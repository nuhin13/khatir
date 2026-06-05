import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../features/properties/data/models/property_enums.dart';
import '../network/api_endpoints.dart';
import '../network/dio_client.dart';

/// Client bootstrap config served by `GET /api/v1/config/public`.
///
/// Only the fields the app currently consumes are modelled. Defaults are
/// conservative so a missing/failed config never breaks the UI.
class PublicConfig {
  const PublicConfig({
    this.introSlideSkipAllowed = true,
    this.areaOptions = Area.values,
    this.flags = const <String, bool>{},
  });

  /// Convenience constructor for tests/call sites that only care about the
  /// `voice_tenant_entry` flag. Builds a [flags] map from the legacy boolean so
  /// existing fixtures keep working after the move to a generic flags dict.
  factory PublicConfig.withVoice({
    bool introSlideSkipAllowed = true,
    List<Area> areaOptions = Area.values,
    bool voiceTenantEntry = true,
  }) {
    return PublicConfig(
      introSlideSkipAllowed: introSlideSkipAllowed,
      areaOptions: areaOptions,
      flags: <String, bool>{'voice_tenant_entry': voiceTenantEntry},
    );
  }

  /// Whether the onboarding slides may be skipped (SystemConfig
  /// `intro_slide_skip_allowed`).
  final bool introSlideSkipAllowed;

  /// All global feature flags served in the `/config/public` `flags` block as a
  /// `key → enabled` map. Read through [FlagsProvider]/[Flags.isEnabled] rather
  /// than poking individual keys here. Empty when unseeded/missing — callers
  /// supply their own per-flag default.
  final Map<String, bool> flags;

  /// Whether the voice tenant-entry method is available (FeatureFlag
  /// `voice_tenant_entry` in the `flags` block). Hides the voice card on the
  /// add-tenant chooser when off. Defaults **on** to match the backend's
  /// task-declared default so an unseeded environment still offers voice.
  ///
  /// Kept as a convenience getter; new features should read the flag through
  /// the generic [Flags] provider instead.
  bool get voiceTenantEntry => flags['voice_tenant_entry'] ?? true;

  /// Selectable Dhaka areas for the property wizard (SystemConfig
  /// `area_options`). Wire values are mapped to [Area]; unknown values are
  /// dropped. Falls back to the full [Area] enum when unseeded/missing so the
  /// wizard always has chips to show.
  final List<Area> areaOptions;

  factory PublicConfig.fromJson(Map<String, dynamic> json) {
    // Tolerate either a flat payload or a `{ "config": { ... } }` envelope.
    final root = json['config'] is Map<String, dynamic>
        ? json['config'] as Map<String, dynamic>
        : json;
    final raw = root['intro_slide_skip_allowed'];
    return PublicConfig(
      introSlideSkipAllowed: switch (raw) {
        final bool b => b,
        'true' => true,
        'false' => false,
        _ => true,
      },
      areaOptions: _parseAreaOptions(root['area_options']),
      flags: _parseFlags(root['flags']),
    );
  }

  /// Parses the `/config/public` `flags` block (`{ "<key>": true/false }`) into
  /// a `key → enabled` map, tolerating string-encoded booleans. Unparseable
  /// values are dropped (the per-flag default then applies at read time). An
  /// absent/invalid block yields an empty map.
  static Map<String, bool> _parseFlags(Object? raw) {
    if (raw is! Map) return const <String, bool>{};
    final parsed = <String, bool>{};
    raw.forEach((key, value) {
      if (key is! String) return;
      switch (value) {
        case final bool b:
          parsed[key] = b;
        case 'true':
          parsed[key] = true;
        case 'false':
          parsed[key] = false;
      }
    });
    return parsed;
  }

  /// Parses the `area_options` wire value (a JSON array of wire strings) into a
  /// list of [Area]. Unknown values are skipped; an empty/invalid result falls
  /// back to the full enum so chips never disappear.
  static List<Area> _parseAreaOptions(Object? raw) {
    if (raw is! List) return Area.values;
    final areas = <Area>[
      for (final value in raw)
        if (value is String)
          if (Area.fromWire(value) case final Area area) area,
    ];
    return areas.isEmpty ? Area.values : areas;
  }
}

/// Fetches [PublicConfig] from the backend. On any failure it falls back to the
/// permissive defaults so onboarding always renders.
final publicConfigProvider = FutureProvider<PublicConfig>((ref) async {
  final dio = ref.watch(dioClientProvider);
  try {
    final res = await dio.get<Map<String, dynamic>>(ApiEndpoints.publicConfig);
    final data = res.data;
    if (data == null) return const PublicConfig();
    return PublicConfig.fromJson(data);
  } on DioException {
    return const PublicConfig();
  }
});
