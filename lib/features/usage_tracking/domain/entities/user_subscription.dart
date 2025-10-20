import 'package:equatable/equatable.dart';

/// Entity representing user's subscription details
class UserSubscription extends Equatable {
  final String userId;
  final String currentTier; // free, pro, premium
  final DateTime subscriptionStart;
  final DateTime? subscriptionEnd;
  final bool isActive;
  final Map<String, dynamic> tierLimits;
  final DateTime? nextBillingDate;
  final String? paymentMethod;
  final double? monthlyPrice;
  final String? currency;
  final List<String> features;

  const UserSubscription({
    required this.userId,
    required this.currentTier,
    required this.subscriptionStart,
    this.subscriptionEnd,
    required this.isActive,
    required this.tierLimits,
    this.nextBillingDate,
    this.paymentMethod,
    this.monthlyPrice,
    this.currency,
    required this.features,
  });

  /// Factory constructor for free tier
  factory UserSubscription.free(String userId) {
    return UserSubscription(
      userId: userId,
      currentTier: 'free',
      subscriptionStart: DateTime.now(),
      subscriptionEnd: null,
      isActive: true,
      tierLimits: {
        'daily_messages': 20,
        'daily_tokens': 10000,
        'monthly_messages': 600,
        'monthly_tokens': 300000,
        'providers': ['gemini'],
        'priority_queue': false,
        'advanced_features': false,
      },
      nextBillingDate: null,
      paymentMethod: null,
      monthlyPrice: 0.0,
      currency: 'USD',
      features: [
        'Basic AI chat with Gemini',
        '20 messages per day',
        '10,000 tokens per day',
        'Conversation history',
        'Basic support',
      ],
    );
  }

  /// Factory constructor for pro tier
  factory UserSubscription.pro(
    String userId, {
    DateTime? startDate,
    String? paymentMethod,
  }) {
    final start = startDate ?? DateTime.now();
    return UserSubscription(
      userId: userId,
      currentTier: 'pro',
      subscriptionStart: start,
      subscriptionEnd: null,
      isActive: true,
      tierLimits: {
        'daily_messages': 200,
        'daily_tokens': 100000,
        'monthly_messages': 6000,
        'monthly_tokens': 3000000,
        'providers': ['gemini', 'claude', 'openai'],
        'priority_queue': true,
        'advanced_features': true,
      },
      nextBillingDate: DateTime(start.year, start.month + 1, start.day),
      paymentMethod: paymentMethod,
      monthlyPrice: 9.99,
      currency: 'USD',
      features: [
        'All AI providers (Gemini, Claude, OpenAI)',
        '200 messages per day',
        '100,000 tokens per day',
        'Priority processing',
        'Advanced features',
        'Export conversations',
        'Priority support',
      ],
    );
  }

  /// Factory constructor for premium tier
  factory UserSubscription.premium(
    String userId, {
    DateTime? startDate,
    String? paymentMethod,
  }) {
    final start = startDate ?? DateTime.now();
    return UserSubscription(
      userId: userId,
      currentTier: 'premium',
      subscriptionStart: start,
      subscriptionEnd: null,
      isActive: true,
      tierLimits: {
        'daily_messages': 999999,
        'daily_tokens': 99999999,
        'monthly_messages': 999999,
        'monthly_tokens': 99999999,
        'providers': ['gemini', 'claude', 'openai'],
        'priority_queue': true,
        'advanced_features': true,
        'unlimited': true,
      },
      nextBillingDate: DateTime(start.year, start.month + 1, start.day),
      paymentMethod: paymentMethod,
      monthlyPrice: 29.99,
      currency: 'USD',
      features: [
        'Unlimited messages',
        'Unlimited tokens',
        'All AI providers',
        'Highest priority processing',
        'Advanced analytics',
        'API access',
        'Custom integrations',
        'Dedicated support',
      ],
    );
  }

  /// Check if subscription has expired
  bool get isExpired {
    if (subscriptionEnd == null) return false;
    return DateTime.now().isAfter(subscriptionEnd!);
  }

  /// Check if subscription needs renewal
  bool get needsRenewal {
    if (currentTier == 'free') return false;
    if (nextBillingDate == null) return false;

    final daysUntilBilling = nextBillingDate!.difference(DateTime.now()).inDays;
    return daysUntilBilling <= 3; // Warning 3 days before
  }

  /// Check if user can use a specific provider
  bool canUseProvider(String provider) {
    final allowedProviders = tierLimits['providers'] as List<String>?;
    if (allowedProviders == null) return false;
    return allowedProviders.contains(provider.toLowerCase());
  }

  /// Get daily message limit
  int get dailyMessageLimit {
    return tierLimits['daily_messages'] as int? ?? 20;
  }

  /// Get daily token limit
  int get dailyTokenLimit {
    return tierLimits['daily_tokens'] as int? ?? 10000;
  }

  /// Get monthly message limit
  int get monthlyMessageLimit {
    return tierLimits['monthly_messages'] as int? ?? 600;
  }

  /// Get monthly token limit
  int get monthlyTokenLimit {
    return tierLimits['monthly_tokens'] as int? ?? 300000;
  }

  /// Check if user has priority queue
  bool get hasPriorityQueue {
    return tierLimits['priority_queue'] as bool? ?? false;
  }

  /// Check if user has advanced features
  bool get hasAdvancedFeatures {
    return tierLimits['advanced_features'] as bool? ?? false;
  }

  /// Get tier display name
  String get tierDisplayName {
    switch (currentTier.toLowerCase()) {
      case 'free':
        return 'Free';
      case 'pro':
        return 'Pro';
      case 'premium':
        return 'Premium';
      default:
        return 'Free';
    }
  }

  /// Get tier color for UI
  String get tierColorHex {
    switch (currentTier.toLowerCase()) {
      case 'free':
        return '#9E9E9E'; // Grey
      case 'pro':
        return '#2196F3'; // Blue
      case 'premium':
        return '#FFD700'; // Gold
      default:
        return '#9E9E9E';
    }
  }

  /// Get upgrade suggestion
  String? get upgradeSuggestion {
    switch (currentTier.toLowerCase()) {
      case 'free':
        return 'Upgrade to Pro for 10x more messages and all AI providers';
      case 'pro':
        return 'Upgrade to Premium for unlimited usage';
      case 'premium':
        return null;
      default:
        return 'Upgrade to Pro for more features';
    }
  }

  /// Copy with updated values
  UserSubscription copyWith({
    String? userId,
    String? currentTier,
    DateTime? subscriptionStart,
    DateTime? subscriptionEnd,
    bool? isActive,
    Map<String, dynamic>? tierLimits,
    DateTime? nextBillingDate,
    String? paymentMethod,
    double? monthlyPrice,
    String? currency,
    List<String>? features,
  }) {
    return UserSubscription(
      userId: userId ?? this.userId,
      currentTier: currentTier ?? this.currentTier,
      subscriptionStart: subscriptionStart ?? this.subscriptionStart,
      subscriptionEnd: subscriptionEnd ?? this.subscriptionEnd,
      isActive: isActive ?? this.isActive,
      tierLimits: tierLimits ?? this.tierLimits,
      nextBillingDate: nextBillingDate ?? this.nextBillingDate,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      monthlyPrice: monthlyPrice ?? this.monthlyPrice,
      currency: currency ?? this.currency,
      features: features ?? this.features,
    );
  }

  @override
  List<Object?> get props => [
    userId,
    currentTier,
    subscriptionStart,
    subscriptionEnd,
    isActive,
    tierLimits,
    nextBillingDate,
    paymentMethod,
    monthlyPrice,
    currency,
    features,
  ];
}
