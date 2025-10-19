/// Custom exceptions for data layer
/// These exceptions are thrown from data sources and caught in repositories

/// Base exception class
abstract class AppException implements Exception {
  final String message;
  final int? code;

  const AppException({
    required this.message,
    this.code,
  });

  @override
  String toString() => '$runtimeType: $message ${code != null ? "(Code: $code)" : ""}';
}

/// Exception when there's an error from the server
class ServerException extends AppException {
  const ServerException({
    String message = 'Server error',
    int? code,
  }) : super(message: message, code: code);
}

/// Exception when there's no internet connection
class NetworkException extends AppException {
  const NetworkException({
    String message = 'Network error',
  }) : super(message: message);
}

/// Exception related to AI provider operations
class AIProviderException extends AppException {
  final String provider;

  const AIProviderException({
    required this.provider,
    required String message,
    int? code,
  }) : super(message: message, code: code);
}

/// Exception when rate limit is exceeded
class RateLimitException extends AppException {
  final String provider;
  final int? retryAfter;

  const RateLimitException({
    required this.provider,
    this.retryAfter,
    String message = 'Rate limit exceeded',
  }) : super(message: message);
}

/// Exception when cached data operations fail
class CacheException extends AppException {
  const CacheException({
    String message = 'Cache error',
  }) : super(message: message);
}

/// Exception for validation errors
class ValidationException extends AppException {
  final Map<String, List<String>>? errors;

  const ValidationException({
    required String message,
    this.errors,
  }) : super(message: message);
}

/// Exception for unauthorized access
class UnauthorizedException extends AppException {
  const UnauthorizedException({
    String message = 'Unauthorized',
  }) : super(message: message);
}

/// Exception for parsing errors
class ParsingException extends AppException {
  const ParsingException({
    String message = 'Parsing failed',
    int? code,
  }) : super(message: message, code: code);
}

/// Exception for file operations
class FileException extends AppException {
  const FileException({
    required String message,
  }) : super(message: message);
}