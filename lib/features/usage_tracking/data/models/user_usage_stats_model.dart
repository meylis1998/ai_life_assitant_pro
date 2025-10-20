import '../../domain/entities/user_usage_stats.dart';

/// Model class for UserUsageStats with JSON serialization
class UserUsageStatsModel extends UserUsageStats {
  UserUsageStatsModel({
    required super.userId,
    required super.userTier,
    required super.messagesThisMonth,
    required super.tokensThisMonth,
    required super.messagesThisDay,
    required super.tokensThisDay,
    required super.messagesThisHour,
    required String lastMessageTime,
    required Map<String, dynamic> providerUsage,
    required String statsResetDate,
    required String createdAt,
    required String updatedAt,
  }) : super(
         lastMessageTime: DateTime.parse(lastMessageTime),
         providerUsage: providerUsage.cast<String, int>(),
         statsResetDate: DateTime.parse(statsResetDate),
         createdAt: DateTime.parse(createdAt),
         updatedAt: DateTime.parse(updatedAt),
       );

  /// Factory constructor for creating model from JSON
  factory UserUsageStatsModel.fromJson(Map<String, dynamic> json) {
    return UserUsageStatsModel(
      userId: json['userId'] as String,
      userTier: json['userTier'] as String? ?? 'free',
      messagesThisMonth: json['messagesThisMonth'] as int? ?? 0,
      tokensThisMonth: json['tokensThisMonth'] as int? ?? 0,
      messagesThisDay: json['messagesThisDay'] as int? ?? 0,
      tokensThisDay: json['tokensThisDay'] as int? ?? 0,
      messagesThisHour: json['messagesThisHour'] as int? ?? 0,
      lastMessageTime:
          json['lastMessageTime'] as String? ?? DateTime.now().toIso8601String(),
      providerUsage: json['providerUsage'] as Map<String, dynamic>? ?? {},
      statsResetDate:
          json['statsResetDate'] as String? ?? DateTime.now().toIso8601String(),
      createdAt:
          json['createdAt'] as String? ?? DateTime.now().toIso8601String(),
      updatedAt:
          json['updatedAt'] as String? ?? DateTime.now().toIso8601String(),
    );
  }

  /// Factory constructor for creating model from entity
  factory UserUsageStatsModel.fromEntity(UserUsageStats entity) {
    return UserUsageStatsModel(
      userId: entity.userId,
      userTier: entity.userTier,
      messagesThisMonth: entity.messagesThisMonth,
      tokensThisMonth: entity.tokensThisMonth,
      messagesThisDay: entity.messagesThisDay,
      tokensThisDay: entity.tokensThisDay,
      messagesThisHour: entity.messagesThisHour,
      lastMessageTime: entity.lastMessageTime.toIso8601String(),
      providerUsage: entity.providerUsage,
      statsResetDate: entity.statsResetDate.toIso8601String(),
      createdAt: entity.createdAt.toIso8601String(),
      updatedAt: entity.updatedAt.toIso8601String(),
    );
  }

  /// Convert model to JSON
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userTier': userTier,
      'messagesThisMonth': messagesThisMonth,
      'tokensThisMonth': tokensThisMonth,
      'messagesThisDay': messagesThisDay,
      'tokensThisDay': tokensThisDay,
      'messagesThisHour': messagesThisHour,
      'lastMessageTime': lastMessageTime.toIso8601String(),
      'providerUsage': providerUsage,
      'statsResetDate': statsResetDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
