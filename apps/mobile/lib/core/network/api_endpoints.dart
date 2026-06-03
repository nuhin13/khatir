/// Centralised API path constants. Paths only — the host comes from
/// `AppConfig.apiBaseUrl`. One level of nesting max per conventions.
class ApiEndpoints {
  ApiEndpoints._();

  static const String apiPrefix = '/api/v1';

  // Auth (wired in EPIC-01).
  static const String requestOtp = '$apiPrefix/auth/request-otp';
  static const String verifyOtp = '$apiPrefix/auth/verify-otp';
  static const String refresh = '$apiPrefix/auth/refresh';
  static const String logout = '$apiPrefix/auth/logout';
  static const String me = '$apiPrefix/auth/me';

  // Profile (T-001): read + partial update of the caller's own profile.
  static const String profile = '$apiPrefix/profile';

  // Properties (EPIC-03): buildings CRUD, nested units, single-unit, portfolio.
  static const String buildings = '$apiPrefix/buildings';

  /// `/api/v1/buildings/{id}`.
  static String building(String id) => '$buildings/$id';

  /// `/api/v1/buildings/{id}/units` — list/create units under a building.
  static String buildingUnits(String buildingId) =>
      '$buildings/$buildingId/units';

  /// `/api/v1/buildings/{id}/units/generate` — bulk-generate units.
  static String buildingUnitsGenerate(String buildingId) =>
      '$buildings/$buildingId/units/generate';

  static const String units = '$apiPrefix/units';

  /// `/api/v1/units/{id}` — single-unit detail/update/delete.
  static String unit(String id) => '$units/$id';

  /// `/api/v1/portfolio` — landlord/manager portfolio summary.
  static const String portfolio = '$apiPrefix/portfolio';

  // Client bootstrap config + feature flags.
  static const String publicConfig = '$apiPrefix/config/public';

  // Health check (no auth).
  static const String healthz = '/healthz';
}
