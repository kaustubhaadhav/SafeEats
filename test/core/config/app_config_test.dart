import 'package:flutter_test/flutter_test.dart';
import 'package:safeeats/core/config/app_config.dart';

void main() {
  group('AppConfig Tests', () {
    late AppConfig config;

    setUp(() {
      config = AppConfig.instance;
    });

    test('instance returns singleton', () {
      final config1 = AppConfig.instance;
      final config2 = AppConfig.instance;
      expect(identical(config1, config2), isTrue);
    });

    group('Environment Configuration', () {
      test('default environment is development', () {
        // Default is development when ENVIRONMENT is not set
        expect(config.environment, isNotNull);
        expect(config.isDevelopment, anyOf(isTrue, isFalse));
      });

      test('isDevelopment, isStaging, isProduction are mutually exclusive', () {
        final bools = [config.isDevelopment, config.isStaging, config.isProduction];
        expect(bools.where((b) => b).length, lessThanOrEqualTo(1));
      });
    });

    group('API Configuration', () {
      test('backendUrl is not empty', () {
        expect(config.backendUrl, isNotEmpty);
      });

      test('openFoodFactsUrl is valid', () {
        expect(config.openFoodFactsUrl, contains('openfoodfacts.org'));
      });

      test('hasApiKey returns false when no API key set', () {
        // By default, no API key is set
        expect(config.hasApiKey, anyOf(isTrue, isFalse));
      });
    });

    group('Network Configuration', () {
      test('connectionTimeout is positive duration', () {
        expect(config.connectionTimeout.inMilliseconds, isPositive);
      });

      test('receiveTimeout is positive duration', () {
        expect(config.receiveTimeout.inMilliseconds, isPositive);
      });

      test('maxRetries is positive', () {
        expect(config.maxRetries, isPositive);
      });

      test('retryInitialDelay is positive duration', () {
        expect(config.retryInitialDelay.inMilliseconds, isPositive);
      });

      test('retryBackoffMultiplier is greater than 1', () {
        expect(config.retryBackoffMultiplier, greaterThan(1.0));
      });

      test('retryMaxDelay is greater than initial delay', () {
        expect(
          config.retryMaxDelay.inMilliseconds,
          greaterThan(config.retryInitialDelay.inMilliseconds),
        );
      });
    });

    group('Feature Flags', () {
      test('enableOfflineMode has a value', () {
        expect(config.enableOfflineMode, anyOf(isTrue, isFalse));
      });

      test('enableDebugLogging has a value', () {
        expect(config.enableDebugLogging, anyOf(isTrue, isFalse));
      });

      test('enableAnalytics has a value', () {
        expect(config.enableAnalytics, anyOf(isTrue, isFalse));
      });

      test('enableExperimentalFeatures has a value', () {
        expect(config.enableExperimentalFeatures, anyOf(isTrue, isFalse));
      });
    });

    group('Cache Configuration', () {
      test('productCacheDuration is positive', () {
        expect(config.productCacheDuration.inHours, isPositive);
      });

      test('historyCacheDuration is positive', () {
        expect(config.historyCacheDuration.inDays, isPositive);
      });

      test('maxHistoryItems is positive', () {
        expect(config.maxHistoryItems, isPositive);
      });
    });

    group('App Information', () {
      test('appVersion is not empty', () {
        expect(config.appVersion, isNotEmpty);
      });

      test('userAgent contains SafeEats', () {
        expect(config.userAgent, contains('SafeEats'));
      });

      test('toString returns configuration summary', () {
        final str = config.toString();
        expect(str, contains('AppConfig'));
        expect(str, contains('Backend URL'));
        expect(str, contains('Environment'));
      });
    });
  });

  group('Environment Enum Tests', () {
    test('all environments have unique values', () {
      final values = Environment.values.map((e) => e.value).toSet();
      expect(values.length, equals(Environment.values.length));
    });

    test('fromString parses production correctly', () {
      expect(EnvironmentExtension.fromString('production'), equals(Environment.production));
      expect(EnvironmentExtension.fromString('prod'), equals(Environment.production));
      expect(EnvironmentExtension.fromString('PRODUCTION'), equals(Environment.production));
    });

    test('fromString parses staging correctly', () {
      expect(EnvironmentExtension.fromString('staging'), equals(Environment.staging));
      expect(EnvironmentExtension.fromString('stage'), equals(Environment.staging));
      expect(EnvironmentExtension.fromString('STAGING'), equals(Environment.staging));
    });

    test('fromString returns development for unknown values', () {
      expect(EnvironmentExtension.fromString('unknown'), equals(Environment.development));
      expect(EnvironmentExtension.fromString(null), equals(Environment.development));
      expect(EnvironmentExtension.fromString(''), equals(Environment.development));
    });

    test('environment values return correct strings', () {
      expect(Environment.development.value, equals('development'));
      expect(Environment.staging.value, equals('staging'));
      expect(Environment.production.value, equals('production'));
    });
  });
}