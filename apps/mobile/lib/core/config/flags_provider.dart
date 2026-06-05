import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'public_config_provider.dart';

/// Typed view over the feature-flag dict served by `GET /api/v1/config/public`
/// (EPIC-13 T-002, `{ "flags": { "voice_tenant_entry": true, ... } }`).
///
/// Features ask `isEnabled('<flag_key>')` instead of reading individual config
/// fields, so newly flagged behaviour wires up by passing a key — no provider
/// changes. Because the underlying `/config/public` cache is busted on every
/// admin toggle (T-002) and the client re-reads it, flips propagate within the
/// backend's `<60s` budget.
class Flags {
  const Flags(this._flags);

  /// `key → enabled` map from the `flags` block. Empty when unseeded/missing.
  final Map<String, bool> _flags;

  /// Whether [key] is enabled. Returns [orElse] (default `false`) when the flag
  /// is absent so an unconfigured/never-seeded flag stays off unless a caller
  /// opts into a different default — matching "flags are off until granted".
  bool isEnabled(String key, {bool orElse = false}) => _flags[key] ?? orElse;
}

/// Exposes [Flags] derived from the live [publicConfigProvider]. While the
/// config is loading (or if the fetch failed and fell back to defaults) the
/// flag map reflects whatever [PublicConfig] resolved to — an empty map until
/// real data arrives, so reads return their per-flag default.
final flagsProvider = Provider<Flags>((ref) {
  final config = ref
      .watch(publicConfigProvider)
      .maybeWhen(data: (c) => c, orElse: () => const PublicConfig());
  return Flags(config.flags);
});
