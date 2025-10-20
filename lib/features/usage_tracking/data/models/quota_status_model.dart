import '../../domain/entities/quota_status.dart';

/// Model class for QuotaStatus with JSON serialization
class QuotaStatusModel extends QuotaStatus {
  QuotaStatusModel({
    required super.userId,
    required super.tier,
    required super.dailyMessageLimit,
    required super.dailyMessagesUsed,
    required super.dailyTokenLimit,
    required super.dailyTokensUsed,
    required super.monthlyMessageLimit,
    required super.monthlyMessagesUsed,
    required super.monthlyTokenLimit,
    required super.monthlyTokensUsed,
    required String lastResetDate,
    required String nextResetDate,
    required super.isExceeded,
    super.warningMessage,
  }) : super(
         lastResetDate: DateTime.parse(lastResetDate),
         nextResetDate: DateTime.parse(nextResetDate),
       );

  /// Factory constructor for creating model from JSON
  factory QuotaStatusModel.fromJson(Map<String, dynamic> json) {
    return QuotaStatusModel(
      userId: json['userId'] as String,
      tier: json['tier'] as String,
      dailyMessageLimit: json['dailyMessageLimit'] as int? ?? 20,
      dailyMessagesUsed: json['dailyMessagesUsed'] as int? ?? 0,
      dailyTokenLimit: json['dailyTokenLimit'] as int? ?? 10000,
      dailyTokensUsed: json['dailyTokensUsed'] as int? ?? 0,
      monthlyMessageLimit: json['monthlyMessageLimit'] as int? ?? 600,
      monthlyMessagesUsed: json['monthlyMessagesUsed'] as int? ?? 0,
      monthlyTokenLimit: json['monthlyTokenLimit'] as int? ?? 300000,
      monthlyTokensUsed: json['monthlyTokensUsed'] as int? ?? 0,
      lastResetDate:
          json['lastResetDate'] as String? ?? DateTime.now().toIso8601String(),
      nextResetDate:
          json['nextResetDate'] as String? ??
          DateTime.now().add(const Duration(days: 1)).toIso8601String(),
      isExceeded: json['isExceeded'] as bool? ?? false,
      warningMessage: json['warningMessage'] as String?,
    );
  }

  /// Factory constructor for creating model from entity
  factory QuotaStatusModel.fromEntity(QuotaStatus entity) {
    return QuotaStatusModel(
      userId: entity.userId,
      tier: entity.tier,
      dailyMessageLimit: entity.dailyMessageLimit,
      dailyMessagesUsed: entity.dailyMessagesUsed,
      dailyTokenLimit: entity.dailyTokenLimit,
      dailyTokensUsed: entity.dailyTokensUsed,
      monthlyMessageLimit: entity.monthlyMessageLimit,
      monthlyMessagesUsed: entity.monthlyMessagesUsed,
      monthlyTokenLimit: entity.monthlyTokenLimit,
      monthlyTokensUsed: entity.monthlyTokensUsed,
      lastResetDate: entity.lastResetDate.toIso8601String(),
      nextResetDate: entity.nextResetDate.toIso8601String(),
      isExceeded: entity.isExceeded,
      warningMessage: entity.warningMessage,
    );
  }

  /// Convert model to JSON
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'tier': tier,
      'dailyMessageLimit': dailyMessageLimit,
      'dailyMessagesUsed': dailyMessagesUsed,
      'dailyTokenLimit': dailyTokenLimit,
      'dailyTokensUsed': dailyTokensUsed,
      'monthlyMessageLimit': monthlyMessageLimit,
      'monthlyMessagesUsed': monthlyMessagesUsed,
      'monthlyTokenLimit': monthlyTokenLimit,
      'monthlyTokensUsed': monthlyTokensUsed,
      'lastResetDate': lastResetDate.toIso8601String(),
      'nextResetDate': nextResetDate.toIso8601String(),
      'isExceeded': isExceeded,
      'warningMessage': warningMessage,
    };
  }
}
