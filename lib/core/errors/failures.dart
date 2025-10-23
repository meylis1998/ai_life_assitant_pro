import 'package:equatable/equatable.dart';

/// Base class for all failures in the application
abstract class Failure extends Equatable {
  final String message;
  final int? code;

  const Failure({required this.message, this.code});

  @override
  List<Object?> get props => [message, code];
}

/// Failure when there's an error from the server
class ServerFailure extends Failure {
  const ServerFailure({super.message = 'Server error occurred', super.code});
}

/// Failure when there's no internet connection
class NetworkFailure extends Failure {
  const NetworkFailure({super.message = 'No internet connection', super.code});
}

/// Failure related to AI provider operations
class AIProviderFailure extends Failure {
  const AIProviderFailure({required super.message, super.code});
}

/// Failure when rate limit is exceeded
class RateLimitFailure extends Failure {
  final String provider;
  final int? retryAfter;

  const RateLimitFailure({
    required this.provider,
    this.retryAfter,
    super.message = 'Rate limit exceeded',
  });

  @override
  List<Object?> get props => [message, code, provider, retryAfter];
}

/// Failure when cached data is not available
class CacheFailure extends Failure {
  const CacheFailure({super.message = 'Cache error occurred', super.code});
}

/// Failure for validation errors
class ValidationFailure extends Failure {
  final Map<String, List<String>>? errors;

  const ValidationFailure({required super.message, this.errors});

  @override
  List<Object?> get props => [message, errors];
}

/// Failure for unauthorized access
class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure({super.message = 'Unauthorized access'});
}

/// Failure for parsing errors
class ParsingFailure extends Failure {
  const ParsingFailure({super.message = 'Failed to parse data', super.code});
}

/// Failure when user quota is exceeded
class UserQuotaExceededFailure extends Failure {
  final String userTier;
  final String quotaType; // daily, monthly, tokens
  final DateTime? resetTime;
  final String? upgradeSuggestion;

  const UserQuotaExceededFailure({
    required super.message,
    required this.userTier,
    required this.quotaType,
    this.resetTime,
    this.upgradeSuggestion,
  });

  @override
  List<Object?> get props => [
    message,
    userTier,
    quotaType,
    resetTime,
    upgradeSuggestion,
  ];
}

/// Failure when subscription has expired
class SubscriptionExpiredFailure extends Failure {
  final DateTime expiredAt;
  final String previousTier;

  const SubscriptionExpiredFailure({
    super.message = 'Subscription has expired',
    required this.expiredAt,
    required this.previousTier,
  });

  @override
  List<Object?> get props => [message, expiredAt, previousTier];
}

/// Failure when token limit is exceeded for a specific message
class TokenLimitExceededFailure extends Failure {
  final int requestedTokens;
  final int availableTokens;
  final String provider;

  const TokenLimitExceededFailure({
    required super.message,
    required this.requestedTokens,
    required this.availableTokens,
    required this.provider,
  });

  @override
  List<Object?> get props => [
    message,
    requestedTokens,
    availableTokens,
    provider,
  ];
}

/// Failure for weather API errors
class WeatherFailure extends Failure {
  const WeatherFailure({super.message = 'Weather data unavailable', super.code});
}

/// Failure for news API errors
class NewsFailure extends Failure {
  const NewsFailure({super.message = 'News data unavailable', super.code});
}

/// Failure for calendar access errors
class CalendarFailure extends Failure {
  const CalendarFailure({super.message = 'Calendar access failed', super.code});
}

/// Failure for location permission errors
class LocationFailure extends Failure {
  const LocationFailure({super.message = 'Location permission denied', super.code});
}

/// Failure for permission errors
class PermissionFailure extends Failure {
  final String permissionType;

  const PermissionFailure({
    required super.message,
    required this.permissionType,
  });

  @override
  List<Object?> get props => [message, permissionType];
}
