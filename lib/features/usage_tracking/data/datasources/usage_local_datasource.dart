import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/utils/logger.dart';
import '../models/message_usage_log_model.dart';
import '../models/quota_status_model.dart';
import '../models/user_subscription_model.dart';
import '../models/user_usage_stats_model.dart';

/// Abstract class for usage tracking local data source
abstract class UsageLocalDataSource {
  /// Cache user's usage statistics
  Future<void> cacheUsageStats(UserUsageStatsModel stats);

  /// Get cached usage statistics
  Future<UserUsageStatsModel?> getCachedUsageStats(String userId);

  /// Cache user's subscription
  Future<void> cacheSubscription(UserSubscriptionModel subscription);

  /// Get cached subscription
  Future<UserSubscriptionModel?> getCachedSubscription(String userId);

  /// Cache quota status
  Future<void> cacheQuotaStatus(QuotaStatusModel status);

  /// Get cached quota status
  Future<QuotaStatusModel?> getCachedQuotaStatus(String userId);

  /// Cache message usage logs
  Future<void> cacheUsageLogs(List<MessageUsageLogModel> logs);

  /// Get cached usage logs
  Future<List<MessageUsageLogModel>> getCachedUsageLogs(String userId);

  /// Clear all cached data for a user
  Future<void> clearUserCache(String userId);
}

/// Implementation of usage tracking local data source
class UsageLocalDataSourceImpl implements UsageLocalDataSource {
  final SharedPreferences sharedPreferences;
  final FlutterSecureStorage secureStorage;

  static const String USAGE_STATS_PREFIX = 'usage_stats_';
  static const String SUBSCRIPTION_PREFIX = 'subscription_';
  static const String QUOTA_STATUS_PREFIX = 'quota_status_';
  static const String USAGE_LOGS_PREFIX = 'usage_logs_';

  UsageLocalDataSourceImpl({
    required this.sharedPreferences,
    required this.secureStorage,
  });

  @override
  Future<void> cacheUsageStats(UserUsageStatsModel stats) async {
    try {
      final key = '$USAGE_STATS_PREFIX${stats.userId}';
      final jsonString = json.encode(stats.toJson());
      await sharedPreferences.setString(key, jsonString);
    } catch (e) {
      AppLogger.e('Error caching usage stats: $e');
      throw CacheException(message: 'Failed to cache usage stats');
    }
  }

  @override
  Future<UserUsageStatsModel?> getCachedUsageStats(String userId) async {
    try {
      final key = '$USAGE_STATS_PREFIX$userId';
      final jsonString = sharedPreferences.getString(key);

      if (jsonString != null) {
        final jsonMap = json.decode(jsonString) as Map<String, dynamic>;
        return UserUsageStatsModel.fromJson(jsonMap);
      }

      return null;
    } catch (e) {
      AppLogger.e('Error getting cached usage stats: $e');
      return null;
    }
  }

  @override
  Future<void> cacheSubscription(UserSubscriptionModel subscription) async {
    try {
      final key = '$SUBSCRIPTION_PREFIX${subscription.userId}';
      final jsonString = json.encode(subscription.toJson());

      // Store subscription in secure storage for sensitive data
      await secureStorage.write(key: key, value: jsonString);
    } catch (e) {
      AppLogger.e('Error caching subscription: $e');
      throw CacheException(message: 'Failed to cache subscription');
    }
  }

  @override
  Future<UserSubscriptionModel?> getCachedSubscription(String userId) async {
    try {
      final key = '$SUBSCRIPTION_PREFIX$userId';
      final jsonString = await secureStorage.read(key: key);

      if (jsonString != null) {
        final jsonMap = json.decode(jsonString) as Map<String, dynamic>;
        return UserSubscriptionModel.fromJson(jsonMap);
      }

      return null;
    } catch (e) {
      AppLogger.e('Error getting cached subscription: $e');
      return null;
    }
  }

  @override
  Future<void> cacheQuotaStatus(QuotaStatusModel status) async {
    try {
      final key = '$QUOTA_STATUS_PREFIX${status.tier}';
      final jsonString = json.encode(status.toJson());
      await sharedPreferences.setString(key, jsonString);
    } catch (e) {
      AppLogger.e('Error caching quota status: $e');
      throw CacheException(message: 'Failed to cache quota status');
    }
  }

  @override
  Future<QuotaStatusModel?> getCachedQuotaStatus(String userId) async {
    try {
      // First get user subscription to know their tier
      final subscription = await getCachedSubscription(userId);
      if (subscription == null) return null;

      final key = '$QUOTA_STATUS_PREFIX${subscription.currentTier}';
      final jsonString = sharedPreferences.getString(key);

      if (jsonString != null) {
        final jsonMap = json.decode(jsonString) as Map<String, dynamic>;
        return QuotaStatusModel.fromJson(jsonMap);
      }

      return null;
    } catch (e) {
      AppLogger.e('Error getting cached quota status: $e');
      return null;
    }
  }

  @override
  Future<void> cacheUsageLogs(List<MessageUsageLogModel> logs) async {
    try {
      if (logs.isEmpty) return;

      final userId = logs.first.userId;
      final key = '$USAGE_LOGS_PREFIX$userId';

      // Only cache the most recent logs (limit to 100)
      final logsToCache = logs.take(100).toList();
      final jsonList = logsToCache.map((log) => log.toJson()).toList();
      final jsonString = json.encode(jsonList);

      await sharedPreferences.setString(key, jsonString);
    } catch (e) {
      AppLogger.e('Error caching usage logs: $e');
      throw CacheException(message: 'Failed to cache usage logs');
    }
  }

  @override
  Future<List<MessageUsageLogModel>> getCachedUsageLogs(String userId) async {
    try {
      final key = '$USAGE_LOGS_PREFIX$userId';
      final jsonString = sharedPreferences.getString(key);

      if (jsonString != null) {
        final jsonList = json.decode(jsonString) as List<dynamic>;
        return jsonList
            .map(
              (json) =>
                  MessageUsageLogModel.fromJson(json as Map<String, dynamic>),
            )
            .toList();
      }

      return [];
    } catch (e) {
      AppLogger.e('Error getting cached usage logs: $e');
      return [];
    }
  }

  @override
  Future<void> clearUserCache(String userId) async {
    try {
      // Clear all cached data for the user
      await sharedPreferences.remove('$USAGE_STATS_PREFIX$userId');
      await sharedPreferences.remove('$USAGE_LOGS_PREFIX$userId');
      await secureStorage.delete(key: '$SUBSCRIPTION_PREFIX$userId');

      // Clear quota status for all tiers (since we don't know the user's tier)
      await sharedPreferences.remove('${QUOTA_STATUS_PREFIX}free');
      await sharedPreferences.remove('${QUOTA_STATUS_PREFIX}pro');
      await sharedPreferences.remove('${QUOTA_STATUS_PREFIX}premium');

      AppLogger.i('Cleared usage cache for user: $userId');
    } catch (e) {
      AppLogger.e('Error clearing user cache: $e');
      throw CacheException(message: 'Failed to clear user cache');
    }
  }
}
