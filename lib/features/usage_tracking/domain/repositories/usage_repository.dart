import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/message_usage_log.dart';
import '../entities/quota_status.dart';
import '../entities/user_subscription.dart';
import '../entities/user_usage_stats.dart';

/// Abstract repository for usage tracking operations
abstract class UsageRepository {
  /// Get user's current usage statistics
  Future<Either<Failure, UserUsageStats>> getUserStats(String userId);

  /// Update user's usage statistics
  Future<Either<Failure, void>> updateUserStats(UserUsageStats stats);

  /// Reset daily statistics
  Future<Either<Failure, void>> resetDailyStats(String userId);

  /// Reset monthly statistics
  Future<Either<Failure, void>> resetMonthlyStats(String userId);

  /// Get user's current quota status
  Future<Either<Failure, QuotaStatus>> getQuotaStatus(String userId);

  /// Check if user can send a message (pre-flight check)
  Future<Either<Failure, bool>> checkQuota({
    required String userId,
    required String provider,
    int estimatedTokens = 500,
  });

  /// Log message usage after API response
  Future<Either<Failure, void>> logMessageUsage(MessageUsageLog log);

  /// Get message usage history for a user
  Future<Either<Failure, List<MessageUsageLog>>> getUsageHistory({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  });

  /// Increment usage counters
  Future<Either<Failure, void>> incrementUsage({
    required String userId,
    required int messageCount,
    required int tokenCount,
    required String provider,
  });

  /// Get user's subscription details
  Future<Either<Failure, UserSubscription>> getUserSubscription(String userId);

  /// Assign free tier to a new user
  Future<Either<Failure, UserSubscription>> assignFreeTier(String userId);

  /// Update user's subscription
  Future<Either<Failure, void>> updateSubscription(
    UserSubscription subscription,
  );

  /// Upgrade user's tier
  Future<Either<Failure, UserSubscription>> upgradeTier({
    required String userId,
    required String newTier,
    String? paymentMethod,
  });

  /// Downgrade user's tier
  Future<Either<Failure, UserSubscription>> downgradeTier({
    required String userId,
    required String newTier,
  });

  /// Get usage analytics for a period
  Future<Either<Failure, Map<String, dynamic>>> getUsageAnalytics({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Stream real-time quota updates
  Stream<QuotaStatus> watchQuotaStatus(String userId);

  /// Stream real-time usage stats
  Stream<UserUsageStats> watchUserStats(String userId);

  /// Clear cached usage data
  Future<Either<Failure, void>> clearUsageCache(String userId);

  /// Export usage data for user
  Future<Either<Failure, Map<String, dynamic>>> exportUsageData({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Get provider-specific usage
  Future<Either<Failure, Map<String, int>>> getProviderUsage({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Check rate limit for specific provider
  Future<Either<Failure, bool>> checkRateLimit({
    required String userId,
    required String provider,
  });

  /// Get estimated cost for user's usage
  Future<Either<Failure, double>> getEstimatedCost({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
  });
}
