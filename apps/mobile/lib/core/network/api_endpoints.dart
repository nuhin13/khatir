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

  // Tenants (EPIC-04). `tenants/ocr` runs NID OCR on an uploaded image and
  // returns editable fields + an encrypted photo_ref (the tenant is not yet
  // created). Declared before the tenants router on the backend.
  static const String tenantOcr = '$apiPrefix/tenants/ocr';

  // `tenants/voice` transcribes an uploaded Bangla audio clip (ASR, T-006) and
  // returns the same editable fields as OCR, minus `photo_ref` (no artefact).
  static const String tenantVoice = '$apiPrefix/tenants/voice';

  // `tenants` — create a tenant from reviewed fields (POST) + the tenants
  // collection root used to build the single-tenant detail route.
  static const String tenants = '$apiPrefix/tenants';

  /// `/api/v1/tenants/{id}` — single tenant detail/update.
  static String tenant(String id) => '$tenants/$id';

  /// `/api/v1/tenants/{id}/dmpform` — assembled DMP-form preview data for a
  /// tenant (masked NID). Consumed by the DMP preview screen (EPIC-05 T-007).
  static String tenantDmpForm(String tenantId) => '$tenants/$tenantId/dmpform';

  /// `/api/v1/tenants/{id}/dmpform/pdf` — generate the DMP PDF for a tenant
  /// (assemble → render → store → record), returning a signed download URL.
  /// Consumed by the DMP PDF screen (EPIC-05 T-008).
  static String tenantDmpFormPdf(String tenantId) =>
      '$tenants/$tenantId/dmpform/pdf';

  /// `/api/v1/dmpforms/{id}` — retrieve a previously generated DMP record
  /// (owner-scoped), returning the record metadata + a signed download URL.
  static String dmpRecord(String recordId) =>
      '$apiPrefix/dmpforms/$recordId';

  /// `/api/v1/units/{id}/tenants` — tenants holding a lease on a unit.
  static String unitTenants(String unitId) => '$units/$unitId/tenants';

  // Client bootstrap config + feature flags.
  static const String publicConfig = '$apiPrefix/config/public';

  // Health check (no auth).
  static const String healthz = '/healthz';
}
