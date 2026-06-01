/// Centralised API path constants. Paths only — the host comes from
/// `AppConfig.apiBaseUrl`. One level of nesting max per conventions.
class ApiEndpoints {
  ApiEndpoints._();

  static const String apiPrefix = '/api/v1';

  // Auth (wired in EPIC-01).
  static const String requestOtp = '$apiPrefix/auth/request-otp';
  static const String verifyOtp = '$apiPrefix/auth/verify-otp';
  static const String refresh = '$apiPrefix/auth/refresh';

  // Client bootstrap config + feature flags.
  static const String publicConfig = '$apiPrefix/config/public';

  // Health check (no auth).
  static const String healthz = '/healthz';
}
