import 'package:equatable/equatable.dart';
import '../../domain/entities/quota_status.dart';
import '../../domain/entities/user_subscription.dart';
import '../../domain/entities/user_usage_stats.dart';
import '../../domain/entities/message_usage_log.dart';

/// Base class for all usage tracking states
abstract class UsageState extends Equatable {
  final UserUsageStats? usageStats;
  final QuotaStatus? quotaStatus;
  final UserSubscription? subscription;
  final String? error;
  final bool isLoading;

  const UsageState({
    this.usageStats,
    this.quotaStatus,
    this.subscription,
    this.error,
    this.isLoading = false,
  });

  @override
  List<Object?> get props => [
    usageStats,
    quotaStatus,
    subscription,
    error,
    isLoading,
  ];
}

/// Initial state before any usage data is loaded
class UsageInitial extends UsageState {
  const UsageInitial() : super();
}

/// Loading state while fetching usage data
class UsageLoading extends UsageState {
  const UsageLoading({super.usageStats, super.quotaStatus, super.subscription})
    : super(isLoading: true);
}

/// State when usage data is successfully loaded
class UsageLoaded extends UsageState {
  const UsageLoaded({
    required UserUsageStats usageStats,
    required QuotaStatus quotaStatus,
    required UserSubscription subscription,
  }) : super(
         usageStats: usageStats,
         quotaStatus: quotaStatus,
         subscription: subscription,
       );

  /// Create a copy with updated values
  UsageLoaded copyWith({
    UserUsageStats? usageStats,
    QuotaStatus? quotaStatus,
    UserSubscription? subscription,
  }) {
    return UsageLoaded(
      usageStats: usageStats ?? this.usageStats!,
      quotaStatus: quotaStatus ?? this.quotaStatus!,
      subscription: subscription ?? this.subscription!,
    );
  }
}

/// State when usage has been updated
class UsageUpdated extends UsageState {
  final int messagesUsedToday;
  final int tokensUsedToday;
  final double estimatedCostToday;
  final int messagesRemaining;
  final int tokensRemaining;
  final double usagePercentage;

  const UsageUpdated({
    required this.messagesUsedToday,
    required this.tokensUsedToday,
    required this.estimatedCostToday,
    required this.messagesRemaining,
    required this.tokensRemaining,
    required this.usagePercentage,
    required UserUsageStats usageStats,
    required QuotaStatus quotaStatus,
    required UserSubscription subscription,
  }) : super(
         usageStats: usageStats,
         quotaStatus: quotaStatus,
         subscription: subscription,
       );

  @override
  List<Object?> get props => [
    ...super.props,
    messagesUsedToday,
    tokensUsedToday,
    estimatedCostToday,
    messagesRemaining,
    tokensRemaining,
    usagePercentage,
  ];
}

/// State when approaching quota limit
class UsageWarning extends UsageState {
  final String warningMessage;
  final double usagePercentage;
  final int messagesRemaining;
  final int tokensRemaining;
  final DateTime? resetTime;

  const UsageWarning({
    required this.warningMessage,
    required this.usagePercentage,
    required this.messagesRemaining,
    required this.tokensRemaining,
    this.resetTime,
    required UserUsageStats usageStats,
    required QuotaStatus quotaStatus,
    required UserSubscription subscription,
  }) : super(
         usageStats: usageStats,
         quotaStatus: quotaStatus,
         subscription: subscription,
       );

  @override
  List<Object?> get props => [
    ...super.props,
    warningMessage,
    usagePercentage,
    messagesRemaining,
    tokensRemaining,
    resetTime,
  ];
}

/// State when quota is exceeded
class UsageExceeded extends UsageState {
  final String quotaType; // 'daily', 'monthly', 'tokens'
  final DateTime? resetTime;
  final String? upgradeSuggestion;
  final String? upgradeUrl;

  const UsageExceeded({
    required this.quotaType,
    this.resetTime,
    this.upgradeSuggestion,
    this.upgradeUrl,
    required UserUsageStats usageStats,
    required QuotaStatus quotaStatus,
    required UserSubscription subscription,
  }) : super(
         usageStats: usageStats,
         quotaStatus: quotaStatus,
         subscription: subscription,
       );

  String get formattedResetTime {
    if (resetTime == null) return '';
    final duration = resetTime!.difference(DateTime.now());
    if (duration.inDays > 0) {
      return '${duration.inDays}d ${duration.inHours.remainder(24)}h';
    } else if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m';
    } else {
      return 'Less than a minute';
    }
  }

  @override
  List<Object?> get props => [
    ...super.props,
    quotaType,
    resetTime,
    upgradeSuggestion,
    upgradeUrl,
  ];
}

/// State when subscription is checked
class SubscriptionChecked extends UsageState {
  final bool isActive;
  final DateTime? expiresAt;
  final String currentTier;
  final List<String> availableProviders;

  const SubscriptionChecked({
    required this.isActive,
    this.expiresAt,
    required this.currentTier,
    required this.availableProviders,
    required UserSubscription super.subscription,
    super.usageStats,
    super.quotaStatus,
  });

  @override
  List<Object?> get props => [
    ...super.props,
    isActive,
    expiresAt,
    currentTier,
    availableProviders,
  ];
}

/// State when subscription is upgraded
class SubscriptionUpgraded extends UsageState {
  final String previousTier;
  final String newTier;
  final DateTime upgradeDate;
  final Map<String, int> newLimits;

  const SubscriptionUpgraded({
    required this.previousTier,
    required this.newTier,
    required this.upgradeDate,
    required this.newLimits,
    required UserSubscription subscription,
    required UserUsageStats usageStats,
    required QuotaStatus quotaStatus,
  }) : super(
         subscription: subscription,
         usageStats: usageStats,
         quotaStatus: quotaStatus,
       );

  @override
  List<Object?> get props => [
    ...super.props,
    previousTier,
    newTier,
    upgradeDate,
    newLimits,
  ];
}

/// State when analytics are loaded
class UsageAnalyticsLoaded extends UsageState {
  final Map<String, dynamic> analytics;
  final List<MessageUsageLog> recentUsage;
  final Map<String, double> costBreakdown;
  final Map<String, int> providerUsage;
  final double totalCost;
  final int totalMessages;
  final int totalTokens;

  const UsageAnalyticsLoaded({
    required this.analytics,
    required this.recentUsage,
    required this.costBreakdown,
    required this.providerUsage,
    required this.totalCost,
    required this.totalMessages,
    required this.totalTokens,
    super.usageStats,
    super.quotaStatus,
    super.subscription,
  });

  @override
  List<Object?> get props => [
    ...super.props,
    analytics,
    recentUsage,
    costBreakdown,
    providerUsage,
    totalCost,
    totalMessages,
    totalTokens,
  ];
}

/// State when usage data is exported
class UsageDataExported extends UsageState {
  final String filePath;
  final String format;
  final int recordCount;
  final DateTime exportDate;

  const UsageDataExported({
    required this.filePath,
    required this.format,
    required this.recordCount,
    required this.exportDate,
    super.usageStats,
    super.quotaStatus,
    super.subscription,
  });

  @override
  List<Object?> get props => [
    ...super.props,
    filePath,
    format,
    recordCount,
    exportDate,
  ];
}

/// Error state for usage tracking
class UsageError extends UsageState {
  final String errorMessage;
  final String? errorCode;
  final bool isRetryable;

  const UsageError({
    required this.errorMessage,
    this.errorCode,
    this.isRetryable = true,
    super.usageStats,
    super.quotaStatus,
    super.subscription,
  }) : super(error: errorMessage);

  @override
  List<Object?> get props => [
    ...super.props,
    errorMessage,
    errorCode,
    isRetryable,
  ];
}
