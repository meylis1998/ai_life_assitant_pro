import 'package:equatable/equatable.dart';

/// Base class for all usage tracking events
abstract class UsageEvent extends Equatable {
  const UsageEvent();

  @override
  List<Object?> get props => [];
}

/// Initialize usage tracking for a user
class InitializeUsageTracking extends UsageEvent {
  final String userId;

  const InitializeUsageTracking({required this.userId});

  @override
  List<Object?> get props => [userId];
}

/// Check current quota status
class CheckQuotaStatus extends UsageEvent {
  final String userId;
  final String? provider;
  final int? estimatedTokens;

  const CheckQuotaStatus({
    required this.userId,
    this.provider,
    this.estimatedTokens,
  });

  @override
  List<Object?> get props => [userId, provider, estimatedTokens];
}

/// Update usage after a message
class UpdateUsage extends UsageEvent {
  final String userId;
  final int messageCount;
  final int tokenCount;
  final String provider;
  final int responseTimeMs;

  const UpdateUsage({
    required this.userId,
    required this.messageCount,
    required this.tokenCount,
    required this.provider,
    required this.responseTimeMs,
  });

  @override
  List<Object?> get props => [
    userId,
    messageCount,
    tokenCount,
    provider,
    responseTimeMs,
  ];
}

/// Log a message usage
class LogMessageUsage extends UsageEvent {
  final String userId;
  final String messageId;
  final String conversationId;
  final int inputTokens;
  final int outputTokens;
  final String provider;
  final int responseTimeMs;

  const LogMessageUsage({
    required this.userId,
    required this.messageId,
    required this.conversationId,
    required this.inputTokens,
    required this.outputTokens,
    required this.provider,
    required this.responseTimeMs,
  });

  @override
  List<Object?> get props => [
    userId,
    messageId,
    conversationId,
    inputTokens,
    outputTokens,
    provider,
    responseTimeMs,
  ];
}

/// Refresh usage stats
class RefreshUsageStats extends UsageEvent {
  final String userId;
  final bool forceRefresh;

  const RefreshUsageStats({required this.userId, this.forceRefresh = false});

  @override
  List<Object?> get props => [userId, forceRefresh];
}

/// Check subscription status
class CheckSubscription extends UsageEvent {
  final String userId;

  const CheckSubscription({required this.userId});

  @override
  List<Object?> get props => [userId];
}

/// Reset daily usage (typically called at midnight)
class ResetDailyUsage extends UsageEvent {
  final String userId;

  const ResetDailyUsage({required this.userId});

  @override
  List<Object?> get props => [userId];
}

/// Reset monthly usage (typically called on the 1st)
class ResetMonthlyUsage extends UsageEvent {
  final String userId;

  const ResetMonthlyUsage({required this.userId});

  @override
  List<Object?> get props => [userId];
}

/// Get usage analytics
class GetUsageAnalytics extends UsageEvent {
  final String userId;
  final DateTime? startDate;
  final DateTime? endDate;

  const GetUsageAnalytics({required this.userId, this.startDate, this.endDate});

  @override
  List<Object?> get props => [userId, startDate, endDate];
}

/// Upgrade subscription
class UpgradeSubscription extends UsageEvent {
  final String userId;
  final String newTier;
  final String? paymentMethod;

  const UpgradeSubscription({
    required this.userId,
    required this.newTier,
    this.paymentMethod,
  });

  @override
  List<Object?> get props => [userId, newTier, paymentMethod];
}

/// Export usage data
class ExportUsageData extends UsageEvent {
  final String userId;
  final String format; // csv, json, pdf
  final DateTime? startDate;
  final DateTime? endDate;

  const ExportUsageData({
    required this.userId,
    required this.format,
    this.startDate,
    this.endDate,
  });

  @override
  List<Object?> get props => [userId, format, startDate, endDate];
}
