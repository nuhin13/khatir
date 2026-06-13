/// Plan & billing read models (EPIC-10 T-007).
///
/// The plan screen never fetches tier prices on its own: every value comes from
/// the `GET /config/public` envelope (T-005), which carries the active pricing
/// tiers (`pricing.tiers`) and — for an authenticated caller — a flat
/// `subscription` block (current plan key, status, tenant usage vs. limit, and
/// whether the tier permits NID verification). These models map only the fields
/// the screen renders; unknown/missing fields degrade gracefully so a partial
/// payload never crashes the UI.
library;

/// A single pricing tier from `pricing.tiers[]` (the read-only `TierSerializer`
/// shape). Prices arrive as DRF `DecimalField` strings, so they are parsed
/// leniently into doubles. A null [tenantMax] means an unlimited tier.
class PlanTier {
  const PlanTier({
    required this.key,
    required this.label,
    required this.labelBn,
    this.tenantMin,
    this.tenantMax,
    this.monthlyPrice,
    this.annualPrice,
    this.includesVerification = false,
    this.includedCredits = 0,
  });

  /// Stable tier identifier (e.g. `free`, `per_tenant`, `bundle_20`). Sent as
  /// `tier_key` when subscribing.
  final String key;

  /// English plan label.
  final String label;

  /// Bangla plan label.
  final String labelBn;

  /// Lower bound of the tenant band this tier covers (inclusive), if any.
  final int? tenantMin;

  /// Upper bound of the tenant band (inclusive); null means unlimited.
  final int? tenantMax;

  /// Monthly price in BDT; null/0 reads as free.
  final double? monthlyPrice;

  /// Annual price in BDT; null when the tier is monthly-only.
  final double? annualPrice;

  /// Whether the tier bundles NID verification.
  final bool includesVerification;

  /// Verification credits bundled with the tier.
  final int includedCredits;

  /// True when the tier costs nothing (the free tier).
  bool get isFree => (monthlyPrice ?? 0) <= 0 && (annualPrice ?? 0) <= 0;

  /// True when the tier serves an unbounded number of tenants.
  bool get isUnlimited => tenantMax == null;

  factory PlanTier.fromJson(Map<String, dynamic> json) {
    return PlanTier(
      key: (json['key'] as String?) ?? '',
      label: (json['label'] as String?) ?? '',
      labelBn: (json['label_bn'] as String?) ?? (json['label'] as String?) ?? '',
      tenantMin: _asInt(json['tenant_min']),
      tenantMax: _asInt(json['tenant_max']),
      monthlyPrice: _asDouble(json['monthly_price']),
      annualPrice: _asDouble(json['annual_price']),
      includesVerification: (json['includes_verification'] as bool?) ?? false,
      includedCredits: _asInt(json['included_credits']) ?? 0,
    );
  }
}

/// The authenticated caller's `subscription` block from `/config/public`
/// (T-005 §2): current plan key + status, tenant usage against the effective
/// limit, and whether the active tier permits NID verification. A null
/// [tenantLimit] means the current plan is unlimited.
class PlanSubscription {
  const PlanSubscription({
    required this.tierKey,
    required this.status,
    this.tenantsUsed = 0,
    this.tenantLimit,
    this.canVerifyNid = false,
  });

  /// Key of the caller's current tier (`free` when none is active).
  final String tierKey;

  /// Subscription status (`active`, `past_due`, `cancelled`, …).
  final String status;

  /// Tenants the caller currently has.
  final int tenantsUsed;

  /// Effective tenant limit; null means unlimited.
  final int? tenantLimit;

  /// Whether the current tier permits NID verification.
  final bool canVerifyNid;

  /// True when the caller has no headroom left under a finite limit.
  bool get atLimit => tenantLimit != null && tenantsUsed >= tenantLimit!;

  factory PlanSubscription.fromJson(Map<String, dynamic> json) {
    return PlanSubscription(
      tierKey: (json['tier_key'] as String?) ?? 'free',
      status: (json['status'] as String?) ?? 'active',
      tenantsUsed: _asInt(json['tenants_used']) ?? 0,
      tenantLimit: _asInt(json['tenant_limit']),
      canVerifyNid: (json['can_verify_nid'] as bool?) ?? false,
    );
  }
}

/// The slice of `/config/public` the plan screen consumes: the active tier
/// catalogue and (when authenticated) the current subscription.
class PlanConfig {
  const PlanConfig({this.tiers = const [], this.subscription});

  /// Active tiers in plan-picker order (server-sorted by `sort_order`).
  final List<PlanTier> tiers;

  /// The caller's current subscription, or null for an unauthenticated /
  /// missing block.
  final PlanSubscription? subscription;

  factory PlanConfig.fromJson(Map<String, dynamic> json) {
    final pricing = json['pricing'];
    final rawTiers = pricing is Map<String, dynamic> ? pricing['tiers'] : null;
    final tiers = <PlanTier>[
      if (rawTiers is List)
        for (final t in rawTiers)
          if (t is Map<String, dynamic>) PlanTier.fromJson(t),
    ];
    final sub = json['subscription'];
    return PlanConfig(
      tiers: tiers,
      subscription:
          sub is Map<String, dynamic> ? PlanSubscription.fromJson(sub) : null,
    );
  }
}

/// Parses a wire value into an int, tolerating int / num / numeric-string.
int? _asInt(Object? value) => switch (value) {
      final int v => v,
      final num v => v.toInt(),
      final String v => int.tryParse(v),
      _ => null,
    };

/// Parses a wire value into a double, tolerating num / DRF decimal-string.
double? _asDouble(Object? value) => switch (value) {
      final num v => v.toDouble(),
      final String v => double.tryParse(v),
      _ => null,
    };
