import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/chat_message.dart';
import '../models/conversation_model.dart';

/// Contract for local data source
abstract class AIChatLocalDataSource {
  /// Get cached conversation
  Future<ConversationModel?> getCachedConversation(String conversationId);

  /// Get all cached conversations
  Future<List<ConversationModel>> getAllCachedConversations();

  /// Cache a conversation
  Future<void> cacheConversation(ConversationModel conversation);

  /// Delete cached conversation
  Future<void> deleteCachedConversation(String conversationId);

  /// Clear all cached conversations
  Future<void> clearAllCachedConversations();

  /// Get current provider preference
  Future<AIProvider> getCurrentProvider();

  /// Set current provider preference
  Future<void> setCurrentProvider(AIProvider provider);

  /// Get last conversation ID
  Future<String?> getLastConversationId();

  /// Set last conversation ID
  Future<void> setLastConversationId(String conversationId);
}

/// Implementation of local data source using SharedPreferences
class AIChatLocalDataSourceImpl implements AIChatLocalDataSource {
  final SharedPreferences sharedPreferences;

  static const String _conversationPrefix = 'conversation_';
  static const String _conversationListKey = 'conversation_list';
  static const String _currentProviderKey = AppConstants.aiProviderKey;
  static const String _lastConversationKey = 'last_conversation_id';

  AIChatLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<ConversationModel?> getCachedConversation(
    String conversationId,
  ) async {
    try {
      final key = '$_conversationPrefix$conversationId';
      final jsonString = sharedPreferences.getString(key);

      if (jsonString == null) {
        return null;
      }

      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return ConversationModel.fromJson(json);
    } catch (e) {
      AppLogger.e('Error getting cached conversation', error: e);
      throw const CacheException(message: 'Failed to get cached conversation');
    }
  }

  @override
  Future<List<ConversationModel>> getAllCachedConversations() async {
    try {
      final conversationIds =
          sharedPreferences.getStringList(_conversationListKey) ?? [];
      final conversations = <ConversationModel>[];

      for (final id in conversationIds) {
        final conversation = await getCachedConversation(id);
        if (conversation != null) {
          conversations.add(conversation);
        }
      }

      // Sort by updated date (most recent first)
      conversations.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      return conversations;
    } catch (e) {
      AppLogger.e('Error getting all cached conversations', error: e);
      throw const CacheException(message: 'Failed to get cached conversations');
    }
  }

  @override
  Future<void> cacheConversation(ConversationModel conversation) async {
    try {
      final key = '$_conversationPrefix${conversation.id}';
      final json = conversation.toJson();
      final jsonString = jsonEncode(json);

      await sharedPreferences.setString(key, jsonString);

      // Update conversation list
      final conversationIds =
          sharedPreferences.getStringList(_conversationListKey) ?? [];
      if (!conversationIds.contains(conversation.id)) {
        conversationIds.add(conversation.id);
        await sharedPreferences.setStringList(
          _conversationListKey,
          conversationIds,
        );
      }

      AppLogger.i('Cached conversation ${conversation.id}');
    } catch (e) {
      AppLogger.e('Error caching conversation', error: e);
      throw const CacheException(message: 'Failed to cache conversation');
    }
  }

  @override
  Future<void> deleteCachedConversation(String conversationId) async {
    try {
      final key = '$_conversationPrefix$conversationId';
      await sharedPreferences.remove(key);

      // Update conversation list
      final conversationIds =
          sharedPreferences.getStringList(_conversationListKey) ?? [];
      conversationIds.remove(conversationId);
      await sharedPreferences.setStringList(
        _conversationListKey,
        conversationIds,
      );

      AppLogger.i('Deleted cached conversation $conversationId');
    } catch (e) {
      AppLogger.e('Error deleting cached conversation', error: e);
      throw const CacheException(
        message: 'Failed to delete cached conversation',
      );
    }
  }

  @override
  Future<void> clearAllCachedConversations() async {
    try {
      final conversationIds =
          sharedPreferences.getStringList(_conversationListKey) ?? [];

      // Remove each conversation
      for (final id in conversationIds) {
        final key = '$_conversationPrefix$id';
        await sharedPreferences.remove(key);
      }

      // Clear the list
      await sharedPreferences.remove(_conversationListKey);

      AppLogger.i('Cleared all cached conversations');
    } catch (e) {
      AppLogger.e('Error clearing cached conversations', error: e);
      throw const CacheException(
        message: 'Failed to clear cached conversations',
      );
    }
  }

  @override
  Future<AIProvider> getCurrentProvider() async {
    try {
      final providerString = sharedPreferences.getString(_currentProviderKey);

      if (providerString == null) {
        return AIProvider.gemini; // Default provider
      }

      switch (providerString) {
        case 'gemini':
          return AIProvider.gemini;
        case 'claude':
          return AIProvider.claude;
        case 'openai':
          return AIProvider.openai;
        default:
          return AIProvider.gemini;
      }
    } catch (e) {
      AppLogger.e('Error getting current provider', error: e);
      return AIProvider.gemini; // Return default on error
    }
  }

  @override
  Future<void> setCurrentProvider(AIProvider provider) async {
    try {
      await sharedPreferences.setString(_currentProviderKey, provider.apiName);
      AppLogger.i('Set current provider to ${provider.displayName}');
    } catch (e) {
      AppLogger.e('Error setting current provider', error: e);
      throw const CacheException(message: 'Failed to set current provider');
    }
  }

  @override
  Future<String?> getLastConversationId() async {
    try {
      return sharedPreferences.getString(_lastConversationKey);
    } catch (e) {
      AppLogger.e('Error getting last conversation ID', error: e);
      return null;
    }
  }

  @override
  Future<void> setLastConversationId(String conversationId) async {
    try {
      await sharedPreferences.setString(_lastConversationKey, conversationId);
      AppLogger.i('Set last conversation ID to $conversationId');
    } catch (e) {
      AppLogger.e('Error setting last conversation ID', error: e);
      throw const CacheException(message: 'Failed to set last conversation ID');
    }
  }
}
