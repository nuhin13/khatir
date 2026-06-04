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
    this.voiceTenantEntry = true,
  });

  /// Whether the onboarding slides may be skipped (SystemConfig
  /// `intro_slide_skip_allowed`).
  final bool introSlideSkipAllowed;

  /// Whether the voice tenant-entry method is available (FeatureFlag
  /// `voice_tenant_entry` in the `flags` block). Hides the voice card on the
  /// add-tenant chooser when off. Defaults **on** to match the backend's
  /// task-declared default so an unseeded environment still offers voice.
  final bool voiceTenantEntry;

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
      voiceTenantEntry: _parseFlag(
        root['flags'],
        'voice_tenant_entry',
        defaultValue: true,
      ),
    );
  }

  /// Reads a boolean from the `flags` block (`{ "<key>": true/false }`),
  /// tolerating string-encoded booleans. Returns [defaultValue] when the block
  /// or key is missing so an unconfigured flag keeps its task-declared default.
  static bool _parseFlag(
    Object? flags,
    String key, {
    required bool defaultValue,
  }) {
    if (flags is! Map) return defaultValue;
    return switch (flags[key]) {
      final bool b => b,
      'true' => true,
      'false' => false,
      _ => defaultValue,
    };
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
