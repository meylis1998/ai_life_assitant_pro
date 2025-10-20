import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/utils/logger.dart';
import '../../domain/entities/message_usage_log.dart';
import '../../domain/entities/quota_status.dart';
import '../../domain/entities/user_subscription.dart';
import '../../domain/entities/user_usage_stats.dart';
import '../../domain/repositories/usage_repository.dart';
import 'usage_event.dart';
import 'usage_state.dart';

class UsageBloc extends Bloc<UsageEvent, UsageState> {
  final UsageRepository _usageRepository;

  // Timers for auto-refresh
  Timer? _refreshTimer;
  Timer? _midnightTimer;
  Timer? _monthlyTimer;

  // Cache
  String? _currentUserId;
  DateTime? _lastRefresh;

  UsageBloc({required UsageRepository usageRepository})
    : _usageRepository = usageRepository,
      super(const UsageInitial()) {
    on<InitializeUsageTracking>(_onInitializeUsageTracking);
    on<CheckQuotaStatus>(_onCheckQuotaStatus);
    on<UpdateUsage>(_onUpdateUsage);
    on<LogMessageUsage>(_onLogMessageUsage);
    on<RefreshUsageStats>(_onRefreshUsageStats);
    on<CheckSubscription>(_onCheckSubscription);
    on<ResetDailyUsage>(_onResetDailyUsage);
    on<ResetMonthlyUsage>(_onResetMonthlyUsage);
    on<GetUsageAnalytics>(_onGetUsageAnalytics);
    on<UpgradeSubscription>(_onUpgradeSubscription);
    on<ExportUsageData>(_onExportUsageData);
  }

  Future<void> _onInitializeUsageTracking(
    InitializeUsageTracking event,
    Emitter<UsageState> emit,
  ) async {
    try {
      emit(
        UsageLoading(
          usageStats: state.usageStats,
          quotaStatus: state.quotaStatus,
          subscription: state.subscription,
        ),
      );

      _currentUserId = event.userId;

      // Get all data in parallel
      final results = await Future.wait([
        _usageRepository.getUserStats(event.userId),
        _usageRepository.getQuotaStatus(event.userId),
        _usageRepository.getUserSubscription(event.userId),
      ]);

      final statsResult = results[0];
      final quotaResult = results[1];
      final subscriptionResult = results[2];

      // Check if all succeeded
      if (statsResult.isRight() &&
          quotaResult.isRight() &&
          subscriptionResult.isRight()) {
        final stats = statsResult.fold((l) => null, (r) => r as UserUsageStats);
        final quota = quotaResult.fold((l) => null, (r) => r as QuotaStatus);
        final subscription = subscriptionResult.fold(
          (l) => null,
          (r) => r as UserSubscription,
        );

        if (stats != null && quota != null && subscription != null) {
          // Check if we should emit a warning
          if (quota.usagePercentage >= 80 && !quota.isExceeded) {
            emit(
              UsageWarning(
                warningMessage: quota.statusMessage,
                usagePercentage: quota.usagePercentage,
                messagesRemaining: quota.remainingMessages,
                tokensRemaining: quota.remainingTokens,
                resetTime: quota.nextResetDate,
                usageStats: stats,
                quotaStatus: quota,
                subscription: subscription,
              ),
            );
          } else if (quota.isExceeded) {
            emit(
              UsageExceeded(
                quotaType: quota.exceededType ?? 'daily',
                resetTime: quota.nextResetDate,
                upgradeSuggestion: subscription.currentTier == 'free'
                    ? 'Upgrade to Pro for 10x more messages!'
                    : subscription.currentTier == 'pro'
                    ? 'Upgrade to Premium for unlimited usage!'
                    : null,
                usageStats: stats,
                quotaStatus: quota,
                subscription: subscription,
              ),
            );
          } else {
            emit(
              UsageLoaded(
                usageStats: stats,
                quotaStatus: quota,
                subscription: subscription,
              ),
            );
          }

          // Setup auto-refresh
          _setupAutoRefresh();
          _setupResetTimers(stats);
          _lastRefresh = DateTime.now();
        }
      }
    } catch (e) {
      AppLogger.e('Error initializing usage tracking: $e');
      emit(
        UsageError(
          errorMessage: 'Failed to initialize usage tracking',
          errorCode: 'INIT_FAILED',
          usageStats: state.usageStats,
          quotaStatus: state.quotaStatus,
          subscription: state.subscription,
        ),
      );
    }
  }

  Future<void> _onCheckQuotaStatus(
    CheckQuotaStatus event,
    Emitter<UsageState> emit,
  ) async {
    try {
      final canUseResult = await _usageRepository.checkQuota(
        userId: event.userId,
        provider: event.provider ?? 'gemini',
        estimatedTokens: event.estimatedTokens ?? 100,
      );

      final quotaResult = await _usageRepository.getQuotaStatus(event.userId);

      canUseResult.fold(
        (failure) => emit(
          UsageError(
            errorMessage: failure.message,
            usageStats: state.usageStats,
            quotaStatus: state.quotaStatus,
            subscription: state.subscription,
          ),
        ),
        (canUse) {
          quotaResult.fold((failure) => null, (quota) {
            if (!canUse) {
              emit(
                UsageExceeded(
                  quotaType: quota.exceededType ?? 'daily',
                  resetTime: quota.nextResetDate,
                  upgradeSuggestion: state.subscription?.currentTier == 'free'
                      ? 'Upgrade to Pro for more messages!'
                      : null,
                  usageStats: state.usageStats!,
                  quotaStatus: quota,
                  subscription: state.subscription!,
                ),
              );
            } else if (quota.usagePercentage >= 80) {
              emit(
                UsageWarning(
                  warningMessage: quota.statusMessage,
                  usagePercentage: quota.usagePercentage,
                  messagesRemaining: quota.remainingMessages,
                  tokensRemaining: quota.remainingTokens,
                  resetTime: quota.nextResetDate,
                  usageStats: state.usageStats!,
                  quotaStatus: quota,
                  subscription: state.subscription!,
                ),
              );
            }
          });
        },
      );
    } catch (e) {
      AppLogger.e('Error checking quota status: $e');
    }
  }

  Future<void> _onUpdateUsage(
    UpdateUsage event,
    Emitter<UsageState> emit,
  ) async {
    try {
      // Update local cache immediately
      if (state.usageStats != null) {
        final updatedStats = state.usageStats!.copyWith(
          messagesThisDay:
              state.usageStats!.messagesThisDay + event.messageCount,
          tokensThisDay: state.usageStats!.tokensThisDay + event.tokenCount,
          messagesThisMonth:
              state.usageStats!.messagesThisMonth + event.messageCount,
          tokensThisMonth: state.usageStats!.tokensThisMonth + event.tokenCount,
          lastMessageTime: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Calculate remaining and estimated cost
        final limits = _getLimitsForTier(state.subscription?.currentTier ?? 'free');
        final messagesRemaining =
            limits['dailyMessages']! - updatedStats.messagesThisDay;
        final tokensRemaining =
            limits['dailyTokens']! - updatedStats.tokensThisDay;
        final usagePercentage =
            (updatedStats.messagesThisDay / limits['dailyMessages']!) * 100;

        // Estimate cost based on tokens (rough approximation)
        final estimatedCostToday = (updatedStats.tokensThisDay / 1000) * 0.001;

        emit(
          UsageUpdated(
            messagesUsedToday: updatedStats.messagesThisDay,
            tokensUsedToday: updatedStats.tokensThisDay,
            estimatedCostToday: estimatedCostToday,
            messagesRemaining: messagesRemaining.clamp(
              0,
              limits['dailyMessages']!,
            ),
            tokensRemaining: tokensRemaining.clamp(0, limits['dailyTokens']!),
            usagePercentage: usagePercentage.clamp(0, 100),
            usageStats: updatedStats,
            quotaStatus: state.quotaStatus!,
            subscription: state.subscription!,
          ),
        );

        // Update in repository
        await _usageRepository.updateUserStats(updatedStats);
      }
    } catch (e) {
      AppLogger.e('Error updating usage: $e');
    }
  }

  Future<void> _onLogMessageUsage(
    LogMessageUsage event,
    Emitter<UsageState> emit,
  ) async {
    try {
      final usageLog = MessageUsageLog.success(
        id: const Uuid().v4(),
        userId: event.userId,
        messageId: event.messageId,
        conversationId: event.conversationId,
        inputTokens: event.inputTokens,
        outputTokens: event.outputTokens,
        aiProvider: event.provider,
        responseTimeMs: event.responseTimeMs,
      );

      await _usageRepository.logMessageUsage(usageLog);

      // Update usage stats
      add(
        UpdateUsage(
          userId: event.userId,
          messageCount: 1,
          tokenCount: event.inputTokens + event.outputTokens,
          provider: event.provider,
          responseTimeMs: event.responseTimeMs,
        ),
      );
    } catch (e) {
      AppLogger.e('Error logging message usage: $e');
    }
  }

  Future<void> _onRefreshUsageStats(
    RefreshUsageStats event,
    Emitter<UsageState> emit,
  ) async {
    try {
      // Skip if refreshed recently (< 5 seconds)
      if (!event.forceRefresh &&
          _lastRefresh != null &&
          DateTime.now().difference(_lastRefresh!).inSeconds < 5) {
        return;
      }

      final statsResult = await _usageRepository.getUserStats(
        event.userId,
      );
      final quotaResult = await _usageRepository.getQuotaStatus(event.userId);

      if (statsResult.isRight() && quotaResult.isRight()) {
        final stats = statsResult.fold((l) => null, (r) => r);
        final quota = quotaResult.fold((l) => null, (r) => r);

        if (stats != null && quota != null) {
          if (state is UsageLoaded) {
            emit(
              (state as UsageLoaded).copyWith(
                usageStats: stats,
                quotaStatus: quota,
              ),
            );
          }
          _lastRefresh = DateTime.now();
        }
      }
    } catch (e) {
      AppLogger.e('Error refreshing usage stats: $e');
    }
  }

  Future<void> _onCheckSubscription(
    CheckSubscription event,
    Emitter<UsageState> emit,
  ) async {
    try {
      final result = await _usageRepository.getUserSubscription(event.userId);

      result.fold(
        (failure) => emit(
          UsageError(
            errorMessage: failure.message,
            usageStats: state.usageStats,
            quotaStatus: state.quotaStatus,
            subscription: state.subscription,
          ),
        ),
        (subscription) => emit(
          SubscriptionChecked(
            isActive: subscription.isActive,
            expiresAt: subscription.subscriptionEnd,
            currentTier: subscription.currentTier,
            availableProviders: _getProvidersForTier(subscription.currentTier),
            subscription: subscription,
            usageStats: state.usageStats,
            quotaStatus: state.quotaStatus,
          ),
        ),
      );
    } catch (e) {
      AppLogger.e('Error checking subscription: $e');
    }
  }

  Future<void> _onResetDailyUsage(
    ResetDailyUsage event,
    Emitter<UsageState> emit,
  ) async {
    try {
      if (state.usageStats != null) {
        final resetStats = state.usageStats!.copyWith(
          messagesThisDay: 0,
          tokensThisDay: 0,
          messagesThisHour: 0,
          updatedAt: DateTime.now(),
        );

        await _usageRepository.updateUserStats(resetStats);

        if (state is UsageLoaded) {
          emit((state as UsageLoaded).copyWith(usageStats: resetStats));
        }

        AppLogger.i('Daily usage reset for user ${event.userId}');
      }
    } catch (e) {
      AppLogger.e('Error resetting daily usage: $e');
    }
  }

  Future<void> _onResetMonthlyUsage(
    ResetMonthlyUsage event,
    Emitter<UsageState> emit,
  ) async {
    try {
      if (state.usageStats != null) {
        final resetStats = state.usageStats!.copyWith(
          messagesThisMonth: 0,
          tokensThisMonth: 0,
          messagesThisDay: 0,
          tokensThisDay: 0,
          messagesThisHour: 0,
          statsResetDate: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _usageRepository.updateUserStats(resetStats);

        if (state is UsageLoaded) {
          emit((state as UsageLoaded).copyWith(usageStats: resetStats));
        }

        AppLogger.i('Monthly usage reset for user ${event.userId}');
      }
    } catch (e) {
      AppLogger.e('Error resetting monthly usage: $e');
    }
  }

  Future<void> _onGetUsageAnalytics(
    GetUsageAnalytics event,
    Emitter<UsageState> emit,
  ) async {
    try {
      final result = await _usageRepository.getUsageHistory(
        userId: event.userId,
        startDate: event.startDate,
        endDate: event.endDate,
      );

      result.fold(
        (failure) => emit(
          UsageError(
            errorMessage: failure.message,
            usageStats: state.usageStats,
            quotaStatus: state.quotaStatus,
            subscription: state.subscription,
          ),
        ),
        (logs) {
          // Calculate analytics
          final analytics = _calculateAnalytics(logs);

          emit(
            UsageAnalyticsLoaded(
              analytics: analytics,
              recentUsage: logs,
              costBreakdown: analytics['costBreakdown'],
              providerUsage: analytics['providerUsage'],
              totalCost: analytics['totalCost'],
              totalMessages: analytics['totalMessages'],
              totalTokens: analytics['totalTokens'],
              usageStats: state.usageStats,
              quotaStatus: state.quotaStatus,
              subscription: state.subscription,
            ),
          );
        },
      );
    } catch (e) {
      AppLogger.e('Error getting usage analytics: $e');
    }
  }

  Future<void> _onUpgradeSubscription(
    UpgradeSubscription event,
    Emitter<UsageState> emit,
  ) async {
    try {
      // This would typically integrate with payment system
      // For now, we'll simulate the upgrade

      // Use the factory constructor for the appropriate tier
      final newSubscription = event.newTier.toLowerCase() == 'pro'
          ? UserSubscription.pro(
              event.userId,
              paymentMethod: event.paymentMethod,
            )
          : event.newTier.toLowerCase() == 'premium'
              ? UserSubscription.premium(
                  event.userId,
                  paymentMethod: event.paymentMethod,
                )
              : UserSubscription.free(event.userId);

      // Update subscription in repository
      final result = await _usageRepository.updateSubscription(newSubscription);

      result.fold(
        (failure) => emit(
          UsageError(
            errorMessage: failure.message,
            usageStats: state.usageStats,
            quotaStatus: state.quotaStatus,
            subscription: state.subscription,
          ),
        ),
        (_) {
          // Reset stats for new tier
          add(RefreshUsageStats(userId: event.userId, forceRefresh: true));

          emit(
            SubscriptionUpgraded(
              previousTier: state.subscription?.currentTier ?? 'free',
              newTier: event.newTier,
              upgradeDate: DateTime.now(),
              newLimits: _getLimitsForTier(event.newTier),
              subscription: newSubscription,
              usageStats: state.usageStats!,
              quotaStatus: state.quotaStatus!,
            ),
          );
        },
      );
    } catch (e) {
      AppLogger.e('Error upgrading subscription: $e');
    }
  }

  Future<void> _onExportUsageData(
    ExportUsageData event,
    Emitter<UsageState> emit,
  ) async {
    try {
      final result = await _usageRepository.getUsageHistory(
        userId: event.userId,
        startDate: event.startDate,
        endDate: event.endDate,
      );

      result.fold(
        (failure) => emit(
          UsageError(
            errorMessage: failure.message,
            usageStats: state.usageStats,
            quotaStatus: state.quotaStatus,
            subscription: state.subscription,
          ),
        ),
        (logs) {
          // Format and export data based on requested format
          final filePath = _exportData(logs, event.format);

          emit(
            UsageDataExported(
              filePath: filePath,
              format: event.format,
              recordCount: logs.length,
              exportDate: DateTime.now(),
              usageStats: state.usageStats,
              quotaStatus: state.quotaStatus,
              subscription: state.subscription,
            ),
          );
        },
      );
    } catch (e) {
      AppLogger.e('Error exporting usage data: $e');
    }
  }

  // Helper methods

  void _setupAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (_currentUserId != null) {
        add(RefreshUsageStats(userId: _currentUserId!));
      }
    });
  }

  void _setupResetTimers(UserUsageStats stats) {
    // Setup daily reset timer
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day + 1);
    final durationToMidnight = midnight.difference(now);

    _midnightTimer?.cancel();
    _midnightTimer = Timer(durationToMidnight, () {
      if (_currentUserId != null) {
        add(ResetDailyUsage(userId: _currentUserId!));
      }
      // Setup next timer
      _setupResetTimers(stats);
    });

    // Setup monthly reset timer
    final firstOfNextMonth = DateTime(
      now.month == 12 ? now.year + 1 : now.year,
      now.month == 12 ? 1 : now.month + 1,
      1,
    );
    final durationToFirstOfMonth = firstOfNextMonth.difference(now);

    _monthlyTimer?.cancel();
    _monthlyTimer = Timer(durationToFirstOfMonth, () {
      if (_currentUserId != null) {
        add(ResetMonthlyUsage(userId: _currentUserId!));
      }
    });
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

  List<String> _getProvidersForTier(String tier) {
    switch (tier.toLowerCase()) {
      case 'free':
        return ['gemini'];
      case 'pro':
        return ['gemini', 'claude', 'openai'];
      case 'premium':
        return ['gemini', 'claude', 'openai'];
      default:
        return ['gemini'];
    }
  }

  Map<String, dynamic> _calculateAnalytics(List<MessageUsageLog> logs) {
    final costBreakdown = <String, double>{};
    final providerUsage = <String, int>{};
    double totalCost = 0.0;
    int totalMessages = logs.length;
    int totalTokens = 0;

    for (final log in logs) {
      // Calculate cost per provider
      final cost = log.estimatedCost;
      costBreakdown[log.aiProvider] =
          (costBreakdown[log.aiProvider] ?? 0) + cost;
      totalCost += cost;

      // Count usage per provider
      providerUsage[log.aiProvider] = (providerUsage[log.aiProvider] ?? 0) + 1;

      // Sum tokens
      totalTokens += log.totalTokens;
    }

    return {
      'costBreakdown': costBreakdown,
      'providerUsage': providerUsage,
      'totalCost': totalCost,
      'totalMessages': totalMessages,
      'totalTokens': totalTokens,
      'averageResponseTime': logs.isEmpty
          ? 0
          : logs.map((l) => l.responseTimeMs).reduce((a, b) => a + b) ~/
                logs.length,
      'successRate': logs.isEmpty
          ? 100.0
          : (logs.where((l) => l.status == MessageUsageStatus.success).length / logs.length) *
                100,
    };
  }

  String _exportData(List<MessageUsageLog> logs, String format) {
    // This would be implemented based on format requirements
    // For now, return a placeholder path
    return '/storage/emulated/0/Download/usage_export_${DateTime.now().millisecondsSinceEpoch}.$format';
  }

  @override
  Future<void> close() {
    _refreshTimer?.cancel();
    _midnightTimer?.cancel();
    _monthlyTimer?.cancel();
    return super.close();
  }
}
