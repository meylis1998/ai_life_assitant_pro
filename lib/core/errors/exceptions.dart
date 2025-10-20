/// Custom exceptions for data layer
/// These exceptions are thrown from data sources and caught in repositories
library;

/// Base exception class
abstract class AppException implements Exception {
  final String message;
  final int? code;

  const AppException({required this.message, this.code});

  @override
  String toString() =>
      '$runtimeType: $message ${code != null ? "(Code: $code)" : ""}';
}

/// Exception when there's an error from the server
class ServerException extends AppException {
  const ServerException({super.message = 'Server error', super.code});
}

/// Exception when there's no internet connection
class NetworkException extends AppException {
  const NetworkException({super.message = 'Network error'});
}

/// Exception related to AI provider operations
class AIProviderException extends AppException {
  final String provider;

  const AIProviderException({
    required this.provider,
    required super.message,
    super.code,
  });
}

/// Exception when rate limit is exceeded
class RateLimitException extends AppException {
  final String provider;
  final int? retryAfter;

  const RateLimitException({
    required this.provider,
    this.retryAfter,
    super.message = 'Rate limit exceeded',
  });
}

/// Exception when cached data operations fail
class CacheException extends AppException {
  const CacheException({super.message = 'Cache error'});
}

/// Exception for validation errors
class ValidationException extends AppException {
  final Map<String, List<String>>? errors;

  const ValidationException({required super.message, this.errors});
}

/// Exception for unauthorized access
class UnauthorizedException extends AppException {
  const UnauthorizedException({super.message = 'Unauthorized'});
}

/// Exception for parsing errors
class ParsingException extends AppException {
  const ParsingException({super.message = 'Parsing failed', super.code});
}

/// Exception for file operations
class FileException extends AppException {
  const FileException({required super.message});
}
