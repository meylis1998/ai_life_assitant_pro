import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

/// Entity representing a chat message
class ChatMessage extends Equatable {
  final String id;
  final String content;
  final MessageRole role;
  final DateTime timestamp;
  final AIProvider? provider;
  final MessageStatus status;
  final Map<String, dynamic>? metadata;

  // Token counting and usage tracking
  final int? inputTokens;
  final int? outputTokens;
  final int? totalTokens;
  final String? userId;
  final int? responseTimeMs;

  ChatMessage({
    String? id,
    required this.content,
    required this.role,
    DateTime? timestamp,
    this.provider,
    this.status = MessageStatus.sent,
    this.metadata,
    this.inputTokens,
    this.outputTokens,
    this.totalTokens,
    this.userId,
    this.responseTimeMs,
  }) : id = id ?? const Uuid().v4(),
       timestamp = timestamp ?? DateTime.now();

  /// Create a copy of the message with updated fields
  ChatMessage copyWith({
    String? id,
    String? content,
    MessageRole? role,
    DateTime? timestamp,
    AIProvider? provider,
    MessageStatus? status,
    Map<String, dynamic>? metadata,
    int? inputTokens,
    int? outputTokens,
    int? totalTokens,
    String? userId,
    int? responseTimeMs,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      role: role ?? this.role,
      timestamp: timestamp ?? this.timestamp,
      provider: provider ?? this.provider,
      status: status ?? this.status,
      metadata: metadata ?? this.metadata,
      inputTokens: inputTokens ?? this.inputTokens,
      outputTokens: outputTokens ?? this.outputTokens,
      totalTokens: totalTokens ?? this.totalTokens,
      userId: userId ?? this.userId,
      responseTimeMs: responseTimeMs ?? this.responseTimeMs,
    );
  }

  @override
  List<Object?> get props => [
    id,
    content,
    role,
    timestamp,
    provider,
    status,
    metadata,
    inputTokens,
    outputTokens,
    totalTokens,
    userId,
    responseTimeMs,
  ];

  /// Calculate total tokens if not already set
  int get calculatedTotalTokens {
    if (totalTokens != null) return totalTokens!;
    final input = inputTokens ?? 0;
    final output = outputTokens ?? 0;
    return input + output;
  }

  /// Check if this message has token information
  bool get hasTokenInfo => inputTokens != null || outputTokens != null;

  /// Get estimated cost for this message based on provider
  double getEstimatedCost() {
    if (!hasTokenInfo) return 0.0;

    // Approximate costs per 1K tokens (in USD)
    final costPer1kTokens = {
      AIProvider.gemini: 0.0001,
      AIProvider.claude: 0.008,
      AIProvider.openai: 0.002,
    };

    final rate = provider != null
        ? (costPer1kTokens[provider] ?? 0.001)
        : 0.001;

    return (calculatedTotalTokens / 1000) * rate;
  }

  @override
  String toString() {
    return 'ChatMessage{id: $id, role: $role, content: ${content.substring(0, content.length > 50 ? 50 : content.length)}..., status: $status, tokens: $calculatedTotalTokens}';
  }
}

/// Role of the message sender
enum MessageRole { user, assistant, system }

/// AI provider used for generating the response
enum AIProvider { gemini, claude, openai }

/// Status of the message
enum MessageStatus { sending, sent, streaming, failed, pending }

/// Extension methods for enums
extension MessageRoleExtension on MessageRole {
  String get displayName {
    switch (this) {
      case MessageRole.user:
        return 'You';
      case MessageRole.assistant:
        return 'Assistant';
      case MessageRole.system:
        return 'System';
    }
  }
}

extension AIProviderExtension on AIProvider {
  String get displayName {
    switch (this) {
      case AIProvider.gemini:
        return 'Gemini';
      case AIProvider.claude:
        return 'Claude';
      case AIProvider.openai:
        return 'OpenAI';
    }
  }

  String get apiName {
    switch (this) {
      case AIProvider.gemini:
        return 'gemini';
      case AIProvider.claude:
        return 'claude';
      case AIProvider.openai:
        return 'openai';
    }
  }
}
