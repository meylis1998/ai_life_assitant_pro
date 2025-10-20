import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../usage_tracking/domain/entities/quota_status.dart';
import '../../../usage_tracking/domain/repositories/usage_repository.dart';
import '../../../usage_tracking/presentation/bloc/usage_bloc.dart';
import '../../../usage_tracking/presentation/bloc/usage_event.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/usecases/get_chat_history.dart';
import '../../domain/usecases/send_message.dart';
import '../../domain/usecases/stream_response.dart';
import 'chat_event.dart';
import 'chat_state.dart';

/// BLoC for managing chat functionality with usage tracking
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final SendMessage sendMessage;
  final StreamResponse streamResponse;
  final GetChatHistory getChatHistory;
  final AuthRepository authRepository;
  final UsageRepository usageRepository;
  final UsageBloc? usageBloc;

  StreamSubscription? _streamSubscription;
  String _accumulatedContent = '';
  QuotaStatus? _currentQuotaStatus;

  ChatBloc({
    required this.sendMessage,
    required this.streamResponse,
    required this.getChatHistory,
    required this.authRepository,
    required this.usageRepository,
    this.usageBloc,
  }) : super(const ChatInitial()) {
    on<SendMessageEvent>(_onSendMessage);
    on<StreamMessageEvent>(_onStreamMessage);
    on<LoadChatHistoryEvent>(_onLoadChatHistory);
    on<StartNewConversationEvent>(_onStartNewConversation);
    on<SwitchProviderEvent>(_onSwitchProvider);
    on<DeleteMessageEvent>(_onDeleteMessage);
    on<RetryMessageEvent>(_onRetryMessage);
    on<ClearConversationEvent>(_onClearConversation);
    on<StopStreamingEvent>(_onStopStreaming);

    // Initialize user context
    _initializeUserContext();
  }

  /// Initialize user context and quota status
  Future<void> _initializeUserContext() async {
    try {
      final userResult = await authRepository.getCurrentUser();
      userResult.fold(
        (failure) {
          // User not authenticated, will use guest mode
          AppLogger.i('No authenticated user, using guest mode');
        },
        (user) {
          // Initialize usage tracking if UsageBloc is available
          final userId = user?.id;
          if (userId != null) {
            usageBloc?.add(InitializeUsageTracking(userId: userId));
          }
        },
      );
    } catch (e) {
      AppLogger.e('Failed to initialize user context: $e');
    }
  }

  /// Handle sending a message
  Future<void> _onSendMessage(
    SendMessageEvent event,
    Emitter<ChatState> emit,
  ) async {
    try {
      AppLogger.i('Sending message: ${event.message}');

      // Get current user for quota checking
      final userResult = await authRepository.getCurrentUser();
      final user = userResult.fold((f) => null, (u) => u);
      final userId = user?.id ?? 'guest';

      // Check quota before sending (for authenticated users)
      if (user != null) {
        final quotaResult = await usageRepository.checkQuota(
          userId: userId,
          provider: event.provider.apiName,
          estimatedTokens: _estimateTokens(event.message),
        );

        final canSend = quotaResult.fold((f) => false, (r) => r);

        if (!canSend) {
          // Get quota status for detailed error
          final quotaStatusResult = await usageRepository.getQuotaStatus(
            userId,
          );

          return quotaStatusResult.fold(
            (failure) {
              emit(
                ChatError(
                  errorMessage: 'Quota exceeded. Please try again later.',
                  conversation: state.conversation,
                  currentProvider: event.provider,
                ),
              );
            },
            (quotaStatus) {
              _currentQuotaStatus = quotaStatus;
              emit(
                QuotaExceeded(
                  userTier: quotaStatus.tier,
                  quotaType: quotaStatus.exceededType ?? 'daily',
                  resetTime: quotaStatus.nextResetDate,
                  upgradeSuggestion: quotaStatus.tier == 'free'
                      ? 'Upgrade to Pro for 10x more messages!'
                      : quotaStatus.tier == 'pro'
                      ? 'Upgrade to Premium for unlimited usage!'
                      : null,
                  remainingMessages: quotaStatus.remainingMessages,
                  remainingTokens: quotaStatus.remainingTokens,
                  conversation: state.conversation,
                  currentProvider: event.provider,
                  quotaStatus: quotaStatus,
                ),
              );
            },
          );
        }

        // Check if approaching limit (80%+ usage)
        final quotaStatusResult = await usageRepository.getQuotaStatus(userId);
        quotaStatusResult.fold((f) => null, (quotaStatus) {
          _currentQuotaStatus = quotaStatus;
          if (quotaStatus.usagePercentage >= 80 && !quotaStatus.isExceeded) {
            // Emit warning but continue with message
            emit(
              QuotaWarning(
                usagePercentage: quotaStatus.usagePercentage,
                remainingMessages: quotaStatus.remainingMessages,
                remainingTokens: quotaStatus.remainingTokens,
                warningMessage: 'You\'re approaching your daily limit',
                conversation: state.conversation,
                currentProvider: event.provider,
                quotaStatus: quotaStatus,
              ),
            );
          }
        });
      }

      // Create user message with userId
      final userMessage = ChatMessage(
        content: event.message,
        role: MessageRole.user,
        status: MessageStatus.sent,
        userId: userId,
      );

      // Add user message to conversation
      final currentConversation =
          state.conversation ??
          Conversation(
            title: 'New Conversation',
            defaultProvider: event.provider,
          );

      final updatedConversation = currentConversation.addMessage(userMessage);

      emit(
        MessageSent(
          sentMessage: userMessage,
          conversation: updatedConversation,
          currentProvider: event.provider,
        ),
      );

      // Send message and get response
      final result = await sendMessage(
        MessageParams(
          message: event.message,
          provider: event.provider,
          conversationId: currentConversation.id,
        ),
      );

      result.fold(
        (failure) {
          AppLogger.e('Failed to send message: ${failure.message}');

          // Check if it's a quota exceeded failure
          if (failure is UserQuotaExceededFailure) {
            emit(
              QuotaExceeded(
                userTier: failure.userTier,
                quotaType: failure.quotaType,
                resetTime: failure.resetTime,
                upgradeSuggestion: failure.upgradeSuggestion,
                remainingMessages: 0,
                remainingTokens: 0,
                conversation: updatedConversation,
                currentProvider: event.provider,
                quotaStatus: _currentQuotaStatus,
              ),
            );
          } else {
            emit(
              ChatError(
                errorMessage: failure.message,
                failedMessage: userMessage,
                conversation: updatedConversation,
                currentProvider: event.provider,
              ),
            );
          }
        },
        (response) {
          AppLogger.i(
            'Received response with ${response.totalTokens ?? 0} tokens',
          );
          final conversationWithResponse = updatedConversation.addMessage(
            response,
          );

          // Log usage to UsageBloc if available
          if (user != null &&
              usageBloc != null &&
              response.totalTokens != null) {
            usageBloc!.add(
              LogMessageUsage(
                userId: userId,
                messageId: response.id,
                conversationId: currentConversation.id,
                inputTokens: response.inputTokens ?? 0,
                outputTokens: response.outputTokens ?? 0,
                provider: event.provider.apiName,
                responseTimeMs: response.responseTimeMs ?? 0,
              ),
            );
          }

          // Update usage stats
          if (user != null && _currentQuotaStatus != null) {
            final updatedStats = UsageUpdated(
              messagesUsedToday:
                  (_currentQuotaStatus!.messagesUsedToday ?? 0) + 1,
              tokensUsedToday:
                  (_currentQuotaStatus!.tokensUsedToday ?? 0) +
                  (response.totalTokens ?? 0),
              estimatedCost: response.getEstimatedCost(),
              conversation: conversationWithResponse,
              currentProvider: event.provider,
              quotaStatus: _currentQuotaStatus,
              userId: userId,
            );
            emit(updatedStats);
          } else {
            emit(
              ResponseReceived(
                response: response,
                conversation: conversationWithResponse,
                currentProvider: event.provider,
              ),
            );
          }
        },
      );
    } catch (e, stackTrace) {
      AppLogger.e('Error in _onSendMessage', error: e, stackTrace: stackTrace);
      emit(
        ChatError(
          errorMessage: 'An unexpected error occurred',
          conversation: state.conversation,
          currentProvider: event.provider,
        ),
      );
    }
  }

  /// Handle streaming a message response
  Future<void> _onStreamMessage(
    StreamMessageEvent event,
    Emitter<ChatState> emit,
  ) async {
    try {
      AppLogger.i('Starting stream for message: ${event.message}');

      // Cancel any existing stream
      await _streamSubscription?.cancel();
      _accumulatedContent = '';

      // Create user message
      final userMessage = ChatMessage(
        content: event.message,
        role: MessageRole.user,
        status: MessageStatus.sent,
      );

      // Add user message to conversation
      final currentConversation =
          state.conversation ??
          Conversation(
            title: 'New Conversation',
            defaultProvider: event.provider,
          );

      var updatedConversation = currentConversation.addMessage(userMessage);

      emit(
        MessageSent(
          sentMessage: userMessage,
          conversation: updatedConversation,
          currentProvider: event.provider,
        ),
      );

      // Create assistant message placeholder
      final assistantMessage = ChatMessage(
        content: '',
        role: MessageRole.assistant,
        provider: event.provider,
        status: MessageStatus.streaming,
      );

      updatedConversation = updatedConversation.addMessage(assistantMessage);

      // Stream the response
      final stream = streamResponse(
        StreamMessageParams(
          message: event.message,
          provider: event.provider,
          conversationId: currentConversation.id,
        ),
      );

      _streamSubscription = stream.listen(
        (result) {
          result.fold(
            (failure) {
              AppLogger.e('Stream error: ${failure.message}');
              emit(
                ChatError(
                  errorMessage: failure.message,
                  conversation: updatedConversation,
                  currentProvider: event.provider,
                ),
              );
            },
            (chunk) {
              _accumulatedContent += chunk;

              // Update the assistant message with accumulated content
              final updatedAssistantMessage = assistantMessage.copyWith(
                content: _accumulatedContent,
              );

              final conversationWithUpdate = updatedConversation.updateMessage(
                assistantMessage.id,
                updatedAssistantMessage,
              );

              emit(
                ChatStreaming(
                  conversation: conversationWithUpdate,
                  streamingContent: _accumulatedContent,
                  currentProvider: event.provider,
                ),
              );
            },
          );
        },
        onDone: () {
          AppLogger.i('Stream completed');

          // Mark message as sent
          final finalMessage = assistantMessage.copyWith(
            content: _accumulatedContent,
            status: MessageStatus.sent,
          );

          final finalConversation = updatedConversation.updateMessage(
            assistantMessage.id,
            finalMessage,
          );

          emit(
            ResponseReceived(
              response: finalMessage,
              conversation: finalConversation,
              currentProvider: event.provider,
            ),
          );
        },
        onError: (error) {
          AppLogger.e('Stream error', error: error);
          emit(
            ChatError(
              errorMessage: 'Stream error: $error',
              conversation: updatedConversation,
              currentProvider: event.provider,
            ),
          );
        },
      );
    } catch (e, stackTrace) {
      AppLogger.e(
        'Error in _onStreamMessage',
        error: e,
        stackTrace: stackTrace,
      );
      emit(
        ChatError(
          errorMessage: 'Failed to start streaming',
          conversation: state.conversation,
          currentProvider: event.provider,
        ),
      );
    }
  }

  /// Handle loading chat history
  Future<void> _onLoadChatHistory(
    LoadChatHistoryEvent event,
    Emitter<ChatState> emit,
  ) async {
    emit(
      ChatLoading(
        conversation: state.conversation,
        currentProvider: state.currentProvider,
      ),
    );

    final result = await getChatHistory(
      ChatHistoryParams(conversationId: event.conversationId),
    );

    result.fold(
      (failure) => emit(
        ChatError(
          errorMessage: failure.message,
          currentProvider: state.currentProvider,
        ),
      ),
      (conversation) => emit(
        ChatLoaded(
          conversation: conversation,
          currentProvider:
              conversation.defaultProvider ?? state.currentProvider,
        ),
      ),
    );
  }

  /// Handle starting a new conversation
  Future<void> _onStartNewConversation(
    StartNewConversationEvent event,
    Emitter<ChatState> emit,
  ) async {
    final newConversation = Conversation(
      title: event.title ?? 'New Conversation',
      defaultProvider: event.defaultProvider ?? state.currentProvider,
    );

    emit(
      NewConversationStarted(
        conversation: newConversation,
        currentProvider: event.defaultProvider ?? state.currentProvider,
      ),
    );
  }

  /// Handle switching AI provider
  Future<void> _onSwitchProvider(
    SwitchProviderEvent event,
    Emitter<ChatState> emit,
  ) async {
    AppLogger.i(
      'Switching provider from ${state.currentProvider} to ${event.provider}',
    );

    // Check if user has access to this provider
    final userResult = await authRepository.getCurrentUser();
    final user = userResult.fold((f) => null, (u) => u);

    if (user != null) {
      final subscriptionResult = await usageRepository.getUserSubscription(
        user.id,
      );

      subscriptionResult.fold(
        (failure) {
          // Allow switch on error
          emit(
            ProviderSwitched(
              previousProvider: state.currentProvider,
              newProvider: event.provider,
              conversation: state.conversation,
            ),
          );
        },
        (subscription) {
          final canUse = subscription.canUseProvider(event.provider.apiName);

          if (!canUse) {
            emit(
              ChatError(
                errorMessage:
                    'Upgrade to Pro to use ${event.provider.displayName}',
                conversation: state.conversation,
                currentProvider: state.currentProvider,
              ),
            );
          } else {
            emit(
              ProviderSwitched(
                previousProvider: state.currentProvider,
                newProvider: event.provider,
                conversation: state.conversation,
              ),
            );
          }
        },
      );
    } else {
      // Guest users can only use Gemini
      if (event.provider != AIProvider.gemini) {
        emit(
          ChatError(
            errorMessage: 'Sign in to use ${event.provider.displayName}',
            conversation: state.conversation,
            currentProvider: state.currentProvider,
          ),
        );
      } else {
        emit(
          ProviderSwitched(
            previousProvider: state.currentProvider,
            newProvider: event.provider,
            conversation: state.conversation,
          ),
        );
      }
    }
  }

  /// Handle deleting a message
  Future<void> _onDeleteMessage(
    DeleteMessageEvent event,
    Emitter<ChatState> emit,
  ) async {
    if (state.conversation != null) {
      final updatedConversation = state.conversation!.removeMessage(
        event.messageId,
      );
      emit(
        ChatLoaded(
          conversation: updatedConversation,
          currentProvider: state.currentProvider,
        ),
      );
    }
  }

  /// Handle retrying a failed message
  Future<void> _onRetryMessage(
    RetryMessageEvent event,
    Emitter<ChatState> emit,
  ) async {
    if (event.message.role == MessageRole.user) {
      add(
        SendMessageEvent(
          message: event.message.content,
          provider: state.currentProvider,
          conversationId: state.conversation?.id,
        ),
      );
    }
  }

  /// Handle clearing the conversation
  Future<void> _onClearConversation(
    ClearConversationEvent event,
    Emitter<ChatState> emit,
  ) async {
    emit(ConversationCleared(currentProvider: state.currentProvider));
  }

  /// Handle stopping the stream
  Future<void> _onStopStreaming(
    StopStreamingEvent event,
    Emitter<ChatState> emit,
  ) async {
    await _streamSubscription?.cancel();
    _streamSubscription = null;

    if (state.conversation != null && state.isStreaming) {
      emit(
        ChatLoaded(
          conversation: state.conversation!,
          currentProvider: state.currentProvider,
        ),
      );
    }
  }

  /// Helper method to estimate tokens in a text
  int _estimateTokens(String text) {
    // Rough estimation: 1 token per 4 characters
    return (text.length / 4).ceil();
  }

  @override
  Future<void> close() {
    _streamSubscription?.cancel();
    return super.close();
  }
}
