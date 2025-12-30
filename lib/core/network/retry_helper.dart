import 'dart:async';
import 'dart:math';

/// Configuration for retry behavior
class RetryConfig {
  final int maxRetries;
  final Duration initialDelay;
  final double backoffMultiplier;
  final Duration maxDelay;
  final bool Function(Exception)? shouldRetry;

  const RetryConfig({
    this.maxRetries = 3,
    this.initialDelay = const Duration(milliseconds: 500),
    this.backoffMultiplier = 2.0,
    this.maxDelay = const Duration(seconds: 30),
    this.shouldRetry,
  });

  static const RetryConfig defaultConfig = RetryConfig();
}

/// Helper class for implementing retry logic with exponential backoff
class RetryHelper {
  /// Executes a function with retry logic using exponential backoff
  /// 
  /// [operation] - The async function to execute
  /// [config] - Configuration for retry behavior
  /// 
  /// Returns the result of the operation if successful
  /// Throws the last exception if all retries are exhausted
  static Future<T> withRetry<T>({
    required Future<T> Function() operation,
    RetryConfig config = RetryConfig.defaultConfig,
    void Function(int attempt, Exception error, Duration nextDelay)? onRetry,
  }) async {
    int attempt = 0;
    Exception? lastException;

    while (attempt <= config.maxRetries) {
      try {
        return await operation();
      } on Exception catch (e) {
        lastException = e;
        attempt++;

        // Check if we should retry this exception
        if (config.shouldRetry != null && !config.shouldRetry!(e)) {
          rethrow;
        }

        // Check if we've exhausted retries
        if (attempt > config.maxRetries) {
          rethrow;
        }

        // Calculate delay with exponential backoff and jitter
        final delay = _calculateDelay(
          attempt: attempt,
          initialDelay: config.initialDelay,
          backoffMultiplier: config.backoffMultiplier,
          maxDelay: config.maxDelay,
        );

        // Notify about retry
        onRetry?.call(attempt, e, delay);

        // Wait before next attempt
        await Future.delayed(delay);
      }
    }

    throw lastException!;
  }

  /// Calculates the delay for the next retry attempt with jitter
  static Duration _calculateDelay({
    required int attempt,
    required Duration initialDelay,
    required double backoffMultiplier,
    required Duration maxDelay,
  }) {
    // Exponential backoff: initialDelay * (multiplier ^ (attempt - 1))
    final exponentialDelay = initialDelay.inMilliseconds *
        pow(backoffMultiplier, attempt - 1).toInt();

    // Add jitter (±25% randomness) to prevent thundering herd
    final random = Random();
    final jitterFactor = 0.75 + (random.nextDouble() * 0.5); // 0.75 to 1.25
    final delayWithJitter = (exponentialDelay * jitterFactor).toInt();

    // Ensure delay doesn't exceed maximum
    final finalDelay = Duration(
      milliseconds: min(delayWithJitter, maxDelay.inMilliseconds),
    );

    return finalDelay;
  }
}