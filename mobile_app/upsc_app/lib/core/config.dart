class AppConfig {
  static const String apiUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://upsc-2qbz.onrender.com',
  );
  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'production',
  );
}
