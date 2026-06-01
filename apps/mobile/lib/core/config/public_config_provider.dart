import 'package:dio/dio.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../network/api_endpoints.dart';
import '../network/dio_client.dart';

/// Client bootstrap config served by `GET /api/v1/config/public`.
///
/// Only the fields the app currently consumes are modelled. Defaults are
/// conservative so a missing/failed config never breaks the UI.
class PublicConfig {
  const PublicConfig({this.introSlideSkipAllowed = true});

  /// Whether the onboarding slides may be skipped (SystemConfig
  /// `intro_slide_skip_allowed`).
  final bool introSlideSkipAllowed;

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
    );
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
