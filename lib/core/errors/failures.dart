import 'package:equatable/equatable.dart';

/// Base class for all failures in the application
abstract class Failure extends Equatable {
  final String message;
  final int? code;

  const Failure({
    required this.message,
    this.code,
  });

  @override
  List<Object?> get props => [message, code];
}

/// Failure when there's an error from the server
class ServerFailure extends Failure {
  const ServerFailure({
    String message = 'Server error occurred',
    int? code,
  }) : super(message: message, code: code);
}

/// Failure when there's no internet connection
class NetworkFailure extends Failure {
  const NetworkFailure({
    String message = 'No internet connection',
    int? code,
  }) : super(message: message, code: code);
}

/// Failure related to AI provider operations
class AIProviderFailure extends Failure {
  const AIProviderFailure({
    required String message,
    int? code,
  }) : super(message: message, code: code);
}

/// Failure when rate limit is exceeded
class RateLimitFailure extends Failure {
  final String provider;
  final int? retryAfter;

  const RateLimitFailure({
    required this.provider,
    this.retryAfter,
    String message = 'Rate limit exceeded',
  }) : super(message: message);

  @override
  List<Object?> get props => [message, code, provider, retryAfter];
}

/// Failure when cached data is not available
class CacheFailure extends Failure {
  const CacheFailure({
    String message = 'Cache error occurred',
    int? code,
  }) : super(message: message, code: code);
}

/// Failure for validation errors
class ValidationFailure extends Failure {
  final Map<String, List<String>>? errors;

  const ValidationFailure({
    required String message,
    this.errors,
  }) : super(message: message);

  @override
  List<Object?> get props => [message, errors];
}

/// Failure for unauthorized access
class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure({
    String message = 'Unauthorized access',
  }) : super(message: message);
}

/// Failure for parsing errors
class ParsingFailure extends Failure {
  const ParsingFailure({
    String message = 'Failed to parse data',
    int? code,
  }) : super(message: message, code: code);
}