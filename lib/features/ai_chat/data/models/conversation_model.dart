import '../../domain/entities/chat_message.dart';
import '../../domain/entities/conversation.dart';
import 'chat_message_model.dart';

/// Data model for Conversation
class ConversationModel extends Conversation {
  ConversationModel({
    required super.id,
    required super.title,
    required super.messages,
    required super.createdAt,
    required super.updatedAt,
    super.defaultProvider,
    super.metadata,
  });

  /// Create from entity
  factory ConversationModel.fromEntity(Conversation entity) {
    return ConversationModel(
      id: entity.id,
      title: entity.title,
      messages: entity.messages,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      defaultProvider: entity.defaultProvider,
      metadata: entity.metadata,
    );
  }

  /// Create from JSON
  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id'] as String,
      title: json['title'] as String,
      messages: (json['messages'] as List<dynamic>)
          .map((e) => ChatMessageModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      defaultProvider: json['defaultProvider'] != null
          ? _parseProvider(json['defaultProvider'] as String)
          : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'messages': messages
          .map((msg) => ChatMessageModel.fromEntity(msg).toJson())
          .toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'defaultProvider': defaultProvider?.apiName,
      'metadata': metadata,
    };
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
}
