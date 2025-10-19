import 'package:dartz/dartz.dart';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/repositories/ai_chat_repository.dart';
import '../datasources/ai_chat_local_datasource.dart';
import '../datasources/ai_chat_remote_datasource.dart';
import '../models/conversation_model.dart';

/// Implementation of the AI chat repository
class AIChatRepositoryImpl implements AIChatRepository {
  final AIChatRemoteDataSource remoteDataSource;
  final AIChatLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  AIChatRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, ChatMessage>> sendMessage({
    required String message,
    required AIProvider provider,
    String? conversationId,
    Map<String, dynamic>? context,
  }) async {
    try {
      // Check network connectivity
      if (!await networkInfo.isConnected) {
        return const Left(NetworkFailure(message: 'No internet connection'));
      }

      // Get conversation history if ID provided
      List<ChatMessage>? history;
      if (conversationId != null) {
        final cachedConversation = await localDataSource.getCachedConversation(conversationId);
        history = cachedConversation?.messages;
      }

      // Send message to remote source
      final response = await remoteDataSource.sendMessage(
        message: message,
        provider: provider,
        history: history,
      );

      // Cache the updated conversation if ID provided
      if (conversationId != null) {
        await _updateCachedConversation(conversationId, message, response);
      }

      return Right(response);
    } on AIProviderException catch (e) {
      return Left(AIProviderFailure(message: e.message));
    } on RateLimitException catch (e) {
      return Left(RateLimitFailure(
        provider: e.provider,
        message: e.message,
        retryAfter: e.retryAfter,
      ));
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, code: e.code));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      AppLogger.e('Unexpected error in sendMessage', error: e);
      return Left(ServerFailure(message: 'An unexpected error occurred: $e'));
    }
  }

  @override
  Stream<Either<Failure, String>> streamResponse({
    required String message,
    required AIProvider provider,
    String? conversationId,
    Map<String, dynamic>? context,
  }) async* {
    try {
      // Check network connectivity
      if (!await networkInfo.isConnected) {
        yield const Left(NetworkFailure(message: 'No internet connection'));
        return;
      }

      // Get conversation history if ID provided
      List<ChatMessage>? history;
      if (conversationId != null) {
        final cachedConversation = await localDataSource.getCachedConversation(conversationId);
        history = cachedConversation?.messages;
      }

      // Stream response from remote source
      final stream = remoteDataSource.streamResponse(
        message: message,
        provider: provider,
        history: history,
      );

      // Buffer to accumulate the full response
      final buffer = StringBuffer();

      await for (final chunk in stream) {
        buffer.write(chunk);
        yield Right(chunk);
      }

      // After streaming is complete, cache the conversation
      if (conversationId != null) {
        final fullResponse = ChatMessage(
          content: buffer.toString(),
          role: MessageRole.assistant,
          provider: provider,
        );
        await _updateCachedConversation(conversationId, message, fullResponse);
      }
    } on AIProviderException catch (e) {
      yield Left(AIProviderFailure(message: e.message));
    } on RateLimitException catch (e) {
      yield Left(RateLimitFailure(
        provider: e.provider,
        message: e.message,
        retryAfter: e.retryAfter,
      ));
    } on ServerException catch (e) {
      yield Left(ServerFailure(message: e.message, code: e.code));
    } on NetworkException catch (e) {
      yield Left(NetworkFailure(message: e.message));
    } catch (e) {
      AppLogger.e('Unexpected error in streamResponse', error: e);
      yield Left(ServerFailure(message: 'Stream error: $e'));
    }
  }

  @override
  Future<Either<Failure, Conversation>> getChatHistory(String conversationId) async {
    try {
      final cachedConversation = await localDataSource.getCachedConversation(conversationId);

      if (cachedConversation != null) {
        return Right(cachedConversation);
      }

      return const Left(CacheFailure(message: 'Conversation not found'));
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      AppLogger.e('Error getting chat history', error: e);
      return Left(CacheFailure(message: 'Failed to get chat history: $e'));
    }
  }

  @override
  Future<Either<Failure, List<Conversation>>> getAllConversations() async {
    try {
      final conversations = await localDataSource.getAllCachedConversations();
      return Right(conversations);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      AppLogger.e('Error getting all conversations', error: e);
      return Left(CacheFailure(message: 'Failed to get conversations: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> saveConversation(Conversation conversation) async {
    try {
      final model = ConversationModel.fromEntity(conversation);
      await localDataSource.cacheConversation(model);
      await localDataSource.setLastConversationId(conversation.id);
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      AppLogger.e('Error saving conversation', error: e);
      return Left(CacheFailure(message: 'Failed to save conversation: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteConversation(String conversationId) async {
    try {
      await localDataSource.deleteCachedConversation(conversationId);
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      AppLogger.e('Error deleting conversation', error: e);
      return Left(CacheFailure(message: 'Failed to delete conversation: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> clearAllHistory() async {
    try {
      await localDataSource.clearAllCachedConversations();
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      AppLogger.e('Error clearing all history', error: e);
      return Left(CacheFailure(message: 'Failed to clear history: $e'));
    }
  }

  @override
  Future<Either<Failure, bool>> isProviderAvailable(AIProvider provider) async {
    try {
      final isAvailable = await remoteDataSource.isProviderAvailable(provider);
      return Right(isAvailable);
    } catch (e) {
      AppLogger.e('Error checking provider availability', error: e);
      return const Right(false);
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getRateLimitStatus(AIProvider provider) async {
    try {
      // TODO: Implement actual rate limit tracking
      // For now, return mock data
      final status = {
        'provider': provider.apiName,
        'remaining': 60,
        'limit': 60,
        'resetsAt': DateTime.now().add(const Duration(minutes: 1)).toIso8601String(),
      };
      return Right(status);
    } catch (e) {
      AppLogger.e('Error getting rate limit status', error: e);
      return Left(ServerFailure(message: 'Failed to get rate limit status: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> switchProvider(AIProvider provider) async {
    try {
      // Check if provider is available
      final isAvailable = await remoteDataSource.isProviderAvailable(provider);
      if (!isAvailable) {
        return Left(AIProviderFailure(
          message: '${provider.displayName} is not configured',
        ));
      }

      // Save provider preference
      await localDataSource.setCurrentProvider(provider);
      return const Right(null);
    } catch (e) {
      AppLogger.e('Error switching provider', error: e);
      return Left(ServerFailure(message: 'Failed to switch provider: $e'));
    }
  }

  @override
  Future<Either<Failure, AIProvider>> getCurrentProvider() async {
    try {
      final provider = await localDataSource.getCurrentProvider();
      return Right(provider);
    } catch (e) {
      AppLogger.e('Error getting current provider', error: e);
      return const Right(AIProvider.gemini); // Return default
    }
  }

  @override
  Future<Either<Failure, String>> uploadDocument({
    required String filePath,
    required String documentId,
  }) async {
    try {
      // TODO: Implement document upload for RAG
      return const Left(ServerFailure(message: 'Document upload not yet implemented'));
    } catch (e) {
      AppLogger.e('Error uploading document', error: e);
      return Left(ServerFailure(message: 'Failed to upload document: $e'));
    }
  }

  @override
  Future<Either<Failure, ChatMessage>> queryDocument({
    required String query,
    required String documentId,
    required AIProvider provider,
  }) async {
    try {
      // TODO: Implement document query using RAG
      return const Left(ServerFailure(message: 'Document query not yet implemented'));
    } catch (e) {
      AppLogger.e('Error querying document', error: e);
      return Left(ServerFailure(message: 'Failed to query document: $e'));
    }
  }

  /// Helper method to update cached conversation
  Future<void> _updateCachedConversation(
    String conversationId,
    String userMessage,
    ChatMessage aiResponse,
  ) async {
    try {
      // Get existing conversation or create new one
      var conversation = await localDataSource.getCachedConversation(conversationId);

      if (conversation == null) {
        conversation = ConversationModel(
          id: conversationId,
          title: userMessage.length > 50
              ? '${userMessage.substring(0, 50)}...'
              : userMessage,
          messages: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }

      // Add user message
      final userMsg = ChatMessage(
        content: userMessage,
        role: MessageRole.user,
      );

      // Update conversation with new messages
      final updatedConversation = conversation
          .addMessage(userMsg)
          .addMessage(aiResponse);

      // Cache the updated conversation
      await localDataSource.cacheConversation(
        ConversationModel.fromEntity(updatedConversation),
      );
    } catch (e) {
      AppLogger.e('Error updating cached conversation', error: e);
    }
  }
}