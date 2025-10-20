import 'package:equatable/equatable.dart';

/// Entity representing user's usage statistics
class UserUsageStats extends Equatable {
  final String userId;
  final String userTier; // free, pro, premium
  final int messagesThisMonth;
  final int tokensThisMonth;
  final int messagesThisDay;
  final int tokensThisDay;
  final int messagesThisHour;
  final DateTime lastMessageTime;
  final Map<String, int> providerUsage; // e.g., gemini: 50, claude: 20
  final DateTime statsResetDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserUsageStats({
    required this.userId,
    required this.userTier,
    required this.messagesThisMonth,
    required this.tokensThisMonth,
    required this.messagesThisDay,
    required this.tokensThisDay,
    required this.messagesThisHour,
    required this.lastMessageTime,
    required this.providerUsage,
    required this.statsResetDate,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create empty stats for a new user
  factory UserUsageStats.empty(String userId) {
    final now = DateTime.now();
    return UserUsageStats(
      userId: userId,
      userTier: 'free',
      messagesThisMonth: 0,
      tokensThisMonth: 0,
      messagesThisDay: 0,
      tokensThisDay: 0,
      messagesThisHour: 0,
      lastMessageTime: now,
      providerUsage: {},
      statsResetDate: now,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Check if daily limit is exceeded based on tier
  bool isDailyLimitExceeded() {
    switch (userTier.toLowerCase()) {
      case 'free':
        return messagesThisDay >= 20 || tokensThisDay >= 10000;
      case 'pro':
        return messagesThisDay >= 200 || tokensThisDay >= 100000;
      case 'premium':
        return false; // Unlimited
      default:
        return messagesThisDay >= 20; // Default to free tier
    }
  }

  /// Check if monthly limit is exceeded based on tier
  bool isMonthlyLimitExceeded() {
    switch (userTier.toLowerCase()) {
      case 'free':
        return messagesThisMonth >= 600 || tokensThisMonth >= 300000;
      case 'pro':
        return messagesThisMonth >= 6000 || tokensThisMonth >= 3000000;
      case 'premium':
        return false; // Unlimited
      default:
        return messagesThisMonth >= 600; // Default to free tier
    }
  }

  /// Get remaining daily messages
  int getRemainingDailyMessages() {
    switch (userTier.toLowerCase()) {
      case 'free':
        return (20 - messagesThisDay).clamp(0, 20);
      case 'pro':
        return (200 - messagesThisDay).clamp(0, 200);
      case 'premium':
        return 999999; // Unlimited
      default:
        return (20 - messagesThisDay).clamp(0, 20);
    }
  }

  /// Get remaining daily tokens
  int getRemainingDailyTokens() {
    switch (userTier.toLowerCase()) {
      case 'free':
        return (10000 - tokensThisDay).clamp(0, 10000);
      case 'pro':
        return (100000 - tokensThisDay).clamp(0, 100000);
      case 'premium':
        return 999999999; // Unlimited
      default:
        return (10000 - tokensThisDay).clamp(0, 10000);
    }
  }

  /// Check if stats need to be reset (daily/monthly)
  bool needsDailyReset() {
    final now = DateTime.now();
    return now.day != lastMessageTime.day ||
        now.month != lastMessageTime.month ||
        now.year != lastMessageTime.year;
  }

  bool needsMonthlyReset() {
    final now = DateTime.now();
    return now.month != lastMessageTime.month ||
        now.year != lastMessageTime.year;
  }

  /// Copy with updated values
  UserUsageStats copyWith({
    String? userId,
    String? userTier,
    int? messagesThisMonth,
    int? tokensThisMonth,
    int? messagesThisDay,
    int? tokensThisDay,
    int? messagesThisHour,
    DateTime? lastMessageTime,
    Map<String, int>? providerUsage,
    DateTime? statsResetDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserUsageStats(
      userId: userId ?? this.userId,
      userTier: userTier ?? this.userTier,
      messagesThisMonth: messagesThisMonth ?? this.messagesThisMonth,
      tokensThisMonth: tokensThisMonth ?? this.tokensThisMonth,
      messagesThisDay: messagesThisDay ?? this.messagesThisDay,
      tokensThisDay: tokensThisDay ?? this.tokensThisDay,
      messagesThisHour: messagesThisHour ?? this.messagesThisHour,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      providerUsage: providerUsage ?? this.providerUsage,
      statsResetDate: statsResetDate ?? this.statsResetDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    userId,
    userTier,
    messagesThisMonth,
    tokensThisMonth,
    messagesThisDay,
    tokensThisDay,
    messagesThisHour,
    lastMessageTime,
    providerUsage,
    statsResetDate,
    createdAt,
    updatedAt,
  ];
}
