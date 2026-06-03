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

  // Client bootstrap config + feature flags.
  static const String publicConfig = '$apiPrefix/config/public';

  // Health check (no auth).
  static const String healthz = '/healthz';
}
