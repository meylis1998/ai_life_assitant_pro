import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import 'chat_message.dart';

/// Entity representing a conversation/chat thread
class Conversation extends Equatable {
  final String id;
  final String title;
  final List<ChatMessage> messages;
  final DateTime createdAt;
  final DateTime updatedAt;
  final AIProvider? defaultProvider;
  final Map<String, dynamic>? metadata;

  Conversation({
    String? id,
    required this.title,
    List<ChatMessage>? messages,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.defaultProvider,
    this.metadata,
  }) : id = id ?? const Uuid().v4(),
       messages = messages ?? [],
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  /// Create a copy of the conversation with updated fields
  Conversation copyWith({
    String? id,
    String? title,
    List<ChatMessage>? messages,
    DateTime? createdAt,
    DateTime? updatedAt,
    AIProvider? defaultProvider,
    Map<String, dynamic>? metadata,
  }) {
    return Conversation(
      id: id ?? this.id,
      title: title ?? this.title,
      messages: messages ?? this.messages,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      defaultProvider: defaultProvider ?? this.defaultProvider,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Add a message to the conversation
  Conversation addMessage(ChatMessage message) {
    return copyWith(
      messages: [...messages, message],
      updatedAt: DateTime.now(),
    );
  }

  /// Update a message in the conversation
  Conversation updateMessage(String messageId, ChatMessage updatedMessage) {
    final updatedMessages = messages.map((msg) {
      return msg.id == messageId ? updatedMessage : msg;
    }).toList();

    return copyWith(messages: updatedMessages, updatedAt: DateTime.now());
  }

  /// Remove a message from the conversation
  Conversation removeMessage(String messageId) {
    final updatedMessages = messages
        .where((msg) => msg.id != messageId)
        .toList();
    return copyWith(messages: updatedMessages, updatedAt: DateTime.now());
  }

  /// Get the last message in the conversation
  ChatMessage? get lastMessage => messages.isNotEmpty ? messages.last : null;

  /// Get the last user message
  ChatMessage? get lastUserMessage {
    final userMessages = messages
        .where((msg) => msg.role == MessageRole.user)
        .toList();
    return userMessages.isNotEmpty ? userMessages.last : null;
  }

  /// Get the last assistant message
  ChatMessage? get lastAssistantMessage {
    final assistantMessages = messages
        .where((msg) => msg.role == MessageRole.assistant)
        .toList();
    return assistantMessages.isNotEmpty ? assistantMessages.last : null;
  }

  /// Get message count
  int get messageCount => messages.length;

  /// Check if conversation is empty
  bool get isEmpty => messages.isEmpty;

  @override
  List<Object?> get props => [
    id,
    title,
    messages,
    createdAt,
    updatedAt,
    defaultProvider,
    metadata,
  ];

  @override
  String toString() {
    return 'Conversation{id: $id, title: $title, messageCount: $messageCount}';
  }
}
