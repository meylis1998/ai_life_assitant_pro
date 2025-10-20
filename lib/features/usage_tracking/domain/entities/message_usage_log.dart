import 'package:equatable/equatable.dart';

/// Entity representing usage log for a single message
class MessageUsageLog extends Equatable {
  final String id;
  final String userId;
  final String messageId;
  final String conversationId;
  final int inputTokens;
  final int outputTokens;
  final int totalTokens;
  final String aiProvider;
  final MessageUsageStatus status;
  final DateTime timestamp;
  final int responseTimeMs;
  final String? errorCode;
  final String? errorMessage;
  final Map<String, dynamic>? metadata;

  const MessageUsageLog({
    required this.id,
    required this.userId,
    required this.messageId,
    required this.conversationId,
    required this.inputTokens,
    required this.outputTokens,
    required this.totalTokens,
    required this.aiProvider,
    required this.status,
    required this.timestamp,
    required this.responseTimeMs,
    this.errorCode,
    this.errorMessage,
    this.metadata,
  });

  /// Factory constructor for successful message
  factory MessageUsageLog.success({
    required String id,
    required String userId,
    required String messageId,
    required String conversationId,
    required int inputTokens,
    required int outputTokens,
    required String aiProvider,
    required int responseTimeMs,
    Map<String, dynamic>? metadata,
  }) {
    return MessageUsageLog(
      id: id,
      userId: userId,
      messageId: messageId,
      conversationId: conversationId,
      inputTokens: inputTokens,
      outputTokens: outputTokens,
      totalTokens: inputTokens + outputTokens,
      aiProvider: aiProvider,
      status: MessageUsageStatus.success,
      timestamp: DateTime.now(),
      responseTimeMs: responseTimeMs,
      metadata: metadata,
    );
  }

  /// Factory constructor for failed message
  factory MessageUsageLog.failure({
    required String id,
    required String userId,
    required String messageId,
    required String conversationId,
    required String aiProvider,
    required String errorCode,
    required String errorMessage,
    int inputTokens = 0,
    int responseTimeMs = 0,
  }) {
    return MessageUsageLog(
      id: id,
      userId: userId,
      messageId: messageId,
      conversationId: conversationId,
      inputTokens: inputTokens,
      outputTokens: 0,
      totalTokens: inputTokens,
      aiProvider: aiProvider,
      status: MessageUsageStatus.failed,
      timestamp: DateTime.now(),
      responseTimeMs: responseTimeMs,
      errorCode: errorCode,
      errorMessage: errorMessage,
    );
  }

  /// Factory constructor for quota exceeded
  factory MessageUsageLog.quotaExceeded({
    required String id,
    required String userId,
    required String messageId,
    required String conversationId,
    required String aiProvider,
    required String quotaType,
  }) {
    return MessageUsageLog(
      id: id,
      userId: userId,
      messageId: messageId,
      conversationId: conversationId,
      inputTokens: 0,
      outputTokens: 0,
      totalTokens: 0,
      aiProvider: aiProvider,
      status: MessageUsageStatus.quotaExceeded,
      timestamp: DateTime.now(),
      responseTimeMs: 0,
      errorCode: 'QUOTA_EXCEEDED',
      errorMessage: 'User quota exceeded: $quotaType',
      metadata: {'quotaType': quotaType},
    );
  }

  /// Get cost estimate based on provider and tokens
  double get estimatedCost {
    // Approximate costs per 1K tokens (in USD)
    final costPer1kTokens = {
      'gemini': 0.0001, // Gemini Pro pricing
      'claude': 0.008, // Claude 3 pricing
      'openai': 0.002, // GPT-4 pricing
    };

    final rate = costPer1kTokens[aiProvider.toLowerCase()] ?? 0.001;
    return (totalTokens / 1000) * rate;
  }

  /// Get response speed category
  String get responseSpeed {
    if (responseTimeMs < 1000) return 'fast';
    if (responseTimeMs < 3000) return 'normal';
    if (responseTimeMs < 5000) return 'slow';
    return 'very slow';
  }

  /// Check if this was a streaming response
  bool get isStreaming {
    return metadata?['streaming'] == true;
  }

  /// Get formatted timestamp
  String get formattedTimestamp {
    final hour = timestamp.hour.toString().padLeft(2, '0');
    final minute = timestamp.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Get token efficiency (output/input ratio)
  double get tokenEfficiency {
    if (inputTokens == 0) return 0;
    return outputTokens / inputTokens;
  }

  /// Copy with updated values
  MessageUsageLog copyWith({
    String? id,
    String? userId,
    String? messageId,
    String? conversationId,
    int? inputTokens,
    int? outputTokens,
    int? totalTokens,
    String? aiProvider,
    MessageUsageStatus? status,
    DateTime? timestamp,
    int? responseTimeMs,
    String? errorCode,
    String? errorMessage,
    Map<String, dynamic>? metadata,
  }) {
    return MessageUsageLog(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      messageId: messageId ?? this.messageId,
      conversationId: conversationId ?? this.conversationId,
      inputTokens: inputTokens ?? this.inputTokens,
      outputTokens: outputTokens ?? this.outputTokens,
      totalTokens: totalTokens ?? this.totalTokens,
      aiProvider: aiProvider ?? this.aiProvider,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      responseTimeMs: responseTimeMs ?? this.responseTimeMs,
      errorCode: errorCode ?? this.errorCode,
      errorMessage: errorMessage ?? this.errorMessage,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    messageId,
    conversationId,
    inputTokens,
    outputTokens,
    totalTokens,
    aiProvider,
    status,
    timestamp,
    responseTimeMs,
    errorCode,
    errorMessage,
    metadata,
  ];
}

/// Enum for message usage status
enum MessageUsageStatus {
  success,
  failed,
  quotaExceeded,
  rateLimited,
  cancelled,
  timeout,
}
