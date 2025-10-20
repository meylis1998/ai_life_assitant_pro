import '../../domain/entities/user_subscription.dart';

/// Model class for UserSubscription with JSON serialization
class UserSubscriptionModel extends UserSubscription {
  UserSubscriptionModel({
    required super.userId,
    required String tier,
    required String startDate,
    String? endDate,
    required super.isActive,
    super.paymentMethod,
    super.monthlyPrice,
    super.currency,
    List<String>? features,
    Map<String, dynamic>? tierLimits,
  }) : super(
         currentTier: tier,
         subscriptionStart: DateTime.parse(startDate),
         subscriptionEnd: endDate != null ? DateTime.parse(endDate) : null,
         tierLimits: tierLimits ?? {},
         features: features ?? [],
       );

  /// Factory constructor for creating model from JSON
  factory UserSubscriptionModel.fromJson(Map<String, dynamic> json) {
    return UserSubscriptionModel(
      userId: json['userId'] as String,
      tier: json['tier'] as String? ?? 'free',
      startDate:
          json['startDate'] as String? ?? DateTime.now().toIso8601String(),
      endDate: json['endDate'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      paymentMethod: json['paymentMethod'] as String?,
      monthlyPrice: json['monthlyPrice'] as double?,
      currency: json['currency'] as String?,
      features: (json['features'] as List<dynamic>?)?.cast<String>(),
      tierLimits: json['tierLimits'] as Map<String, dynamic>?,
    );
  }

  /// Factory constructor for creating model from entity
  factory UserSubscriptionModel.fromEntity(UserSubscription entity) {
    return UserSubscriptionModel(
      userId: entity.userId,
      tier: entity.currentTier,
      startDate: entity.subscriptionStart.toIso8601String(),
      endDate: entity.subscriptionEnd?.toIso8601String(),
      isActive: entity.isActive,
      paymentMethod: entity.paymentMethod,
      monthlyPrice: entity.monthlyPrice,
      currency: entity.currency,
      features: entity.features,
      tierLimits: entity.tierLimits,
    );
  }

  /// Convert model to JSON
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'tier': currentTier,
      'startDate': subscriptionStart.toIso8601String(),
      'endDate': subscriptionEnd?.toIso8601String(),
      'isActive': isActive,
      'paymentMethod': paymentMethod,
      'monthlyPrice': monthlyPrice,
      'currency': currency,
      'features': features,
      'tierLimits': tierLimits,
    };
  }
}
