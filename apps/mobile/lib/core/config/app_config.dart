/// Runtime configuration sourced from `--dart-define`. No secrets are baked
/// into the binary — only the API base URL and the environment name.
class AppConfig {
  AppConfig._();

  /// Backend base URL, e.g. `http://localhost:8000`.
  /// Provided via `--dart-define=API_BASE_URL=...`.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );

  /// Environment name: `dev` | `staging` | `prod`.
  /// Provided via `--dart-define=APP_ENV=...`.
  static const String appEnv = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'dev',
  );
}
