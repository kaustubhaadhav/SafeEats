/// Application configuration management for SafeEats.
/// 
/// This module provides environment-aware configuration that can be customized
/// at compile-time using Dart defines or at runtime through the config service.
/// 
/// ## Usage
/// 
/// ### Compile-time configuration:
/// ```bash
/// flutter run --dart-define=BACKEND_URL=https://api.safeeats.com
/// flutter run --dart-define=ENVIRONMENT=production
/// flutter run --dart-define=API_KEY=your-api-key
/// ```
/// 
/// ### Runtime access:
/// ```dart
/// final config = AppConfig.instance;
/// print(config.backendUrl);
/// print(config.environment);
/// ```
library;

/// Supported application environments.
/// 
/// Each environment has different default configurations for API endpoints,
/// logging levels, and feature flags.
enum Environment {
  /// Development environment with debug logging and local backend.
  development,
  
  /// Staging environment for pre-production testing.
  staging,
  
  /// Production environment with optimized settings.
  production,
}

/// Extension methods for [Environment] enum.
extension EnvironmentExtension on Environment {
  /// Returns the string representation used in compile-time defines.
  String get value {
    switch (this) {
      case Environment.development:
        return 'development';
      case Environment.staging:
        return 'staging';
      case Environment.production:
        return 'production';
    }
  }

  /// Parses a string to [Environment], defaulting to [Environment.development].
  static Environment fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'production':
      case 'prod':
        return Environment.production;
      case 'staging':
      case 'stage':
        return Environment.staging;
      default:
        return Environment.development;
    }
  }
}

/// Central configuration class for the SafeEats application.
/// 
/// This class manages all environment-specific settings including:
/// - API endpoints and authentication
/// - Feature flags
/// - Timeout and retry configurations
/// - Logging settings
/// 
/// Configuration values are read from compile-time defines with sensible defaults.
/// 
/// ## Example
/// ```dart
/// final config = AppConfig.instance;
/// 
/// // Access API configuration
/// final dio = Dio(BaseOptions(
///   baseUrl: config.backendUrl,
///   connectTimeout: config.connectionTimeout,
/// ));
/// 
/// // Check environment
/// if (config.isDevelopment) {
///   print('Running in development mode');
/// }
/// ```
class AppConfig {
  /// Singleton instance of the application configuration.
  static final AppConfig instance = AppConfig._internal();

  AppConfig._internal();

  // ==========================================================================
  // Environment Configuration
  // ==========================================================================

  /// The current application environment.
  /// 
  /// Set via `--dart-define=ENVIRONMENT=production` at compile time.
  /// Defaults to [Environment.development].
  Environment get environment => EnvironmentExtension.fromString(
    const String.fromEnvironment('ENVIRONMENT', defaultValue: 'development'),
  );

  /// Whether the app is running in development mode.
  bool get isDevelopment => environment == Environment.development;

  /// Whether the app is running in staging mode.
  bool get isStaging => environment == Environment.staging;

  /// Whether the app is running in production mode.
  bool get isProduction => environment == Environment.production;

  // ==========================================================================
  // API Configuration
  // ==========================================================================

  /// The SafeEats backend API base URL.
  /// 
  /// Set via `--dart-define=BACKEND_URL=https://api.safeeats.com` at compile time.
  /// 
  /// Default values by environment:
  /// - Development: `http://localhost:8000`
  /// - Staging: `https://staging-api.safeeats.com`
  /// - Production: `https://api.safeeats.com`
  String get backendUrl {
    const defined = String.fromEnvironment('BACKEND_URL');
    if (defined.isNotEmpty) return defined;
    
    switch (environment) {
      case Environment.development:
        return 'http://localhost:8000';
      case Environment.staging:
        return 'https://staging-api.safeeats.com';
      case Environment.production:
        return 'https://api.safeeats.com';
    }
  }

  /// The Open Food Facts API base URL.
  /// 
  /// Used as a fallback when the backend is unavailable.
  String get openFoodFactsUrl => const String.fromEnvironment(
    'OPEN_FOOD_FACTS_URL',
    defaultValue: 'https://world.openfoodfacts.org/api/v2',
  );

  /// API key for authenticating with the SafeEats backend.
  /// 
  /// Set via `--dart-define=API_KEY=your-api-key` at compile time.
  /// Leave empty to disable API key authentication.
  String get apiKey => const String.fromEnvironment('API_KEY');

  /// Whether API key authentication is enabled.
  bool get hasApiKey => apiKey.isNotEmpty;

  // ==========================================================================
  // Network Configuration
  // ==========================================================================

  /// Connection timeout for API requests.
  /// 
  /// Defaults to 15 seconds for production, 30 seconds for development.
  Duration get connectionTimeout => Duration(
    seconds: isProduction ? 15 : 30,
  );

  /// Receive timeout for API requests.
  /// 
  /// Defaults to 15 seconds for production, 30 seconds for development.
  Duration get receiveTimeout => Duration(
    seconds: isProduction ? 15 : 30,
  );

  /// Maximum number of retry attempts for failed network requests.
  int get maxRetries => isProduction ? 3 : 2;

  /// Initial delay between retry attempts.
  Duration get retryInitialDelay => const Duration(milliseconds: 500);

  /// Backoff multiplier for exponential retry delays.
  double get retryBackoffMultiplier => 2.0;

  /// Maximum delay between retry attempts.
  Duration get retryMaxDelay => const Duration(seconds: 10);

  // ==========================================================================
  // Feature Flags
  // ==========================================================================

  /// Whether to enable verbose logging for debugging.
  bool get enableDebugLogging => const bool.fromEnvironment(
    'DEBUG_LOGGING',
    defaultValue: false,
  ) || isDevelopment;

  /// Whether to enable offline mode with local caching.
  bool get enableOfflineMode => const bool.fromEnvironment(
    'ENABLE_OFFLINE_MODE',
    defaultValue: true,
  );

  /// Whether to enable analytics collection.
  bool get enableAnalytics => const bool.fromEnvironment(
    'ENABLE_ANALYTICS',
    defaultValue: false,
  ) && isProduction;

  /// Whether to show experimental features.
  bool get enableExperimentalFeatures => const bool.fromEnvironment(
    'ENABLE_EXPERIMENTAL',
    defaultValue: false,
  ) && !isProduction;

  // ==========================================================================
  // Cache Configuration
  // ==========================================================================

  /// Duration to keep product data in cache before refresh.
  Duration get productCacheDuration => const Duration(hours: 24);

  /// Duration to keep scan history entries.
  Duration get historyCacheDuration => const Duration(days: 30);

  /// Maximum number of items to keep in scan history.
  int get maxHistoryItems => 100;

  // ==========================================================================
  // App Information
  // ==========================================================================

  /// Application version string.
  String get appVersion => '1.0.0';

  /// User agent string for API requests.
  String get userAgent => 'SafeEats - Food Carcinogen Scanner - Version $appVersion';

  /// Returns a summary of the current configuration for debugging.
  @override
  String toString() {
    return '''
AppConfig:
  Environment: ${environment.value}
  Backend URL: $backendUrl
  Open Food Facts URL: $openFoodFactsUrl
  Has API Key: $hasApiKey
  Connection Timeout: ${connectionTimeout.inSeconds}s
  Max Retries: $maxRetries
  Debug Logging: $enableDebugLogging
  Offline Mode: $enableOfflineMode
  Analytics: $enableAnalytics
''';
  }
}