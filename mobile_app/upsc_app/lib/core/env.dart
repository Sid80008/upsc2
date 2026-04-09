import 'config.dart';

class Env {
  static bool get isProduction => AppConfig.environment == 'production';
  static bool get isDevelopment => !isProduction;
}
