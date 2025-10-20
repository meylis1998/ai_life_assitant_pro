import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/utils/logger.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../usage_tracking/domain/entities/message_usage_log.dart';
import '../../../usage_tracking/domain/repositories/usage_repository.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/repositories/ai_chat_repository.dart';
import '../datasources/ai_chat_local_datasource.dart';
import '../datasources/ai_chat_remote_datasource.dart';
import '../models/conversation_model.dart';

/// Enhanced implementation of the AI chat repository with authentication and usage tracking
class AIChatRepositoryImplEnhanced implements AIChatRepository {
  final AIChatRemoteDataSource remoteDataSource;
  final AIChatLocalDataSource localDataSource;
  final NetworkInfo networkInfo;
  final AuthRepository authRepository;
  final UsageRepository usageRepository;

  AIChatRepositoryImplEnhanced({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
    required this.authRepository,
    required this.usageRepository,
  });

  @override
  Future<Either<Failure, ChatMessage>> sendMessage({
    required String message,
    required AIProvider provider,
    String? conversationId,
    Map<String, dynamic>? context,
  }) async {
    try {
      // 1. Check network connectivity
      if (!await networkInfo.isConnected) {
        return const Left(NetworkFailure(message: 'No internet connection'));
      }

      // 2. Get current authenticated user
      final userResult = await authRepository.getCurrentUser();
      final user = userResult.fold(
        (failure) => null, // Allow guest mode
        (user) => user,
      );

      final userId = user?.id ?? 'guest';

      // 3. Check quota for authenticated users
      if (user != null) {
        final quotaResult = await usageRepository.checkQuota(
          userId: userId,
          provider: provider.apiName,
          estimatedTokens: _estimateTokens(message),
        );

        final canSend = quotaResult.fold(
          (failure) => false,
          (result) => result,
        );

        if (!canSend) {
          // Get detailed quota status for error message
          final quotaStatusResult = await usageRepository.getQuotaStatus(
            userId,
          );

          return quotaStatusResult.fold(
            (failure) => Left(
              UserQuotaExceededFailure(
                message: 'Daily message limit reached',
                userTier: 'unknown',
                quotaType: 'daily',
                resetTime: DateTime.now().add(const Duration(hours: 24)),
              ),
            ),
            (quotaStatus) => Left(
              UserQuotaExceededFailure(
                message: quotaStatus.statusMessage,
                userTier: quotaStatus.tier,
                quotaType: quotaStatus.isExceeded ? 'daily' : 'monthly',
                resetTime: quotaStatus.nextResetDate,
                upgradeSuggestion: quotaStatus.tier == 'free'
                    ? 'Upgrade to Pro for 10x more messages!'
                    : null,
              ),
            ),
          );
        }
      }

      // 4. Get conversation history if ID provided
      List<ChatMessage>? history;
      if (conversationId != null) {
        final cachedConversation = await localDataSource.getCachedConversation(
          conversationId,
        );
        history = cachedConversation?.messages;
      }

      // 5. Track start time for response measurement
      final startTime = DateTime.now();

      // 6. Send message to remote source
      final response = await remoteDataSource.sendMessage(
        message: message,
        provider: provider,
        history: history,
      );

      // 7. Calculate response time
      final responseTimeMs = DateTime.now()
          .difference(startTime)
          .inMilliseconds;

      // 8. Extract token counts (varies by provider)
      final tokenInfo = _extractTokenInfo(response, provider);

      // 9. Update response with user context and token info
      final enhancedResponse = response.copyWith(
        userId: userId,
        inputTokens: tokenInfo['inputTokens'],
        outputTokens: tokenInfo['outputTokens'],
        totalTokens: tokenInfo['totalTokens'],
        responseTimeMs: responseTimeMs,
      );

      // 10. Log usage for authenticated users
      if (user != null) {
        final usageLog = MessageUsageLog.success(
          id: const Uuid().v4(),
          userId: userId,
          messageId: enhancedResponse.id,
          conversationId: conversationId ?? 'direct',
          inputTokens: tokenInfo['inputTokens'] ?? 0,
          outputTokens: tokenInfo['outputTokens'] ?? 0,
          aiProvider: provider.apiName,
          responseTimeMs: responseTimeMs,
          metadata: {
            'messageLength': message.length,
            'responseLength': response.content.length,
          },
        );

        await usageRepository.logMessageUsage(usageLog);
      }

      // 11. Cache the updated conversation if ID provided
      if (conversationId != null) {
        await _updateCachedConversation(
          conversationId,
          message,
          enhancedResponse,
          userId,
        );
      }

      AppLogger.i(
        'Message sent successfully - User: $userId, Provider: ${provider.apiName}, '
        'Tokens: ${tokenInfo['totalTokens']}, Time: ${responseTimeMs}ms',
      );

      return Right(enhancedResponse);
    } on AIProviderException catch (e) {
      return Left(AIProviderFailure(message: e.message));
    } on RateLimitException catch (e) {
      return Left(
        RateLimitFailure(
          provider: e.provider,
          message: e.message,
          retryAfter: e.retryAfter,
        ),
      );
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      AppLogger.e('Unexpected error sending message: $e');
      return Left(ServerFailure(message: 'Failed to send message: $e'));
    }
  }

  @override
  Stream<Either<Failure, String>> streamResponse({
    required String message,
    required AIProvider provider,
    String? conversationId,
    Map<String, dynamic>? context,
  }) {
    return Stream.fromFuture(_preFlightChecks(provider)).asyncExpand((
      canProceed,
    ) {
      if (!canProceed) {
        return Stream.value(
          const Left(
            UserQuotaExceededFailure(
              message: 'Quota exceeded',
              userTier: 'unknown',
              quotaType: 'daily',
            ),
          ),
        );
      }

      final startTime = DateTime.now();
      var accumulatedContent = '';

      return remoteDataSource
          .streamResponse(message: message, provider: provider, history: null)
          .map((partialMessage) {
            // Accumulate content (partialMessage is already a String)
            accumulatedContent += partialMessage;

            // Log usage periodically (every 100 chars)
            if (accumulatedContent.length % 100 == 0) {
              _logStreamingUsage(
                message,
                accumulatedContent,
                provider,
                startTime,
              );
            }

            return Right(partialMessage) as Either<Failure, String>;
          })
          .handleError((error) {
            AppLogger.e('Stream error: $error');
            if (error is UserQuotaExceededException) {
              return Left(
                UserQuotaExceededFailure(
                  message: error.message,
                  userTier: 'unknown',
                  quotaType: 'daily',
                ),
              );
            }
            return Left(ServerFailure(message: 'Stream failed: $error'));
          });
    });
  }

  Future<void> _logStreamingUsage(
    String message,
    String accumulatedContent,
    AIProvider provider,
    DateTime startTime,
  ) async {
    try {
      final userResult = await authRepository.getCurrentUser();
      final user = userResult.fold((f) => null, (u) => u);

      if (user != null) {
        final usageLog = MessageUsageLog.success(
          id: const Uuid().v4(),
          userId: user.id,
          messageId: 'streaming-${DateTime.now().millisecondsSinceEpoch}',
          conversationId: 'streaming',
          inputTokens: _estimateTokens(message),
          outputTokens: _estimateTokens(accumulatedContent),
          aiProvider: provider.apiName,
          responseTimeMs: DateTime.now().difference(startTime).inMilliseconds,
        );

        await usageRepository.logMessageUsage(usageLog);
      }
    } catch (e) {
      AppLogger.e('Failed to log streaming usage: $e');
    }
  }

  @override
  Future<Either<Failure, Conversation>> getChatHistory(
    String conversationId,
  ) async {
    try {
      final conversation = await localDataSource.getCachedConversation(
        conversationId,
      );
      if (conversation != null) {
        return Right(conversation);
      } else {
        return const Left(CacheFailure(message: 'Conversation not found'));
      }
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to get conversation: $e'));
    }
  }

  /// Get chat history with optional filters (for internal use)
  Future<Either<Failure, List<ChatMessage>>> getChatHistoryMessages({
    String? conversationId,
    int? limit,
  }) async {
    try {
      // Get current user
      final userResult = await authRepository.getCurrentUser();
      final user = userResult.fold((f) => null, (u) => u);
      final userId = user?.id;

      if (conversationId != null) {
        final conversation = await localDataSource.getCachedConversation(
          conversationId,
        );
        if (conversation != null) {
          // Filter messages by user if authenticated
          final messages = userId != null
              ? conversation.messages.where((m) => m.userId == userId).toList()
              : conversation.messages;

          return Right(
            limit != null ? messages.take(limit).toList() : messages,
          );
        }
      }

      // Get all conversations for user
      final conversations = await localDataSource.getAllCachedConversations();
      final userConversations = userId != null
          ? conversations
                .where((c) => c.messages.any((m) => m.userId == userId))
                .toList()
          : conversations;

      final allMessages = userConversations.expand((c) => c.messages).toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

      return Right(
        limit != null ? allMessages.take(limit).toList() : allMessages,
      );
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to get chat history: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Conversation>>> getAllConversations() async {
    return getConversations();
  }

  Future<Either<Failure, List<Conversation>>> getConversations() async {
    try {
      // Get current user
      final userResult = await authRepository.getCurrentUser();
      final user = userResult.fold((f) => null, (u) => u);
      final userId = user?.id;

      final conversations = await localDataSource.getAllCachedConversations();

      // Filter conversations by user if authenticated
      if (userId != null) {
        final userConversations = conversations
            .where((c) => c.messages.any((m) => m.userId == userId))
            .toList();
        return Right(userConversations);
      }

      return Right(conversations);
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to get conversations: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteConversation(
    String conversationId,
  ) async {
    try {
      // Check if user owns the conversation
      final userResult = await authRepository.getCurrentUser();
      final user = userResult.fold((f) => null, (u) => u);

      if (user != null) {
        final conversation = await localDataSource.getCachedConversation(
          conversationId,
        );
        if (conversation != null) {
          // Check if user has messages in this conversation
          final hasUserMessages = conversation.messages.any(
            (m) => m.userId == user.id,
          );
          if (!hasUserMessages) {
            return const Left(
              UnauthorizedFailure(
                message:
                    'You do not have permission to delete this conversation',
              ),
            );
          }
        }
      }

      await localDataSource.deleteCachedConversation(conversationId);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to delete conversation: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> saveConversation(
    Conversation conversation,
  ) async {
    try {
      await localDataSource.cacheConversation(
        ConversationModel.fromEntity(conversation),
      );
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to save conversation: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> clearAllHistory() async {
    return clearAllConversations();
  }

  Future<Either<Failure, void>> clearAllConversations() async {
    try {
      // Get current user
      final userResult = await authRepository.getCurrentUser();
      final user = userResult.fold((f) => null, (u) => u);

      if (user != null) {
        // Only clear user's conversations
        final conversations = await localDataSource.getAllCachedConversations();
        for (final conversation in conversations) {
          final hasUserMessages = conversation.messages.any(
            (m) => m.userId == user.id,
          );
          if (hasUserMessages) {
            await localDataSource.deleteCachedConversation(conversation.id);
          }
        }
      } else {
        // Guest mode - clear all
        await localDataSource.clearAllCachedConversations();
      }

      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to clear conversations: $e'));
    }
  }

  Future<Either<Failure, void>> setSelectedProvider(AIProvider provider) async {
    try {
      // Check if user has access to this provider
      final userResult = await authRepository.getCurrentUser();
      final user = userResult.fold((f) => null, (u) => u);

      if (user != null) {
        final subscriptionResult = await usageRepository.getUserSubscription(
          user.id,
        );

        final canUse = subscriptionResult.fold(
          (failure) => true, // Allow on error
          (subscription) => subscription.canUseProvider(provider.apiName),
        );

        if (!canUse) {
          return Left(
            UnauthorizedFailure(
              message: 'Upgrade to Pro to use ${provider.displayName}',
            ),
          );
        }
      }

      await localDataSource.setCurrentProvider(provider);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to set provider: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> isProviderAvailable(AIProvider provider) async {
    try {
      final userResult = await authRepository.getCurrentUser();
      final user = userResult.fold((f) => null, (u) => u);

      if (user != null) {
        final subscriptionResult = await usageRepository.getUserSubscription(
          user.id,
        );
        return subscriptionResult.fold(
          (failure) => const Right(true), // Allow on error
          (subscription) =>
              Right(subscription.canUseProvider(provider.apiName)),
        );
      }

      // Guest users can only use Gemini
      return Right(provider == AIProvider.gemini);
    } catch (e) {
      return Left(
        ServerFailure(message: 'Failed to check provider availability: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getRateLimitStatus(
    AIProvider provider,
  ) async {
    try {
      final userResult = await authRepository.getCurrentUser();
      final user = userResult.fold((f) => null, (u) => u);

      if (user == null) {
        return const Right({
          'isLimited': false,
          'remainingCalls': 999999,
          'resetTime': null,
        });
      }

      final quotaResult = await usageRepository.getQuotaStatus(user.id);
      return quotaResult.fold(
        (failure) => const Right({
          'isLimited': false,
          'remainingCalls': 999999,
          'resetTime': null,
        }),
        (quota) => Right({
          'isLimited': quota.isExceeded,
          'remainingCalls': quota.remainingMessages,
          'remainingTokens': quota.remainingTokens,
          'resetTime': quota.nextResetDate,
          'usagePercentage': quota.usagePercentage,
        }),
      );
    } catch (e) {
      return Left(
        ServerFailure(message: 'Failed to get rate limit status: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> switchProvider(AIProvider provider) async {
    return setSelectedProvider(provider);
  }

  @override
  Future<Either<Failure, AIProvider>> getCurrentProvider() async {
    return getSelectedProvider();
  }

  @override
  Future<Either<Failure, String>> uploadDocument({
    required String filePath,
    required String documentId,
  }) async {
    // TODO: Implement RAG document upload
    return const Left(ServerFailure(message: 'RAG not implemented yet'));
  }

  @override
  Future<Either<Failure, ChatMessage>> queryDocument({
    required String query,
    required String documentId,
    required AIProvider provider,
  }) async {
    // TODO: Implement RAG document query
    return const Left(ServerFailure(message: 'RAG not implemented yet'));
  }

  Future<Either<Failure, AIProvider>> getSelectedProvider() async {
    try {
      final provider = await localDataSource.getCurrentProvider();

      // Verify user has access to saved provider
      final userResult = await authRepository.getCurrentUser();
      final user = userResult.fold((f) => null, (u) => u);

      if (user != null) {
        final subscriptionResult = await usageRepository.getUserSubscription(
          user.id,
        );

        final canUse = subscriptionResult.fold(
          (failure) => true,
          (subscription) => subscription.canUseProvider(provider.apiName),
        );

        if (!canUse) {
          // Fallback to Gemini if user doesn't have access
          await localDataSource.setCurrentProvider(AIProvider.gemini);
          return const Right(AIProvider.gemini);
        }
      }

      return Right(provider);
    } catch (e) {
      return const Right(AIProvider.gemini);
    }
  }

  // Helper methods

  Future<bool> _preFlightChecks(AIProvider provider) async {
    // Check network
    if (!await networkInfo.isConnected) {
      return false;
    }

    // Check user quota
    final userResult = await authRepository.getCurrentUser();
    final user = userResult.fold((f) => null, (u) => u);

    if (user != null) {
      final quotaResult = await usageRepository.checkQuota(
        userId: user.id,
        provider: provider.apiName,
        estimatedTokens: 500, // Default estimate
      );

      return quotaResult.fold((f) => false, (r) => r);
    }

    return true; // Allow guest users
  }

  Future<void> _updateCachedConversation(
    String conversationId,
    String userMessage,
    ChatMessage aiResponse,
    String userId,
  ) async {
    final conversation = await localDataSource.getCachedConversation(
      conversationId,
    );

    if (conversation != null) {
      // Create user message with userId
      final userMsg = ChatMessage(
        content: userMessage,
        role: MessageRole.user,
        userId: userId,
      );

      final updatedMessages = [...conversation.messages, userMsg, aiResponse];
      final updatedConversation = conversation.copyWith(
        messages: updatedMessages,
        updatedAt: DateTime.now(),
      );

      await localDataSource.cacheConversation(
        ConversationModel.fromEntity(updatedConversation),
      );
    }
  }

  int _estimateTokens(String text) {
    // Rough estimation: 1 token per 4 characters
    return (text.length / 4).ceil();
  }

  Map<String, int> _extractTokenInfo(
    ChatMessage response,
    AIProvider provider,
  ) {
    // Extract token info from metadata or estimate
    final metadata = response.metadata ?? {};

    switch (provider) {
      case AIProvider.gemini:
        // Gemini provides token counts in response
        return {
          'inputTokens':
              metadata['promptTokenCount'] ?? _estimateTokens(response.content),
          'outputTokens':
              metadata['candidatesTokenCount'] ??
              _estimateTokens(response.content),
          'totalTokens':
              metadata['totalTokenCount'] ??
              _estimateTokens(response.content) * 2,
        };

      case AIProvider.claude:
        // Claude provides usage in headers/response
        return {
          'inputTokens':
              metadata['input_tokens'] ?? _estimateTokens(response.content),
          'outputTokens':
              metadata['output_tokens'] ?? _estimateTokens(response.content),
          'totalTokens':
              metadata['total_tokens'] ?? _estimateTokens(response.content) * 2,
        };

      case AIProvider.openai:
        // OpenAI provides usage object
        final usage = metadata['usage'] as Map<String, dynamic>?;
        return {
          'inputTokens':
              usage?['prompt_tokens'] ?? _estimateTokens(response.content),
          'outputTokens':
              usage?['completion_tokens'] ?? _estimateTokens(response.content),
          'totalTokens':
              usage?['total_tokens'] ?? _estimateTokens(response.content) * 2,
        };
    }
  }
}

/// Exception for quota exceeded scenarios
class UserQuotaExceededException implements Exception {
  final String message;

  UserQuotaExceededException(this.message);

  @override
  String toString() => 'UserQuotaExceededException: $message';
}
