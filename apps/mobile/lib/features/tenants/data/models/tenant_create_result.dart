import 'tenant.dart';

/// The landlord's free-tier usage snapshot, mirroring the optional usage fields
/// the backend may echo on a successful tenant create (T-008:
/// `{tenants_used, free_limit, is_over_free}`). All fields are optional — older
/// servers (or the create response before EPIC-10 wires hard enforcement) omit
/// them, in which case [TenantCreateResult.usage] is `null` and the UI simply
/// shows no free-tier toast.
class TenantUsage {
  const TenantUsage({
    required this.tenantsUsed,
    required this.freeLimit,
    required this.isOverFree,
  });

  /// Number of tenants the landlord has created so far (post-create count).
  final int tenantsUsed;

  /// The free-tier ceiling from `free_tier_tenant_limit` SystemConfig.
  final int freeLimit;

  /// Whether the landlord is over their free allowance (soft signal — hard
  /// enforcement lands in EPIC-10).
  final bool isOverFree;

  /// Parses the usage triplet from a create-response body, or returns `null`
  /// when the server did not echo the usage fields (so the caller skips the
  /// toast rather than rendering a misleading `0/0`).
  static TenantUsage? maybeFromJson(Map<String, dynamic> json) {
    final used = _toInt(json['tenants_used']);
    final limit = _toInt(json['free_limit']);
    if (used == null || limit == null) return null;
    return TenantUsage(
      tenantsUsed: used,
      freeLimit: limit,
      isOverFree: json['is_over_free'] as bool? ?? (used > limit),
    );
  }

  static int? _toInt(Object? value) => switch (value) {
        final int v => v,
        final num v => v.toInt(),
        final String v => int.tryParse(v),
        _ => null,
      };
}

/// The outcome of a tenant create: the persisted (masked) [tenant] the flow
/// routes on, plus the optional free-tier [usage] the UI surfaces as a toast.
class TenantCreateResult {
  const TenantCreateResult({required this.tenant, this.usage});

  final Tenant tenant;
  final TenantUsage? usage;
}
