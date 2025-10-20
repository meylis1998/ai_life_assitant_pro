import '../../domain/entities/message_usage_log.dart';

/// Model class for MessageUsageLog with JSON serialization
class MessageUsageLogModel extends MessageUsageLog {
  MessageUsageLogModel({
    required super.id,
    required super.userId,
    required super.messageId,
    required super.conversationId,
    required super.inputTokens,
    required super.outputTokens,
    required super.totalTokens,
    required super.aiProvider,
    required super.responseTimeMs,
    required String status,
    super.errorCode,
    super.errorMessage,
    required String timestamp,
    super.metadata,
  }) : super(
         status: _parseStatus(status),
         timestamp: DateTime.parse(timestamp),
       );

  /// Helper to parse status from string
  static MessageUsageStatus _parseStatus(String status) {
    switch (status.toLowerCase()) {
      case 'success':
        return MessageUsageStatus.success;
      case 'failed':
        return MessageUsageStatus.failed;
      case 'quotaexceeded':
      case 'quota_exceeded':
        return MessageUsageStatus.quotaExceeded;
      case 'ratelimited':
      case 'rate_limited':
        return MessageUsageStatus.rateLimited;
      case 'cancelled':
        return MessageUsageStatus.cancelled;
      case 'timeout':
        return MessageUsageStatus.timeout;
      default:
        return MessageUsageStatus.success;
    }
  }

  /// Factory constructor for creating model from JSON
  factory MessageUsageLogModel.fromJson(Map<String, dynamic> json) {
    return MessageUsageLogModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      messageId: json['messageId'] as String,
      conversationId: json['conversationId'] as String,
      inputTokens: json['inputTokens'] as int? ?? 0,
      outputTokens: json['outputTokens'] as int? ?? 0,
      totalTokens: json['totalTokens'] as int? ?? 0,
      aiProvider: json['aiProvider'] as String,
      responseTimeMs: json['responseTimeMs'] as int? ?? 0,
      status: json['status'] as String? ?? 'success',
      errorCode: json['errorCode'] as String?,
      errorMessage: json['errorMessage'] as String?,
      timestamp:
          json['timestamp'] as String? ?? DateTime.now().toIso8601String(),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Factory constructor for creating model from entity
  factory MessageUsageLogModel.fromEntity(MessageUsageLog entity) {
    return MessageUsageLogModel(
      id: entity.id,
      userId: entity.userId,
      messageId: entity.messageId,
      conversationId: entity.conversationId,
      inputTokens: entity.inputTokens,
      outputTokens: entity.outputTokens,
      totalTokens: entity.totalTokens,
      aiProvider: entity.aiProvider,
      responseTimeMs: entity.responseTimeMs,
      status: entity.status.name,
      errorCode: entity.errorCode,
      errorMessage: entity.errorMessage,
      timestamp: entity.timestamp.toIso8601String(),
      metadata: entity.metadata,
    );
  }

  /// Convert model to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'messageId': messageId,
      'conversationId': conversationId,
      'inputTokens': inputTokens,
      'outputTokens': outputTokens,
      'totalTokens': totalTokens,
      'aiProvider': aiProvider,
      'responseTimeMs': responseTimeMs,
      'status': status.name,
      'errorCode': errorCode,
      'errorMessage': errorMessage,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }
}
