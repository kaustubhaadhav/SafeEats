import 'package:dio/dio.dart';
import 'retry_helper.dart';

/// API client with built-in retry logic for resilient network requests
class ApiClient {
  final Dio _dio;
  final RetryConfig _retryConfig;

  ApiClient(
    this._dio, {
    RetryConfig? retryConfig,
  }) : _retryConfig = retryConfig ?? const RetryConfig(
    maxRetries: 3,
    initialDelay: Duration(milliseconds: 500),
    backoffMultiplier: 2.0,
    maxDelay: Duration(seconds: 10),
  );

  /// Performs a GET request with automatic retry on transient failures
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    bool enableRetry = true,
  }) async {
    if (!enableRetry) {
      return _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    }

    return RetryHelper.withRetry(
      operation: () => _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
      ),
      config: _retryConfig.copyWith(
        shouldRetry: _isRetryableError,
      ),
      onRetry: (attempt, error, delay) {
        // Log retry attempts for debugging
        // print('Retry attempt $attempt after error: $error, waiting ${delay.inMilliseconds}ms');
      },
    );
  }

  /// Performs a POST request with automatic retry on transient failures
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    bool enableRetry = true,
  }) async {
    if (!enableRetry) {
      return _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    }

    return RetryHelper.withRetry(
      operation: () => _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      ),
      config: _retryConfig.copyWith(
        shouldRetry: _isRetryableError,
      ),
    );
  }

  /// Determines if an error is retryable (transient network errors)
  bool _isRetryableError(Exception e) {
    if (e is DioException) {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.connectionError:
          return true;
        case DioExceptionType.badResponse:
          // Retry on server errors (5xx) but not client errors (4xx)
          final statusCode = e.response?.statusCode;
          if (statusCode != null && statusCode >= 500 && statusCode < 600) {
            return true;
          }
          // Also retry on 429 Too Many Requests
          if (statusCode == 429) {
            return true;
          }
          return false;
        case DioExceptionType.cancel:
        case DioExceptionType.badCertificate:
        case DioExceptionType.unknown:
          return false;
      }
    }
    return false;
  }
}

/// Extension to add copyWith to RetryConfig
extension RetryConfigCopyWith on RetryConfig {
  RetryConfig copyWith({
    int? maxRetries,
    Duration? initialDelay,
    double? backoffMultiplier,
    Duration? maxDelay,
    bool Function(Exception)? shouldRetry,
  }) {
    return RetryConfig(
      maxRetries: maxRetries ?? this.maxRetries,
      initialDelay: initialDelay ?? this.initialDelay,
      backoffMultiplier: backoffMultiplier ?? this.backoffMultiplier,
      maxDelay: maxDelay ?? this.maxDelay,
      shouldRetry: shouldRetry ?? this.shouldRetry,
    );
  }
}