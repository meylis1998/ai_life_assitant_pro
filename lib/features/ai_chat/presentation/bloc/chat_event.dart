import 'package:equatable/equatable.dart';
import '../../domain/entities/chat_message.dart';

/// Base class for all chat events
abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

/// Event to send a message
class SendMessageEvent extends ChatEvent {
  final String message;
  final AIProvider provider;
  final String? conversationId;

  const SendMessageEvent({
    required this.message,
    required this.provider,
    this.conversationId,
  });

  @override
  List<Object?> get props => [message, provider, conversationId];
}

/// Event to stream a message response
class StreamMessageEvent extends ChatEvent {
  final String message;
  final AIProvider provider;
  final String? conversationId;

  const StreamMessageEvent({
    required this.message,
    required this.provider,
    this.conversationId,
  });

  @override
  List<Object?> get props => [message, provider, conversationId];
}

/// Event to load chat history
class LoadChatHistoryEvent extends ChatEvent {
  final String conversationId;

  const LoadChatHistoryEvent({required this.conversationId});

  @override
  List<Object?> get props => [conversationId];
}

/// Event to start a new conversation
class StartNewConversationEvent extends ChatEvent {
  final String? title;
  final AIProvider? defaultProvider;

  const StartNewConversationEvent({this.title, this.defaultProvider});

  @override
  List<Object?> get props => [title, defaultProvider];
}

/// Event to switch AI provider
class SwitchProviderEvent extends ChatEvent {
  final AIProvider provider;

  const SwitchProviderEvent({required this.provider});

  @override
  List<Object?> get props => [provider];
}

/// Event to delete a message
class DeleteMessageEvent extends ChatEvent {
  final String messageId;

  const DeleteMessageEvent({required this.messageId});

  @override
  List<Object?> get props => [messageId];
}

/// Event to retry a failed message
class RetryMessageEvent extends ChatEvent {
  final ChatMessage message;

  const RetryMessageEvent({required this.message});

  @override
  List<Object?> get props => [message];
}

/// Event to clear the current conversation
class ClearConversationEvent extends ChatEvent {
  const ClearConversationEvent();
}

/// Event to stop streaming
class StopStreamingEvent extends ChatEvent {
  const StopStreamingEvent();
}
