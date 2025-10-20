import 'package:equatable/equatable.dart';

/// Entity representing current quota status for a user
class QuotaStatus extends Equatable {
  final String userId;
  final String tier;
  final int dailyMessageLimit;
  final int dailyMessagesUsed;
  final int dailyTokenLimit;
  final int dailyTokensUsed;
  final int monthlyMessageLimit;
  final int monthlyMessagesUsed;
  final int monthlyTokenLimit;
  final int monthlyTokensUsed;
  final DateTime lastResetDate;
  final DateTime nextResetDate;
  final bool isExceeded;
  final String? warningMessage;

  const QuotaStatus({
    required this.userId,
    required this.tier,
    required this.dailyMessageLimit,
    required this.dailyMessagesUsed,
    required this.dailyTokenLimit,
    required this.dailyTokensUsed,
    required this.monthlyMessageLimit,
    required this.monthlyMessagesUsed,
    required this.monthlyTokenLimit,
    required this.monthlyTokensUsed,
    required this.lastResetDate,
    required this.nextResetDate,
    required this.isExceeded,
    this.warningMessage,
  });

  /// Factory constructor for different tiers
  factory QuotaStatus.forTier({
    required String userId,
    required String tier,
    required int dailyMessagesUsed,
    required int dailyTokensUsed,
    required int monthlyMessagesUsed,
    required int monthlyTokensUsed,
  }) {
    final limits = _getTierLimits(tier);
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);

    final isExceeded =
        dailyMessagesUsed >= limits['dailyMessages']! ||
        dailyTokensUsed >= limits['dailyTokens']! ||
        monthlyMessagesUsed >= limits['monthlyMessages']! ||
        monthlyTokensUsed >= limits['monthlyTokens']!;

    String? warningMessage;
    final dailyMessagePercent =
        (dailyMessagesUsed / limits['dailyMessages']!) * 100;
    final dailyTokenPercent = (dailyTokensUsed / limits['dailyTokens']!) * 100;

    if (dailyMessagePercent >= 90 || dailyTokenPercent >= 90) {
      warningMessage = 'You are approaching your daily limit';
    } else if (dailyMessagePercent >= 80 || dailyTokenPercent >= 80) {
      warningMessage = 'You have used over 80% of your daily quota';
    }

    return QuotaStatus(
      userId: userId,
      tier: tier,
      dailyMessageLimit: limits['dailyMessages']!,
      dailyMessagesUsed: dailyMessagesUsed,
      dailyTokenLimit: limits['dailyTokens']!,
      dailyTokensUsed: dailyTokensUsed,
      monthlyMessageLimit: limits['monthlyMessages']!,
      monthlyMessagesUsed: monthlyMessagesUsed,
      monthlyTokenLimit: limits['monthlyTokens']!,
      monthlyTokensUsed: monthlyTokensUsed,
      lastResetDate: now,
      nextResetDate: tomorrow,
      isExceeded: isExceeded,
      warningMessage: warningMessage,
    );
  }

  static Map<String, int> _getTierLimits(String tier) {
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
          'dailyTokens': 99999999,
          'monthlyMessages': 999999,
          'monthlyTokens': 99999999,
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

  /// Get percentage of daily message usage
  double get dailyMessageUsagePercent =>
      dailyMessageLimit > 0 ? (dailyMessagesUsed / dailyMessageLimit) * 100 : 0;

  /// Get percentage of daily token usage
  double get dailyTokenUsagePercent =>
      dailyTokenLimit > 0 ? (dailyTokensUsed / dailyTokenLimit) * 100 : 0;

  /// Get percentage of monthly message usage
  double get monthlyMessageUsagePercent => monthlyMessageLimit > 0
      ? (monthlyMessagesUsed / monthlyMessageLimit) * 100
      : 0;

  /// Get percentage of monthly token usage
  double get monthlyTokenUsagePercent =>
      monthlyTokenLimit > 0 ? (monthlyTokensUsed / monthlyTokenLimit) * 100 : 0;

  /// Check if user can send another message
  bool canSendMessage({int estimatedTokens = 500}) {
    if (tier.toLowerCase() == 'premium') return true;

    return dailyMessagesUsed < dailyMessageLimit &&
        dailyTokensUsed + estimatedTokens <= dailyTokenLimit &&
        monthlyMessagesUsed < monthlyMessageLimit &&
        monthlyTokensUsed + estimatedTokens <= monthlyTokenLimit;
  }

  /// Get time until next reset
  Duration get timeUntilReset {
    final now = DateTime.now();
    return nextResetDate.difference(now);
  }

  /// Get formatted time until reset
  String get formattedTimeUntilReset {
    final duration = timeUntilReset;
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m';
    } else {
      return 'Less than a minute';
    }
  }

  /// Get remaining daily messages
  int get remainingDailyMessages =>
      (dailyMessageLimit - dailyMessagesUsed).clamp(0, dailyMessageLimit);

  /// Get remaining daily tokens
  int get remainingDailyTokens =>
      (dailyTokenLimit - dailyTokensUsed).clamp(0, dailyTokenLimit);

  // Compatibility getters for different naming conventions
  int get remainingMessages => remainingDailyMessages;
  int get remainingTokens => remainingDailyTokens;
  int? get messagesUsedToday => dailyMessagesUsed;
  int? get tokensUsedToday => dailyTokensUsed;
  double get usagePercentage => dailyMessageUsagePercent;
  String? get exceededType {
    if (!isExceeded) return null;
    if (dailyMessagesUsed >= dailyMessageLimit) return 'messages';
    if (dailyTokensUsed >= dailyTokenLimit) return 'tokens';
    return 'daily';
  }

  /// Get user-friendly message about quota status
  String get statusMessage {
    if (isExceeded) {
      if (tier.toLowerCase() == 'free') {
        return 'Daily limit reached. Upgrade to Pro for more messages or wait $formattedTimeUntilReset';
      } else {
        return 'Daily limit reached. Reset in $formattedTimeUntilReset';
      }
    } else if (warningMessage != null) {
      return warningMessage!;
    } else {
      return '$remainingDailyMessages messages remaining today';
    }
  }

  /// Copy with updated values
  QuotaStatus copyWith({
    String? userId,
    String? tier,
    int? dailyMessageLimit,
    int? dailyMessagesUsed,
    int? dailyTokenLimit,
    int? dailyTokensUsed,
    int? monthlyMessageLimit,
    int? monthlyMessagesUsed,
    int? monthlyTokenLimit,
    int? monthlyTokensUsed,
    DateTime? lastResetDate,
    DateTime? nextResetDate,
    bool? isExceeded,
    String? warningMessage,
  }) {
    return QuotaStatus(
      userId: userId ?? this.userId,
      tier: tier ?? this.tier,
      dailyMessageLimit: dailyMessageLimit ?? this.dailyMessageLimit,
      dailyMessagesUsed: dailyMessagesUsed ?? this.dailyMessagesUsed,
      dailyTokenLimit: dailyTokenLimit ?? this.dailyTokenLimit,
      dailyTokensUsed: dailyTokensUsed ?? this.dailyTokensUsed,
      monthlyMessageLimit: monthlyMessageLimit ?? this.monthlyMessageLimit,
      monthlyMessagesUsed: monthlyMessagesUsed ?? this.monthlyMessagesUsed,
      monthlyTokenLimit: monthlyTokenLimit ?? this.monthlyTokenLimit,
      monthlyTokensUsed: monthlyTokensUsed ?? this.monthlyTokensUsed,
      lastResetDate: lastResetDate ?? this.lastResetDate,
      nextResetDate: nextResetDate ?? this.nextResetDate,
      isExceeded: isExceeded ?? this.isExceeded,
      warningMessage: warningMessage ?? this.warningMessage,
    );
  }

  @override
  List<Object?> get props => [
    userId,
    tier,
    dailyMessageLimit,
    dailyMessagesUsed,
    dailyTokenLimit,
    dailyTokensUsed,
    monthlyMessageLimit,
    monthlyMessagesUsed,
    monthlyTokenLimit,
    monthlyTokensUsed,
    lastResetDate,
    nextResetDate,
    isExceeded,
    warningMessage,
  ];
}
