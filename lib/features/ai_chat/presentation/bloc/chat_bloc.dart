import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/logger.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/usecases/get_chat_history.dart';
import '../../domain/usecases/send_message.dart';
import '../../domain/usecases/stream_response.dart';
import 'chat_event.dart';
import 'chat_state.dart';

/// BLoC for managing chat functionality
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final SendMessage sendMessage;
  final StreamResponse streamResponse;
  final GetChatHistory getChatHistory;
  final AuthRepository? authRepository;

  StreamSubscription? _streamSubscription;
  String _accumulatedContent = '';

  ChatBloc({
    required this.sendMessage,
    required this.streamResponse,
    required this.getChatHistory,
    this.authRepository,
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
    if (authRepository == null) {
      AppLogger.w('Auth repository not available - skipping user context initialization');
      return;
    }

    try {
      final userResult = await authRepository!.getCurrentUser();
      userResult.fold(
        (failure) {
          // User not authenticated
          AppLogger.w('No authenticated user found: ${failure.message}');
        },
        (user) {
          if (user == null) {
            AppLogger.w('User is null despite successful result');
            return;
          }

          AppLogger.i('User context initialized for user: ${user.id}');
        },
      );
    } catch (e) {
      AppLogger.e('Failed to initialize user context: $e');
      // Don't rethrow - continue without user context
    }
  }

  /// Handle sending a message
  Future<void> _onSendMessage(
    SendMessageEvent event,
    Emitter<ChatState> emit,
  ) async {
    try {
      AppLogger.i('Sending message: ${event.message}');

      // Get current user - optional if auth is not available
      String? userId;
      if (authRepository != null) {
        final userResult = await authRepository!.getCurrentUser();
        final user = userResult.fold((f) => null, (u) => u);
        userId = user?.id;
      }

      // Create user message
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
          emit(
            ChatError(
              errorMessage: failure.message,
              failedMessage: userMessage,
              conversation: updatedConversation,
              currentProvider: event.provider,
            ),
          );
        },
        (response) {
          AppLogger.i(
            'Received response with ${response.totalTokens ?? 0} tokens',
          );
          final conversationWithResponse = updatedConversation.addMessage(
            response,
          );

          // Emit response received state
          emit(
            ResponseReceived(
              response: response,
              conversation: conversationWithResponse,
              currentProvider: event.provider,
            ),
          );
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

      // Use await for to properly handle the stream
      await for (final result in stream) {
        if (emit.isDone) break;

        result.fold(
          (failure) {
            AppLogger.e('Stream error: ${failure.message}');
            if (!emit.isDone) {
              emit(
                ChatError(
                  errorMessage: failure.message,
                  conversation: updatedConversation,
                  currentProvider: event.provider,
                ),
              );
            }
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

            if (!emit.isDone) {
              emit(
                ChatStreaming(
                  conversation: conversationWithUpdate,
                  streamingContent: _accumulatedContent,
                  currentProvider: event.provider,
                ),
              );
            }
          },
        );
      }

      // Stream completed - mark message as sent
      if (!emit.isDone) {
        AppLogger.i('Stream completed');

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
      }
    } catch (e, stackTrace) {
      AppLogger.e(
        'Error in _onStreamMessage',
        error: e,
        stackTrace: stackTrace,
      );
      if (!emit.isDone) {
        emit(
          ChatError(
            errorMessage: 'Failed to stream message: $e',
            conversation: state.conversation,
            currentProvider: event.provider,
          ),
        );
      }
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

    // Allow switching to any provider (usage tracking disabled)
    emit(
      ProviderSwitched(
        previousProvider: state.currentProvider,
        newProvider: event.provider,
        conversation: state.conversation,
      ),
    );
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

  @override
  Future<void> close() {
    _streamSubscription?.cancel();
    return super.close();
  }
}
