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

  /// `/api/v1/tenants/{id}/verify` — trigger NID EC verification for a tenant.
  /// Returns only verification_status + provider_ref (no raw EC payload).
  static String tenantVerify(String tenantId) => '$tenants/$tenantId/verify';

  /// `/api/v1/units/{id}/tenants` — tenants holding a lease on a unit.
  static String unitTenants(String unitId) => '$units/$unitId/tenants';

  /// `/api/v1/units/{id}/lease` — the unit's current (active) lease plus an
  /// embedded tenant summary (EPIC-06 T-004). 404 when the unit has no active
  /// lease.
  static String unitLease(String unitId) => '$units/$unitId/lease';

  // Leases (EPIC-06): top-level resource at `/api/v1/leases` (no trailing
  // slash). Lifecycle transitions + the rent schedule are `@action` subpaths
  // on a single lease.
  static const String leases = '$apiPrefix/leases';

  /// `/api/v1/leases/{id}` — single-lease detail / partial update.
  static String lease(String id) => '$leases/$id';

  /// `/api/v1/leases/{id}/schedule` — the lease's rent schedule (read-only).
  static String leaseSchedule(String id) => '${lease(id)}/schedule';

  /// `/api/v1/leases/{id}/activate` — activate a draft lease (generates its
  /// rent schedule).
  static String leaseActivate(String id) => '${lease(id)}/activate';

  /// `/api/v1/leases/{id}/terminate` — end/terminate an active lease.
  static String leaseTerminate(String id) => '${lease(id)}/terminate';

  /// `/api/v1/leases/{id}/document` — generate (POST) or retrieve (GET) the
  /// lease document, and update its clauses (PATCH).
  static String leaseDocument(String leaseId) => '${lease(leaseId)}/document';

  /// `/api/v1/leases/{id}/document/pdf` — render and return the lease PDF
  /// (POST returns `{pdf_url: '...'}` with a signed download URL).
  static String leaseDocumentPdf(String leaseId) =>
      '${lease(leaseId)}/document/pdf';

  // Rent collection (EPIC-07): top-level resource at `/api/v1/rent-requests`
  // (no trailing slash). Create + queue list/detail; lifecycle transitions
  // (send / verify / reject / mark-received) are `@action` subpaths on a single
  // request.
  static const String rentRequests = '$apiPrefix/rent-requests';

  /// `/api/v1/rent-requests/{id}` — single rent-request detail.
  static String rentRequest(String id) => '$rentRequests/$id';

  /// `/api/v1/rent-requests/{id}/send` — (re)deliver the rent link to the tenant.
  static String rentRequestSend(String id) => '${rentRequest(id)}/send';

  /// `/api/v1/rent-requests/{id}/verify` — verify the submitted proof (creates a
  /// Payment + receipt, settles the schedule).
  static String rentRequestVerify(String id) => '${rentRequest(id)}/verify';

  /// `/api/v1/rent-requests/{id}/reject` — reject the request with a reason.
  static String rentRequestReject(String id) => '${rentRequest(id)}/reject';

  /// `/api/v1/rent-requests/{id}/mark-received` — record an off-platform (cash)
  /// payment with no proof and settle.
  static String rentRequestMarkReceived(String id) =>
      '${rentRequest(id)}/mark-received';

  // Maintenance + expenses (EPIC-08): top-level resources at
  // `/api/v1/maintenance` and `/api/v1/expenses` (no trailing slash). Maintenance
  // CRUD + the resolve `@action` (auto-creates an expense). Expenses are CRUD +
  // a CSV `export` action + a `summary` aggregation for the dashboard.
  static const String maintenance = '$apiPrefix/maintenance';

  /// `/api/v1/maintenance/{id}` — single maintenance-request detail / update.
  static String maintenanceRequest(String id) => '$maintenance/$id';

  /// `/api/v1/maintenance/{id}/resolve` — resolve a request (records the cost
  /// and auto-creates one expense).
  static String maintenanceResolve(String id) =>
      '${maintenanceRequest(id)}/resolve';

  static const String expenses = '$apiPrefix/expenses';

  /// `/api/v1/expenses/{id}` — single expense detail / update / delete.
  static String expense(String id) => '$expenses/$id';

  /// `/api/v1/expenses/export` — stream the (scoped + filtered) expenses as CSV.
  static const String expensesExport = '$expenses/export';

  /// `/api/v1/expenses/summary` — expense totals by category + by month.
  static const String expensesSummary = '$expenses/summary';

  // Dashboard (EPIC-09): one read endpoint returning every landlord metric in
  // a single call. `?months=N` overrides the configured default window.
  static const String dashboard = '$apiPrefix/dashboard';

  // Client bootstrap config + feature flags.
  static const String publicConfig = '$apiPrefix/config/public';

  // Billing (EPIC-10): subscribe/upgrade to a tier (payment stubbed). The
  // current plan + usage is read from `/config/public` (see [publicConfig]),
  // not a separate fetch.
  static const String billingSubscribe = '$apiPrefix/billing/subscribe';

  // Health check (no auth).
  static const String healthz = '/healthz';
}
