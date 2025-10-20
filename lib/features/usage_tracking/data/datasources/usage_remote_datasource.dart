import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/utils/logger.dart';
import '../models/message_usage_log_model.dart';
import '../models/quota_status_model.dart';
import '../models/user_subscription_model.dart';
import '../models/user_usage_stats_model.dart';

/// Abstract class for usage tracking remote data source
abstract class UsageRemoteDataSource {
  /// Get user's usage statistics from Firestore
  Future<UserUsageStatsModel> getUserUsageStats(String userId);

  /// Update user's usage statistics
  Future<void> updateUsageStats(UserUsageStatsModel stats);

  /// Get user's subscription information
  Future<UserSubscriptionModel> getUserSubscription(String userId);

  /// Update user's subscription
  Future<void> updateSubscription(UserSubscriptionModel subscription);

  /// Log a message usage event
  Future<void> logMessageUsage(MessageUsageLogModel log);

  /// Get usage history
  Future<List<MessageUsageLogModel>> getUsageHistory(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  });

  /// Get quota status
  Future<QuotaStatusModel> getQuotaStatus(String userId);
}

/// Implementation of usage tracking remote data source using Firestore
class UsageRemoteDataSourceImpl implements UsageRemoteDataSource {
  final FirebaseFirestore firestore;

  UsageRemoteDataSourceImpl({required this.firestore});

  @override
  Future<UserUsageStatsModel> getUserUsageStats(String userId) async {
    try {
      final doc = await firestore
          .collection('users')
          .doc(userId)
          .collection('usage')
          .doc('stats')
          .get();

      if (doc.exists && doc.data() != null) {
        return UserUsageStatsModel.fromJson(doc.data()!);
      } else {
        // Create initial stats if not exists
        final now = DateTime.now().toIso8601String();
        final initialStats = UserUsageStatsModel(
          userId: userId,
          messagesThisDay: 0,
          messagesThisMonth: 0,
          tokensThisDay: 0,
          tokensThisMonth: 0,
          messagesThisHour: 0,
          userTier: 'free',
          lastMessageTime: now,
          providerUsage: {},
          statsResetDate: now,
          createdAt: now,
          updatedAt: now,
        );

        await firestore
            .collection('users')
            .doc(userId)
            .collection('usage')
            .doc('stats')
            .set(initialStats.toJson());

        return initialStats;
      }
    } catch (e) {
      AppLogger.e('Error getting user usage stats: $e');
      throw ServerException(message: 'Failed to get usage stats');
    }
  }

  @override
  Future<void> updateUsageStats(UserUsageStatsModel stats) async {
    try {
      await firestore
          .collection('users')
          .doc(stats.userId)
          .collection('usage')
          .doc('stats')
          .set(stats.toJson(), SetOptions(merge: true));
    } catch (e) {
      AppLogger.e('Error updating usage stats: $e');
      throw ServerException(message: 'Failed to update usage stats');
    }
  }

  @override
  Future<UserSubscriptionModel> getUserSubscription(String userId) async {
    try {
      final doc = await firestore
          .collection('users')
          .doc(userId)
          .collection('subscription')
          .doc('current')
          .get();

      if (doc.exists && doc.data() != null) {
        return UserSubscriptionModel.fromJson(doc.data()!);
      } else {
        // Create free tier subscription if not exists
        final freeSubscription = UserSubscriptionModel(
          userId: userId,
          tier: 'free',
          startDate: DateTime.now().toIso8601String(),
          endDate: null,
          isActive: true,
        );

        await firestore
            .collection('users')
            .doc(userId)
            .collection('subscription')
            .doc('current')
            .set(freeSubscription.toJson());

        return freeSubscription;
      }
    } catch (e) {
      AppLogger.e('Error getting user subscription: $e');
      throw ServerException(message: 'Failed to get subscription');
    }
  }

  @override
  Future<void> updateSubscription(UserSubscriptionModel subscription) async {
    try {
      await firestore
          .collection('users')
          .doc(subscription.userId)
          .collection('subscription')
          .doc('current')
          .set(subscription.toJson());

      // Also update in subscription history
      await firestore
          .collection('users')
          .doc(subscription.userId)
          .collection('subscription')
          .doc('history')
          .collection('entries')
          .add({
            ...subscription.toJson(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
    } catch (e) {
      AppLogger.e('Error updating subscription: $e');
      throw ServerException(message: 'Failed to update subscription');
    }
  }

  @override
  Future<void> logMessageUsage(MessageUsageLogModel log) async {
    try {
      await firestore
          .collection('users')
          .doc(log.userId)
          .collection('usage')
          .doc('logs')
          .collection('messages')
          .add({...log.toJson(), 'timestamp': FieldValue.serverTimestamp()});
    } catch (e) {
      AppLogger.e('Error logging message usage: $e');
      throw ServerException(message: 'Failed to log usage');
    }
  }

  @override
  Future<List<MessageUsageLogModel>> getUsageHistory(
    String userId, {
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    try {
      Query query = firestore
          .collection('users')
          .doc(userId)
          .collection('usage')
          .doc('logs')
          .collection('messages')
          .orderBy('timestamp', descending: true);

      if (startDate != null) {
        query = query.where('timestamp', isGreaterThanOrEqualTo: startDate);
      }

      if (endDate != null) {
        query = query.where('timestamp', isLessThanOrEqualTo: endDate);
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();

      return snapshot.docs
          .map(
            (doc) => MessageUsageLogModel.fromJson(
              doc.data() as Map<String, dynamic>,
            ),
          )
          .toList();
    } catch (e) {
      AppLogger.e('Error getting usage history: $e');
      throw ServerException(message: 'Failed to get usage history');
    }
  }

  @override
  Future<QuotaStatusModel> getQuotaStatus(String userId) async {
    try {
      // Get current stats and subscription
      final stats = await getUserUsageStats(userId);
      final subscription = await getUserSubscription(userId);

      // Calculate quota status based on tier
      final limits = _getLimitsForTier(subscription.currentTier);
      final messagesUsed = stats.messagesThisDay;
      final tokensUsed = stats.tokensThisDay;

      final isExceeded =
          messagesUsed >= limits['dailyMessages']! ||
          tokensUsed >= limits['dailyTokens']!;
      final usagePercentage = ((messagesUsed / limits['dailyMessages']!) * 100)
          .clamp(0, 100);

      // Calculate next reset time
      final now = DateTime.now();
      final nextReset = DateTime(now.year, now.month, now.day + 1);

      return QuotaStatusModel(
        userId: userId,
        tier: subscription.currentTier,
        dailyMessageLimit: limits['dailyMessages']!,
        dailyMessagesUsed: messagesUsed,
        dailyTokenLimit: limits['dailyTokens']!,
        dailyTokensUsed: tokensUsed,
        monthlyMessageLimit: limits['monthlyMessages']!,
        monthlyMessagesUsed: stats.messagesThisMonth,
        monthlyTokenLimit: limits['monthlyTokens']!,
        monthlyTokensUsed: stats.tokensThisMonth,
        lastResetDate: now.toIso8601String(),
        nextResetDate: nextReset.toIso8601String(),
        isExceeded: isExceeded,
        warningMessage: usagePercentage >= 80
            ? 'Approaching daily limit (${usagePercentage.toStringAsFixed(0)}% used)'
            : null,
      );
    } catch (e) {
      AppLogger.e('Error getting quota status: $e');
      throw ServerException(message: 'Failed to get quota status');
    }
  }

  Map<String, int> _getLimitsForTier(String tier) {
    switch (tier.toLowerCase()) {
      case 'free':
        return {
          'dailyMessages': 20,
          'dailyTokens': 10000,
          'monthlyMessages': 600,
          'monthlyTokens': 300000,
        };
      case 'pro':
        return {
          'dailyMessages': 200,
          'dailyTokens': 100000,
          'monthlyMessages': 6000,
          'monthlyTokens': 3000000,
        };
      case 'premium':
        return {
          'dailyMessages': 999999,
          'dailyTokens': 999999999,
          'monthlyMessages': 999999,
          'monthlyTokens': 999999999,
        };
      default:
        return {
          'dailyMessages': 20,
          'dailyTokens': 10000,
          'monthlyMessages': 600,
          'monthlyTokens': 300000,
        };
    }
  }
}
