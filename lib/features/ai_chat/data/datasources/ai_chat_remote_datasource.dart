import 'dart:async';

import 'package:dio/dio.dart';
import 'package:google_generative_ai/google_generative_ai.dart'
    hide ServerException;

import '../../../../core/errors/exceptions.dart'
    show AIProviderException, RateLimitException;
import '../../../../core/errors/exceptions.dart' as app_exceptions;
import '../../../../core/network/api_client.dart';
import '../../../../core/services/api_key_service.dart';
import '../../../../core/services/gemini_model_manager.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/chat_message.dart';
import '../models/chat_message_model.dart';

/// Contract for remote data source
abstract class AIChatRemoteDataSource {
  /// Send a message to AI provider
  Future<ChatMessageModel> sendMessage({
    required String message,
    required AIProvider provider,
    List<ChatMessage>? history,
  });

  /// Stream a response from AI provider
  Stream<String> streamResponse({
    required String message,
    required AIProvider provider,
    List<ChatMessage>? history,
  });

  /// Check if provider is available
  Future<bool> isProviderAvailable(AIProvider provider);
}

/// Implementation of remote data source with multi-model fallback
class AIChatRemoteDataSourceImpl implements AIChatRemoteDataSource {
  final ApiClient apiClient;
  final ApiKeyService apiKeyService;
  final GeminiModelManager modelManager;

  /// Cache of initialized Gemini models
  final Map<String, GenerativeModel> _modelCache = {};

  /// Cache of chat sessions per model
  final Map<String, ChatSession> _chatSessions = {};

  AIChatRemoteDataSourceImpl({
    required this.apiClient,
    required this.apiKeyService,
    required this.modelManager,
  });

  /// Initialize Gemini model with specific model name
  Future<GenerativeModel> _initializeGeminiWithModel(String modelName) async {
    // Return cached model if available
    if (_modelCache.containsKey(modelName)) {
      AppLogger.i('♻️  Using cached model: $modelName');
      return _modelCache[modelName]!;
    }

    final apiKey = await apiKeyService.getGeminiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw const AIProviderException(
        provider: 'gemini',
        message:
            'Gemini API key not configured. Please add your API key in Settings.',
      );
    }

    AppLogger.i('🔧 Initializing new model: $modelName');
    final model = GenerativeModel(
      model: modelName,
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: 0.7,
        topK: 40,
        topP: 0.95,
        maxOutputTokens: 8192,
      ),
    );

    _modelCache[modelName] = model;
    return model;
  }

  @override
  Future<ChatMessageModel> sendMessage({
    required String message,
    required AIProvider provider,
    List<ChatMessage>? history,
  }) async {
    try {
      AppLogger.i('📤 Sending message to ${provider.displayName}');

      switch (provider) {
        case AIProvider.gemini:
          return await _sendGeminiMessageWithFallback(message, history);
        case AIProvider.claude:
          return await _sendClaudeMessage(message, history);
        case AIProvider.openai:
          return await _sendOpenAIMessage(message, history);
      }
    } on AIProviderException {
      rethrow;
    } on RateLimitException {
      rethrow;
    } on DioException catch (e) {
      AppLogger.e('Network error', error: e);
      if (e.response?.statusCode == 429) {
        throw RateLimitException(
          provider: provider.apiName,
          message: 'Rate limit exceeded. Please try again later.',
        );
      }
      throw app_exceptions.ServerException(
        message: e.response?.data?['error'] ?? 'Network error occurred',
        code: e.response?.statusCode,
      );
    } catch (e) {
      AppLogger.e('Unexpected error', error: e);
      throw AIProviderException(
        provider: provider.apiName,
        message: 'Failed to send message: $e',
      );
    }
  }

  /// Send message with automatic fallback through model chain
  Future<ChatMessageModel> _sendGeminiMessageWithFallback(
    String message,
    List<ChatMessage>? history, {
    int attemptCount = 0,
  }) async {
    final startTime = DateTime.now();

    // Get next available model
    final modelConfig = modelManager.getNextModel(
      excludeModel: attemptCount > 0 ? modelManager.lastAttemptedModel : null,
      currentAttempt: attemptCount,
    );

    if (modelConfig == null) {
      AppLogger.e('❌ All Gemini models exhausted');
      throw const AIProviderException(
        provider: 'gemini',
        message:
            'All Gemini models are currently unavailable. Please try again later.',
      );
    }

    AppLogger.i(
      '🎯 Attempt ${attemptCount + 1}: Using ${modelConfig.modelName}',
    );

    try {
      final model = await _initializeGeminiWithModel(modelConfig.modelName);
      final chatHistory = _buildGeminiHistory(history);

      // Create or get chat session for this model
      final sessionKey = '${modelConfig.modelName}_session';
      _chatSessions[sessionKey] ??= model.startChat(history: chatHistory);
      final chat = _chatSessions[sessionKey]!;

      // Send message and get response
      final response = await chat.sendMessage(Content.text(message));
      final responseText = response.text ?? '';

      // Mark success
      modelManager.markModelSuccess(modelConfig.modelName);

      final responseTime = DateTime.now().difference(startTime).inMilliseconds;
      AppLogger.i(
        '✅ Success with ${modelConfig.modelName} (${responseTime}ms)',
      );

      return ChatMessageModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: responseText,
        role: MessageRole.assistant,
        timestamp: DateTime.now(),
        provider: AIProvider.gemini,
        status: MessageStatus.sent,
        metadata: {
          'model_used': modelConfig.modelName,
          'attempt_count': attemptCount + 1,
          'fallback_occurred': attemptCount > 0,
          'response_time_ms': responseTime,
          'model_generation': modelConfig.generation,
        },
      );
    } on GenerativeAIException catch (e) {
      AppLogger.e('${modelConfig.modelName} error', error: e);

      // Check if should fallback
      if (_shouldFallback(e)) {
        modelManager.markModelFailed(
          modelConfig.modelName,
          const Duration(minutes: 5),
        );

        // Try next model if available
        if (attemptCount < 3) {
          AppLogger.i('🔄 Falling back to next model...');
          await Future.delayed(
            Duration(milliseconds: 500 * (attemptCount + 1)),
          );
          return await _sendGeminiMessageWithFallback(
            message,
            history,
            attemptCount: attemptCount + 1,
          );
        }
      }

      // No more fallbacks or non-fallback error
      throw AIProviderException(
        provider: 'gemini',
        message: e.message,
      );
    }
  }

  @override
  Stream<String> streamResponse({
    required String message,
    required AIProvider provider,
    List<ChatMessage>? history,
  }) async* {
    try {
      AppLogger.i('📡 Starting stream from ${provider.displayName}');

      switch (provider) {
        case AIProvider.gemini:
          yield* _streamGeminiResponseWithFallback(message, history);
          break;
        case AIProvider.claude:
          yield* _streamClaudeResponse(message, history);
          break;
        case AIProvider.openai:
          yield* _streamOpenAIResponse(message, history);
          break;
      }
    } catch (e) {
      AppLogger.e('Stream error', error: e);
      throw AIProviderException(
        provider: provider.apiName,
        message: 'Stream failed: $e',
      );
    }
  }

  /// Stream response with automatic fallback through model chain
  Stream<String> _streamGeminiResponseWithFallback(
    String message,
    List<ChatMessage>? history, {
    int attemptCount = 0,
  }) async* {
    // Get next available model
    final modelConfig = modelManager.getNextModel(
      excludeModel: attemptCount > 0 ? modelManager.lastAttemptedModel : null,
      currentAttempt: attemptCount,
    );

    if (modelConfig == null) {
      AppLogger.e('❌ All Gemini models exhausted');
      throw const AIProviderException(
        provider: 'gemini',
        message:
            'All Gemini models are currently unavailable. Please try again later.',
      );
    }

    AppLogger.i(
      '🎯 Stream attempt ${attemptCount + 1}: Using ${modelConfig.modelName}',
    );

    try {
      final model = await _initializeGeminiWithModel(modelConfig.modelName);
      final chatHistory = _buildGeminiHistory(history);

      // Create or get chat session
      final sessionKey = '${modelConfig.modelName}_session';
      _chatSessions[sessionKey] ??= model.startChat(history: chatHistory);
      final chat = _chatSessions[sessionKey]!;

      // Stream the response
      final response = chat.sendMessageStream(Content.text(message));
      bool hadData = false;

      await for (final chunk in response) {
        final text = chunk.text;
        if (text != null) {
          yield text;
          hadData = true;
        }
      }

      if (hadData) {
        modelManager.markModelSuccess(modelConfig.modelName);
        AppLogger.i('✅ Stream completed with ${modelConfig.modelName}');
      }
    } on GenerativeAIException catch (e) {
      AppLogger.e('${modelConfig.modelName} stream error', error: e);

      // Check if should fallback
      if (_shouldFallback(e) && attemptCount < 3) {
        modelManager.markModelFailed(
          modelConfig.modelName,
          const Duration(minutes: 5),
        );

        AppLogger.i('🔄 Stream fallback to next model...');
        await Future.delayed(Duration(milliseconds: 500 * (attemptCount + 1)));

        // Recursively try next model
        yield* _streamGeminiResponseWithFallback(
          message,
          history,
          attemptCount: attemptCount + 1,
        );
      } else {
        // No more fallbacks or non-fallback error
        throw AIProviderException(
          provider: 'gemini',
          message: e.message,
        );
      }
    }
  }

  /// Check if error warrants fallback to next model
  bool _shouldFallback(GenerativeAIException error) {
    final message = error.message.toLowerCase();
    return message.contains('rate limit') ||
        message.contains('quota') ||
        message.contains('not found') ||
        message.contains('resource exhausted') ||
        message.contains('429') ||
        message.contains('503') ||
        message.contains('unavailable') ||
        message.contains('overloaded');
  }

  /// Build Gemini chat history
  List<Content> _buildGeminiHistory(List<ChatMessage>? history) {
    if (history == null || history.isEmpty) return [];

    return history.map((msg) {
      return Content(msg.role == MessageRole.user ? 'user' : 'model', [
        TextPart(msg.content),
      ]);
    }).toList();
  }

  /// Clear all cached models and sessions
  void clearCache() {
    _modelCache.clear();
    _chatSessions.clear();
    AppLogger.i('🗑️  Cleared model cache and sessions');
  }

  @override
  Future<bool> isProviderAvailable(AIProvider provider) async {
    switch (provider) {
      case AIProvider.gemini:
        return await apiKeyService.hasGeminiKey();
      case AIProvider.claude:
        return await apiKeyService.hasClaudeKey();
      case AIProvider.openai:
        return await apiKeyService.hasOpenAIKey();
    }
  }

  /// Send message to Claude (placeholder - implement when API is available)
  Future<ChatMessageModel> _sendClaudeMessage(
    String message,
    List<ChatMessage>? history,
  ) async {
    throw const AIProviderException(
      provider: 'claude',
      message: 'Claude API key not configured. Please add your API key in settings.',
    );
  }

  /// Stream response from Claude (placeholder)
  Stream<String> _streamClaudeResponse(
    String message,
    List<ChatMessage>? history,
  ) async* {
    yield 'Claude streaming response to: $message (Not yet implemented)';
  }

  /// Send message to OpenAI (placeholder - implement when API is available)
  Future<ChatMessageModel> _sendOpenAIMessage(
    String message,
    List<ChatMessage>? history,
  ) async {
    throw const AIProviderException(
      provider: 'openai',
      message: 'OpenAI API key not configured. Please add your API key in settings.',
    );
  }

  /// Stream response from OpenAI (placeholder)
  Stream<String> _streamOpenAIResponse(
    String message,
    List<ChatMessage>? history,
  ) async* {
    yield 'OpenAI streaming response to: $message (Not yet implemented)';
  }
}
