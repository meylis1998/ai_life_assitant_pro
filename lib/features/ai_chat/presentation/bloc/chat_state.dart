import 'package:equatable/equatable.dart';
import '../../../usage_tracking/domain/entities/quota_status.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/conversation.dart';

/// Base class for all chat states
abstract class ChatState extends Equatable {
  final Conversation? conversation;
  final AIProvider currentProvider;
  final bool isStreaming;
  final String? streamingContent;
  final String? error;
  final QuotaStatus? quotaStatus;
  final String? userId;

  const ChatState({
    this.conversation,
    this.currentProvider = AIProvider.gemini,
    this.isStreaming = false,
    this.streamingContent,
    this.error,
    this.quotaStatus,
    this.userId,
  });

  @override
  List<Object?> get props => [
    conversation,
    currentProvider,
    isStreaming,
    streamingContent,
    error,
    quotaStatus,
    userId,
  ];
}

/// Initial state
class ChatInitial extends ChatState {
  const ChatInitial() : super();
}

/// Loading state
class ChatLoading extends ChatState {
  const ChatLoading({super.conversation, super.currentProvider});
}

/// Chat loaded state with conversation
class ChatLoaded extends ChatState {
  const ChatLoaded({
    required Conversation super.conversation,
    super.currentProvider,
  });
}

/// Message sent successfully
class MessageSent extends ChatState {
  final ChatMessage sentMessage;

  const MessageSent({
    required this.sentMessage,
    required Conversation super.conversation,
    super.currentProvider,
  });

  @override
  List<Object?> get props => [...super.props, sentMessage];
}

/// Streaming response state
class ChatStreaming extends ChatState {
  const ChatStreaming({
    required Conversation super.conversation,
    required String super.streamingContent,
    super.currentProvider,
  }) : super(isStreaming: true);
}

/// Response received state
class ResponseReceived extends ChatState {
  final ChatMessage response;

  const ResponseReceived({
    required this.response,
    required Conversation super.conversation,
    super.currentProvider,
  });

  @override
  List<Object?> get props => [...super.props, response];
}

/// Error state
class ChatError extends ChatState {
  final String errorMessage;
  final ChatMessage? failedMessage;

  const ChatError({
    required this.errorMessage,
    this.failedMessage,
    super.conversation,
    super.currentProvider,
  }) : super(error: errorMessage);

  @override
  List<Object?> get props => [...super.props, errorMessage, failedMessage];
}

/// Provider switched state
class ProviderSwitched extends ChatState {
  final AIProvider previousProvider;
  final AIProvider newProvider;

  const ProviderSwitched({
    required this.previousProvider,
    required this.newProvider,
    super.conversation,
  }) : super(currentProvider: newProvider);

  @override
  List<Object?> get props => [...super.props, previousProvider, newProvider];
}

/// Conversation cleared state
class ConversationCleared extends ChatState {
  const ConversationCleared({super.currentProvider});
}

/// New conversation started
class NewConversationStarted extends ChatState {
  const NewConversationStarted({
    required Conversation super.conversation,
    super.currentProvider,
  });
}

/// Quota exceeded state
class QuotaExceeded extends ChatState {
  final String userTier;
  final String quotaType;
  final DateTime? resetTime;
  final String? upgradeSuggestion;
  final int remainingMessages;
  final int remainingTokens;

  const QuotaExceeded({
    required this.userTier,
    required this.quotaType,
    this.resetTime,
    this.upgradeSuggestion,
    required this.remainingMessages,
    required this.remainingTokens,
    super.conversation,
    super.currentProvider,
    super.quotaStatus,
  }) : super(error: 'Quota exceeded');

  String get formattedResetTime {
    if (resetTime == null) return '';
    final duration = resetTime!.difference(DateTime.now());
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m';
    } else {
      return 'Less than a minute';
    }
  }

  @override
  List<Object?> get props => [
    ...super.props,
    userTier,
    quotaType,
    resetTime,
    upgradeSuggestion,
    remainingMessages,
    remainingTokens,
  ];
}

/// Quota warning state
class QuotaWarning extends ChatState {
  final double usagePercentage;
  final int remainingMessages;
  final int remainingTokens;
  final String warningMessage;

  const QuotaWarning({
    required this.usagePercentage,
    required this.remainingMessages,
    required this.remainingTokens,
    required this.warningMessage,
    super.conversation,
    super.currentProvider,
    super.quotaStatus,
  });

  @override
  List<Object?> get props => [
    ...super.props,
    usagePercentage,
    remainingMessages,
    remainingTokens,
    warningMessage,
  ];
}

/// Usage updated state
class UsageUpdated extends ChatState {
  final int messagesUsedToday;
  final int tokensUsedToday;
  final double estimatedCost;

  const UsageUpdated({
    required this.messagesUsedToday,
    required this.tokensUsedToday,
    required this.estimatedCost,
    super.conversation,
    super.currentProvider,
    super.quotaStatus,
    super.userId,
  });

  @override
  List<Object?> get props => [
    ...super.props,
    messagesUsedToday,
    tokensUsedToday,
    estimatedCost,
  ];
}
