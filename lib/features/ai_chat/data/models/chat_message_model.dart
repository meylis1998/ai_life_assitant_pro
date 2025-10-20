import '../../domain/entities/chat_message.dart';

/// Data model for ChatMessage
class ChatMessageModel extends ChatMessage {
  ChatMessageModel({
    required super.id,
    required super.content,
    required super.role,
    required super.timestamp,
    super.provider,
    super.status = MessageStatus.sent,
    super.metadata,
  });

  /// Create from entity
  factory ChatMessageModel.fromEntity(ChatMessage entity) {
    return ChatMessageModel(
      id: entity.id,
      content: entity.content,
      role: entity.role,
      timestamp: entity.timestamp,
      provider: entity.provider,
      status: entity.status,
      metadata: entity.metadata,
    );
  }

  /// Create from JSON
  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'] as String,
      content: json['content'] as String,
      role: _parseRole(json['role'] as String),
      timestamp: DateTime.parse(json['timestamp'] as String),
      provider: json['provider'] != null
          ? _parseProvider(json['provider'] as String)
          : null,
      status: _parseStatus(json['status'] as String? ?? 'sent'),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'role': role.name,
      'timestamp': timestamp.toIso8601String(),
      'provider': provider?.apiName,
      'status': status.name,
      'metadata': metadata,
    };
  }

  /// Parse role from string
  static MessageRole _parseRole(String role) {
    switch (role) {
      case 'user':
        return MessageRole.user;
      case 'assistant':
        return MessageRole.assistant;
      case 'system':
        return MessageRole.system;
      default:
        throw ArgumentError('Invalid role: $role');
    }
  }

  /// Parse provider from string
  static AIProvider _parseProvider(String provider) {
    switch (provider) {
      case 'gemini':
        return AIProvider.gemini;
      case 'claude':
        return AIProvider.claude;
      case 'openai':
        return AIProvider.openai;
      default:
        throw ArgumentError('Invalid provider: $provider');
    }
  }

  /// Parse status from string
  static MessageStatus _parseStatus(String status) {
    switch (status) {
      case 'sending':
        return MessageStatus.sending;
      case 'sent':
        return MessageStatus.sent;
      case 'streaming':
        return MessageStatus.streaming;
      case 'failed':
        return MessageStatus.failed;
      case 'pending':
        return MessageStatus.pending;
      default:
        return MessageStatus.sent;
    }
  }
}
