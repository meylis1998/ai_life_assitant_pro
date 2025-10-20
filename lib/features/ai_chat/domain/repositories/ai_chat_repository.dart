import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/chat_message.dart';
import '../entities/conversation.dart';

/// Repository interface for AI chat operations
abstract class AIChatRepository {
  /// Send a message and get a response
  Future<Either<Failure, ChatMessage>> sendMessage({
    required String message,
    required AIProvider provider,
    String? conversationId,
    Map<String, dynamic>? context,
  });

  /// Stream a response for a message
  Stream<Either<Failure, String>> streamResponse({
    required String message,
    required AIProvider provider,
    String? conversationId,
    Map<String, dynamic>? context,
  });

  /// Get chat history for a conversation
  Future<Either<Failure, Conversation>> getChatHistory(String conversationId);

  /// Get all conversations
  Future<Either<Failure, List<Conversation>>> getAllConversations();

  /// Save a conversation
  Future<Either<Failure, void>> saveConversation(Conversation conversation);

  /// Delete a conversation
  Future<Either<Failure, void>> deleteConversation(String conversationId);

  /// Clear all chat history
  Future<Either<Failure, void>> clearAllHistory();

  /// Check if a provider is available
  Future<Either<Failure, bool>> isProviderAvailable(AIProvider provider);

  /// Get the current rate limit status for a provider
  Future<Either<Failure, Map<String, dynamic>>> getRateLimitStatus(
    AIProvider provider,
  );

  /// Switch to a different AI provider
  Future<Either<Failure, void>> switchProvider(AIProvider provider);

  /// Get current active provider
  Future<Either<Failure, AIProvider>> getCurrentProvider();

  /// Upload a document for RAG
  Future<Either<Failure, String>> uploadDocument({
    required String filePath,
    required String documentId,
  });

  /// Query a document using RAG
  Future<Either<Failure, ChatMessage>> queryDocument({
    required String query,
    required String documentId,
    required AIProvider provider,
  });
}
