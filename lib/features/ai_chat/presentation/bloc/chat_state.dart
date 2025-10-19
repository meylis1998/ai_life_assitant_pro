import 'package:equatable/equatable.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/conversation.dart';

/// Base class for all chat states
abstract class ChatState extends Equatable {
  final Conversation? conversation;
  final AIProvider currentProvider;
  final bool isStreaming;
  final String? streamingContent;
  final String? error;

  const ChatState({
    this.conversation,
    this.currentProvider = AIProvider.gemini,
    this.isStreaming = false,
    this.streamingContent,
    this.error,
  });

  @override
  List<Object?> get props => [
        conversation,
        currentProvider,
        isStreaming,
        streamingContent,
        error,
      ];
}

/// Initial state
class ChatInitial extends ChatState {
  const ChatInitial() : super();
}

/// Loading state
class ChatLoading extends ChatState {
  const ChatLoading({
    Conversation? conversation,
    AIProvider currentProvider = AIProvider.gemini,
  }) : super(
          conversation: conversation,
          currentProvider: currentProvider,
        );
}

/// Chat loaded state with conversation
class ChatLoaded extends ChatState {
  const ChatLoaded({
    required Conversation conversation,
    AIProvider currentProvider = AIProvider.gemini,
  }) : super(
          conversation: conversation,
          currentProvider: currentProvider,
        );
}

/// Message sent successfully
class MessageSent extends ChatState {
  final ChatMessage sentMessage;

  const MessageSent({
    required this.sentMessage,
    required Conversation conversation,
    AIProvider currentProvider = AIProvider.gemini,
  }) : super(
          conversation: conversation,
          currentProvider: currentProvider,
        );

  @override
  List<Object?> get props => [
        ...super.props,
        sentMessage,
      ];
}

/// Streaming response state
class ChatStreaming extends ChatState {
  const ChatStreaming({
    required Conversation conversation,
    required String streamingContent,
    AIProvider currentProvider = AIProvider.gemini,
  }) : super(
          conversation: conversation,
          currentProvider: currentProvider,
          isStreaming: true,
          streamingContent: streamingContent,
        );
}

/// Response received state
class ResponseReceived extends ChatState {
  final ChatMessage response;

  const ResponseReceived({
    required this.response,
    required Conversation conversation,
    AIProvider currentProvider = AIProvider.gemini,
  }) : super(
          conversation: conversation,
          currentProvider: currentProvider,
        );

  @override
  List<Object?> get props => [
        ...super.props,
        response,
      ];
}

/// Error state
class ChatError extends ChatState {
  final String errorMessage;
  final ChatMessage? failedMessage;

  const ChatError({
    required this.errorMessage,
    this.failedMessage,
    Conversation? conversation,
    AIProvider currentProvider = AIProvider.gemini,
  }) : super(
          conversation: conversation,
          currentProvider: currentProvider,
          error: errorMessage,
        );

  @override
  List<Object?> get props => [
        ...super.props,
        errorMessage,
        failedMessage,
      ];
}

/// Provider switched state
class ProviderSwitched extends ChatState {
  final AIProvider previousProvider;
  final AIProvider newProvider;

  const ProviderSwitched({
    required this.previousProvider,
    required this.newProvider,
    Conversation? conversation,
  }) : super(
          conversation: conversation,
          currentProvider: newProvider,
        );

  @override
  List<Object?> get props => [
        ...super.props,
        previousProvider,
        newProvider,
      ];
}

/// Conversation cleared state
class ConversationCleared extends ChatState {
  const ConversationCleared({
    AIProvider currentProvider = AIProvider.gemini,
  }) : super(
          currentProvider: currentProvider,
        );
}

/// New conversation started
class NewConversationStarted extends ChatState {
  const NewConversationStarted({
    required Conversation conversation,
    AIProvider currentProvider = AIProvider.gemini,
  }) : super(
          conversation: conversation,
          currentProvider: currentProvider,
        );
}