import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart'
    hide ServerException;

import '../../../../core/errors/exceptions.dart'
    show AIProviderException, RateLimitException;
import '../../../../core/errors/exceptions.dart' as app_exceptions;
import '../../../../core/network/api_client.dart';
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

/// Implementation of remote data source
class AIChatRemoteDataSourceImpl implements AIChatRemoteDataSource {
  final ApiClient apiClient;
  GenerativeModel? _geminiModel;
  ChatSession? _geminiChat;

  AIChatRemoteDataSourceImpl({required this.apiClient}) {
    _initializeProviders();
  }

  /// Initialize AI providers
  void _initializeProviders() {
    // Initialize Gemini
    final geminiKey = dotenv.env['GEMINI_API_KEY'];
    if (geminiKey != null && geminiKey.isNotEmpty) {
      _geminiModel = GenerativeModel(
        model: 'gemini-pro',
        apiKey: geminiKey,
        generationConfig: GenerationConfig(
          temperature: 0.7,
          topK: 40,
          topP: 0.95,
          maxOutputTokens: 8192,
        ),
      );
      AppLogger.i('Gemini model initialized');
    } else {
      AppLogger.w('Gemini API key not found');
    }
  }

  @override
  Future<ChatMessageModel> sendMessage({
    required String message,
    required AIProvider provider,
    List<ChatMessage>? history,
  }) async {
    try {
      AppLogger.i('Sending message to ${provider.displayName}');

      switch (provider) {
        case AIProvider.gemini:
          return await _sendGeminiMessage(message, history);
        case AIProvider.claude:
          return await _sendClaudeMessage(message, history);
        case AIProvider.openai:
          return await _sendOpenAIMessage(message, history);
      }
    } on GenerativeAIException catch (e) {
      AppLogger.e('Gemini API error', error: e);
      throw AIProviderException(provider: provider.apiName, message: e.message);
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

  @override
  Stream<String> streamResponse({
    required String message,
    required AIProvider provider,
    List<ChatMessage>? history,
  }) async* {
    try {
      AppLogger.i('Starting stream from ${provider.displayName}');

      switch (provider) {
        case AIProvider.gemini:
          yield* _streamGeminiResponse(message, history);
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

  @override
  Future<bool> isProviderAvailable(AIProvider provider) async {
    switch (provider) {
      case AIProvider.gemini:
        return _geminiModel != null;
      case AIProvider.claude:
        return dotenv.env['CLAUDE_API_KEY']?.isNotEmpty ?? false;
      case AIProvider.openai:
        return dotenv.env['OPENAI_API_KEY']?.isNotEmpty ?? false;
    }
  }

  /// Send message to Gemini
  Future<ChatMessageModel> _sendGeminiMessage(
    String message,
    List<ChatMessage>? history,
  ) async {
    if (_geminiModel == null) {
      throw const AIProviderException(
        provider: 'gemini',
        message: 'Gemini is not configured',
      );
    }

    // Build chat history
    final chatHistory = _buildGeminiHistory(history);

    // Create or get chat session
    _geminiChat ??= _geminiModel!.startChat(history: chatHistory);

    // Send message and get response
    final response = await _geminiChat!.sendMessage(Content.text(message));
    final responseText = response.text ?? '';

    return ChatMessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: responseText,
      role: MessageRole.assistant,
      timestamp: DateTime.now(),
      provider: AIProvider.gemini,
      status: MessageStatus.sent,
    );
  }

  /// Stream response from Gemini
  Stream<String> _streamGeminiResponse(
    String message,
    List<ChatMessage>? history,
  ) async* {
    if (_geminiModel == null) {
      throw const AIProviderException(
        provider: 'gemini',
        message: 'Gemini is not configured',
      );
    }

    // Build chat history
    final chatHistory = _buildGeminiHistory(history);

    // Create or get chat session
    _geminiChat ??= _geminiModel!.startChat(history: chatHistory);

    // Stream the response
    final response = _geminiChat!.sendMessageStream(Content.text(message));

    await for (final chunk in response) {
      final text = chunk.text;
      if (text != null) {
        yield text;
      }
    }
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

  /// Send message to Claude (placeholder - implement when API is available)
  Future<ChatMessageModel> _sendClaudeMessage(
    String message,
    List<ChatMessage>? history,
  ) async {
    final apiKey = dotenv.env['CLAUDE_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw const AIProviderException(
        provider: 'claude',
        message: 'Claude API key not configured',
      );
    }

    // TODO: Implement Claude API integration
    // For now, return a mock response
    await Future.delayed(const Duration(seconds: 1));

    return ChatMessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: 'Claude response to: $message (Not yet implemented)',
      role: MessageRole.assistant,
      timestamp: DateTime.now(),
      provider: AIProvider.claude,
      status: MessageStatus.sent,
    );
  }

  /// Stream response from Claude (placeholder)
  Stream<String> _streamClaudeResponse(
    String message,
    List<ChatMessage>? history,
  ) async* {
    // TODO: Implement Claude streaming
    yield 'Claude streaming response to: $message (Not yet implemented)';
  }

  /// Send message to OpenAI (placeholder - implement when API is available)
  Future<ChatMessageModel> _sendOpenAIMessage(
    String message,
    List<ChatMessage>? history,
  ) async {
    final apiKey = dotenv.env['OPENAI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw const AIProviderException(
        provider: 'openai',
        message: 'OpenAI API key not configured',
      );
    }

    // TODO: Implement OpenAI API integration
    // For now, return a mock response
    await Future.delayed(const Duration(seconds: 1));

    return ChatMessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: 'OpenAI response to: $message (Not yet implemented)',
      role: MessageRole.assistant,
      timestamp: DateTime.now(),
      provider: AIProvider.openai,
      status: MessageStatus.sent,
    );
  }

  /// Stream response from OpenAI (placeholder)
  Stream<String> _streamOpenAIResponse(
    String message,
    List<ChatMessage>? history,
  ) async* {
    // TODO: Implement OpenAI streaming
    yield 'OpenAI streaming response to: $message (Not yet implemented)';
  }
}
