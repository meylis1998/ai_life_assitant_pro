import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/message_usage_log.dart';
import '../../domain/entities/quota_status.dart';
import '../../domain/entities/user_subscription.dart';
import '../../domain/entities/user_usage_stats.dart';
import '../../domain/repositories/usage_repository.dart';

/// Implementation of UsageRepository
class UsageRepositoryImpl implements UsageRepository {
  final FirebaseFirestore firestore;
  final NetworkInfo networkInfo;

  // Local cache for quick access
  final Map<String, UserUsageStats> _statsCache = {};
  final Map<String, QuotaStatus> _quotaCache = {};
  final Map<String, UserSubscription> _subscriptionCache = {};

  UsageRepositoryImpl({required this.firestore, required this.networkInfo});

  @override
  Future<Either<Failure, UserUsageStats>> getUserStats(String userId) async {
    try {
      // Check cache first
      if (_statsCache.containsKey(userId)) {
        final cached = _statsCache[userId]!;
        // Check if stats need reset
        if (cached.needsDailyReset()) {
          await resetDailyStats(userId);
        } else if (cached.needsMonthlyReset()) {
          await resetMonthlyStats(userId);
        }
        return Right(cached);
      }

      // Fetch from Firestore
      final doc = await firestore
          .collection('users')
          .doc(userId)
          .collection('usage')
          .doc('stats')
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        final stats = _parseUserStats(userId, data);
        _statsCache[userId] = stats;
        return Right(stats);
      } else {
        // Create new stats for user
        final newStats = UserUsageStats.empty(userId);
        await _saveStats(newStats);
        _statsCache[userId] = newStats;
        return Right(newStats);
      }
    } on FirebaseException catch (e) {
      return Left(ServerFailure(message: 'Firebase error: ${e.message}'));
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to get user stats: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> updateUserStats(UserUsageStats stats) async {
    try {
      await _saveStats(stats);
      _statsCache[stats.userId] = stats;
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to update stats: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> resetDailyStats(String userId) async {
    try {
      final statsResult = await getUserStats(userId);

      return statsResult.fold((failure) => Left(failure), (stats) async {
        final resetStats = stats.copyWith(
          messagesThisDay: 0,
          tokensThisDay: 0,
          messagesThisHour: 0,
          lastMessageTime: DateTime.now(),
        );

        await _saveStats(resetStats);
        _statsCache[userId] = resetStats;
        return const Right(null);
      });
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to reset daily stats: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> resetMonthlyStats(String userId) async {
    try {
      final statsResult = await getUserStats(userId);

      return statsResult.fold((failure) => Left(failure), (stats) async {
        final resetStats = stats.copyWith(
          messagesThisMonth: 0,
          tokensThisMonth: 0,
          messagesThisDay: 0,
          tokensThisDay: 0,
          messagesThisHour: 0,
          lastMessageTime: DateTime.now(),
          statsResetDate: DateTime.now(),
        );

        await _saveStats(resetStats);
        _statsCache[userId] = resetStats;
        return const Right(null);
      });
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to reset monthly stats: $e'));
    }
  }

  @override
  Future<Either<Failure, QuotaStatus>> getQuotaStatus(String userId) async {
    try {
      // Get user stats
      final statsResult = await getUserStats(userId);

      return statsResult.fold((failure) => Left(failure), (stats) async {
        // Get user subscription for tier
        final subResult = await getUserSubscription(userId);

        return subResult.fold((failure) => Left(failure), (subscription) {
          final quota = QuotaStatus.forTier(
            userId: userId,
            tier: subscription.currentTier,
            dailyMessagesUsed: stats.messagesThisDay,
            dailyTokensUsed: stats.tokensThisDay,
            monthlyMessagesUsed: stats.messagesThisMonth,
            monthlyTokensUsed: stats.tokensThisMonth,
          );

          _quotaCache[userId] = quota;
          return Right(quota);
        });
      });
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to get quota status: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> checkQuota({
    required String userId,
    required String provider,
    int estimatedTokens = 500,
  }) async {
    try {
      final quotaResult = await getQuotaStatus(userId);

      return quotaResult.fold((failure) => Left(failure), (quota) {
        // Check if provider is allowed for tier
        final subResult = _subscriptionCache[userId];
        if (subResult != null && !subResult.canUseProvider(provider)) {
          return const Right(false);
        }

        // Check quota availability
        final canSend = quota.canSendMessage(estimatedTokens: estimatedTokens);
        return Right(canSend);
      });
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to check quota: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> logMessageUsage(MessageUsageLog log) async {
    try {
      // Save to Firestore
      await firestore
          .collection('usageLogs')
          .doc(log.userId)
          .collection('messages')
          .doc(log.id)
          .set(_messageLogToMap(log));

      // Update user stats
      await incrementUsage(
        userId: log.userId,
        messageCount: 1,
        tokenCount: log.totalTokens,
        provider: log.aiProvider,
      );

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to log usage: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> incrementUsage({
    required String userId,
    required int messageCount,
    required int tokenCount,
    required String provider,
  }) async {
    try {
      final statsResult = await getUserStats(userId);

      return statsResult.fold((failure) => Left(failure), (stats) async {
        // Update provider usage
        final providerUsage = Map<String, int>.from(stats.providerUsage);
        providerUsage[provider] = (providerUsage[provider] ?? 0) + messageCount;

        // Update stats
        final updatedStats = stats.copyWith(
          messagesThisMonth: stats.messagesThisMonth + messageCount,
          tokensThisMonth: stats.tokensThisMonth + tokenCount,
          messagesThisDay: stats.messagesThisDay + messageCount,
          tokensThisDay: stats.tokensThisDay + tokenCount,
          messagesThisHour: stats.messagesThisHour + messageCount,
          lastMessageTime: DateTime.now(),
          providerUsage: providerUsage,
          updatedAt: DateTime.now(),
        );

        await _saveStats(updatedStats);
        _statsCache[userId] = updatedStats;

        return const Right(null);
      });
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to increment usage: $e'));
    }
  }

  @override
  Future<Either<Failure, UserSubscription>> getUserSubscription(
    String userId,
  ) async {
    try {
      // Check cache
      if (_subscriptionCache.containsKey(userId)) {
        return Right(_subscriptionCache[userId]!);
      }

      // Fetch from Firestore
      final doc = await firestore
          .collection('users')
          .doc(userId)
          .collection('subscription')
          .doc('current')
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        final subscription = _parseSubscription(userId, data);
        _subscriptionCache[userId] = subscription;
        return Right(subscription);
      } else {
        // Create free tier subscription
        final freeSub = UserSubscription.free(userId);
        await _saveSubscription(freeSub);
        _subscriptionCache[userId] = freeSub;
        return Right(freeSub);
      }
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to get subscription: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> updateSubscription(
    UserSubscription subscription,
  ) async {
    try {
      await _saveSubscription(subscription);
      _subscriptionCache[subscription.userId] = subscription;
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to update subscription: $e'));
    }
  }

  @override
  Future<Either<Failure, UserSubscription>> upgradeTier({
    required String userId,
    required String newTier,
    String? paymentMethod,
  }) async {
    try {
      UserSubscription newSubscription;

      switch (newTier.toLowerCase()) {
        case 'pro':
          newSubscription = UserSubscription.pro(
            userId,
            paymentMethod: paymentMethod,
          );
          break;
        case 'premium':
          newSubscription = UserSubscription.premium(
            userId,
            paymentMethod: paymentMethod,
          );
          break;
        default:
          newSubscription = UserSubscription.free(userId);
      }

      await _saveSubscription(newSubscription);
      _subscriptionCache[userId] = newSubscription;

      return Right(newSubscription);
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to upgrade tier: $e'));
    }
  }

  @override
  Future<Either<Failure, UserSubscription>> downgradeTier({
    required String userId,
    required String newTier,
  }) async {
    return upgradeTier(userId: userId, newTier: newTier);
  }

  @override
  Future<Either<Failure, List<MessageUsageLog>>> getUsageHistory({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
  }) async {
    try {
      Query query = firestore
          .collection('usageLogs')
          .doc(userId)
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
      final logs = snapshot.docs.map((doc) {
        return _parseMessageLog(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();

      return Right(logs);
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to get usage history: $e'));
    }
  }

  @override
  Stream<QuotaStatus> watchQuotaStatus(String userId) {
    return Stream.periodic(const Duration(seconds: 5), (_) async {
      final result = await getQuotaStatus(userId);
      return result.fold(
        (failure) => throw Exception(failure.message),
        (quota) => quota,
      );
    }).asyncMap((future) => future);
  }

  @override
  Stream<UserUsageStats> watchUserStats(String userId) {
    return firestore
        .collection('users')
        .doc(userId)
        .collection('usage')
        .doc('stats')
        .snapshots()
        .map((doc) {
          if (doc.exists) {
            return _parseUserStats(userId, doc.data()!);
          } else {
            return UserUsageStats.empty(userId);
          }
        });
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getUsageAnalytics({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final historyResult = await getUsageHistory(
        userId: userId,
        startDate: startDate,
        endDate: endDate,
      );

      return historyResult.fold((failure) => Left(failure), (logs) {
        final providerDistribution = <String, int>{};

        final analytics = {
          'totalMessages': logs.length,
          'totalTokens': logs.fold(0, (total, log) => total + log.totalTokens),
          'averageResponseTime': logs.isEmpty
              ? 0
              : logs.fold(0, (total, log) => total + log.responseTimeMs) ~/
                    logs.length,
          'providerDistribution': providerDistribution,
          'successRate': logs.isEmpty
              ? 0.0
              : logs
                        .where((l) => l.status == MessageUsageStatus.success)
                        .length /
                    logs.length,
          'estimatedCost': logs.fold(
            0.0,
            (total, log) => total + log.estimatedCost,
          ),
        };

        // Calculate provider distribution
        for (final log in logs) {
          final provider = log.aiProvider;
          providerDistribution[provider] =
              (providerDistribution[provider] ?? 0) + 1;
        }

        return Right(analytics);
      });
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to get analytics: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> clearUsageCache(String userId) async {
    try {
      _statsCache.remove(userId);
      _quotaCache.remove(userId);
      _subscriptionCache.remove(userId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to clear cache: $e'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> exportUsageData({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final statsResult = await getUserStats(userId);
      final subscriptionResult = await getUserSubscription(userId);
      final historyResult = await getUsageHistory(
        userId: userId,
        startDate: startDate,
        endDate: endDate,
      );

      return statsResult.fold(
        (failure) => Left(failure),
        (stats) => subscriptionResult.fold(
          (failure) => Left(failure),
          (subscription) => historyResult.fold(
            (failure) => Left(failure),
            (history) => Right({
              'userId': userId,
              'exportDate': DateTime.now().toIso8601String(),
              'subscription': {
                'tier': subscription.currentTier,
                'startDate': subscription.subscriptionStart.toIso8601String(),
                'isActive': subscription.isActive,
              },
              'currentUsage': {
                'messagesThisMonth': stats.messagesThisMonth,
                'tokensThisMonth': stats.tokensThisMonth,
                'messagesThisDay': stats.messagesThisDay,
                'tokensThisDay': stats.tokensThisDay,
              },
              'history': history
                  .map(
                    (log) => {
                      'id': log.id,
                      'timestamp': log.timestamp.toIso8601String(),
                      'provider': log.aiProvider,
                      'tokens': log.totalTokens,
                      'status': log.status.toString(),
                    },
                  )
                  .toList(),
            }),
          ),
        ),
      );
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to export data: $e'));
    }
  }

  @override
  Future<Either<Failure, Map<String, int>>> getProviderUsage({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final statsResult = await getUserStats(userId);

      return statsResult.fold(
        (failure) => Left(failure),
        (stats) => Right(stats.providerUsage),
      );
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to get provider usage: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> checkRateLimit({
    required String userId,
    required String provider,
  }) async {
    try {
      // Simple rate limiting check (can be enhanced)
      const limits = {'gemini': 60, 'claude': 50, 'openai': 60};

      final limit = limits[provider.toLowerCase()] ?? 60;

      // Check recent messages in the last minute
      final now = DateTime.now();
      final oneMinuteAgo = now.subtract(const Duration(minutes: 1));

      final historyResult = await getUsageHistory(
        userId: userId,
        startDate: oneMinuteAgo,
        endDate: now,
        limit: limit + 1,
      );

      return historyResult.fold((failure) => Left(failure), (logs) {
        final providerLogs = logs.where((l) => l.aiProvider == provider).length;
        return Right(providerLogs < limit);
      });
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to check rate limit: $e'));
    }
  }

  @override
  Future<Either<Failure, double>> getEstimatedCost({
    required String userId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final historyResult = await getUsageHistory(
        userId: userId,
        startDate: startDate,
        endDate: endDate,
      );

      return historyResult.fold((failure) => Left(failure), (logs) {
        final cost = logs.fold(0.0, (total, log) => total + log.estimatedCost);
        return Right(cost);
      });
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to calculate cost: $e'));
    }
  }

  // Helper methods
  Future<void> _saveStats(UserUsageStats stats) async {
    await firestore
        .collection('users')
        .doc(stats.userId)
        .collection('usage')
        .doc('stats')
        .set(_statsToMap(stats), SetOptions(merge: true));
  }

  Future<void> _saveSubscription(UserSubscription subscription) async {
    await firestore
        .collection('users')
        .doc(subscription.userId)
        .collection('subscription')
        .doc('current')
        .set(_subscriptionToMap(subscription), SetOptions(merge: true));
  }

  UserUsageStats _parseUserStats(String userId, Map<String, dynamic> data) {
    return UserUsageStats(
      userId: userId,
      userTier: data['userTier'] ?? 'free',
      messagesThisMonth: data['messagesThisMonth'] ?? 0,
      tokensThisMonth: data['tokensThisMonth'] ?? 0,
      messagesThisDay: data['messagesThisDay'] ?? 0,
      tokensThisDay: data['tokensThisDay'] ?? 0,
      messagesThisHour: data['messagesThisHour'] ?? 0,
      lastMessageTime:
          (data['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      providerUsage: Map<String, int>.from(data['providerUsage'] ?? {}),
      statsResetDate:
          (data['statsResetDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  UserSubscription _parseSubscription(
    String userId,
    Map<String, dynamic> data,
  ) {
    return UserSubscription(
      userId: userId,
      currentTier: data['currentTier'] ?? 'free',
      subscriptionStart:
          (data['subscriptionStart'] as Timestamp?)?.toDate() ?? DateTime.now(),
      subscriptionEnd: (data['subscriptionEnd'] as Timestamp?)?.toDate(),
      isActive: data['isActive'] ?? true,
      tierLimits: Map<String, dynamic>.from(data['tierLimits'] ?? {}),
      nextBillingDate: (data['nextBillingDate'] as Timestamp?)?.toDate(),
      paymentMethod: data['paymentMethod'],
      monthlyPrice: data['monthlyPrice']?.toDouble(),
      currency: data['currency'],
      features: List<String>.from(data['features'] ?? []),
    );
  }

  MessageUsageLog _parseMessageLog(String id, Map<String, dynamic> data) {
    return MessageUsageLog(
      id: id,
      userId: data['userId'] ?? '',
      messageId: data['messageId'] ?? '',
      conversationId: data['conversationId'] ?? '',
      inputTokens: data['inputTokens'] ?? 0,
      outputTokens: data['outputTokens'] ?? 0,
      totalTokens: data['totalTokens'] ?? 0,
      aiProvider: data['aiProvider'] ?? '',
      status: MessageUsageStatus.values.firstWhere(
        (s) => s.toString() == data['status'],
        orElse: () => MessageUsageStatus.success,
      ),
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      responseTimeMs: data['responseTimeMs'] ?? 0,
      errorCode: data['errorCode'],
      errorMessage: data['errorMessage'],
      metadata: data['metadata'],
    );
  }

  Map<String, dynamic> _statsToMap(UserUsageStats stats) {
    return {
      'userTier': stats.userTier,
      'messagesThisMonth': stats.messagesThisMonth,
      'tokensThisMonth': stats.tokensThisMonth,
      'messagesThisDay': stats.messagesThisDay,
      'tokensThisDay': stats.tokensThisDay,
      'messagesThisHour': stats.messagesThisHour,
      'lastMessageTime': Timestamp.fromDate(stats.lastMessageTime),
      'providerUsage': stats.providerUsage,
      'statsResetDate': Timestamp.fromDate(stats.statsResetDate),
      'createdAt': Timestamp.fromDate(stats.createdAt),
      'updatedAt': Timestamp.fromDate(stats.updatedAt),
    };
  }

  Map<String, dynamic> _subscriptionToMap(UserSubscription subscription) {
    return {
      'currentTier': subscription.currentTier,
      'subscriptionStart': Timestamp.fromDate(subscription.subscriptionStart),
      'subscriptionEnd': subscription.subscriptionEnd != null
          ? Timestamp.fromDate(subscription.subscriptionEnd!)
          : null,
      'isActive': subscription.isActive,
      'tierLimits': subscription.tierLimits,
      'nextBillingDate': subscription.nextBillingDate != null
          ? Timestamp.fromDate(subscription.nextBillingDate!)
          : null,
      'paymentMethod': subscription.paymentMethod,
      'monthlyPrice': subscription.monthlyPrice,
      'currency': subscription.currency,
      'features': subscription.features,
    };
  }

  Map<String, dynamic> _messageLogToMap(MessageUsageLog log) {
    return {
      'userId': log.userId,
      'messageId': log.messageId,
      'conversationId': log.conversationId,
      'inputTokens': log.inputTokens,
      'outputTokens': log.outputTokens,
      'totalTokens': log.totalTokens,
      'aiProvider': log.aiProvider,
      'status': log.status.toString(),
      'timestamp': Timestamp.fromDate(log.timestamp),
      'responseTimeMs': log.responseTimeMs,
      'errorCode': log.errorCode,
      'errorMessage': log.errorMessage,
      'metadata': log.metadata,
    };
  }
}
