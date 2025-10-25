import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/logger.dart';

/// HTTP-based Gemini API client for direct REST API access
/// Supports current Gemini models (2.5+) that aren't available in deprecated packages
class GeminiHttpService {
  final String apiKey;
  final http.Client client;
  final String baseUrl = 'https://generativelanguage.googleapis.com/v1beta';

  GeminiHttpService({required this.apiKey, required this.client});

  /// Generate content using Gemini REST API with automatic fallback
  Future<String> generateContent({
    required String model,
    required String prompt,
    double temperature = 0.7,
    int maxOutputTokens = 65536,
  }) async {
    // List of models to try in order (updated for 2025)
    // Note: Use exact model names from Google AI Studio
    final modelsToTry = [
      model, // Try requested model first
      'gemini-2.5-flash', // Fallback to stable flash
      'gemini-2.5-pro', // Fallback to pro version
      'gemini-2.0-flash', // Final fallback to 2.0 series
    ];

    Exception? lastException;

    for (int i = 0; i < modelsToTry.length; i++) {
      final currentModel = modelsToTry[i];

      try {
        return await _generateWithModel(
          model: currentModel,
          prompt: prompt,
          temperature: temperature,
          maxOutputTokens: maxOutputTokens,
          attemptNumber: i + 1,
        );
      } catch (e) {
        lastException = e as Exception;
        final shouldRetry = _shouldFallback(e);

        if (shouldRetry && i < modelsToTry.length - 1) {
          AppLogger.w('🔄 Falling back to next model due to: $e');
          await Future.delayed(Duration(milliseconds: 500 * (i + 1)));
          continue;
        } else {
          // No more fallbacks or non-retryable error
          break;
        }
      }
    }

    // All models failed
    throw lastException ?? Exception('All Gemini models failed');
  }

  /// Internal method to generate with a specific model
  Future<String> _generateWithModel({
    required String model,
    required String prompt,
    double temperature = 0.7,
    int maxOutputTokens = 65536,
    int attemptNumber = 1,
  }) async {
    final url = Uri.parse('$baseUrl/models/$model:generateContent?key=$apiKey');

    AppLogger.i('🎯 Attempt $attemptNumber: Calling Gemini API with $model');

    final response = await client.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': prompt},
            ],
          },
        ],
        'generationConfig': {
          'temperature': temperature,
          'maxOutputTokens': maxOutputTokens,
        },
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final text =
          data['candidates']?[0]?['content']?['parts']?[0]?['text']
              as String?;

      if (text == null) {
        throw Exception('No text generated in response');
      }

      AppLogger.i('✅ Success with $model - Generated ${text.length} characters');
      return text;
    } else if (response.statusCode == 404) {
      final errorBody = jsonDecode(response.body);
      final errorMessage =
          errorBody['error']?['message'] ?? 'Model not found';
      throw Exception('Model $model not found: $errorMessage');
    } else if (response.statusCode == 429) {
      throw Exception('Rate limit exceeded. Please try again later.');
    } else {
      final errorBody = jsonDecode(response.body);
      final errorMessage = errorBody['error']?['message'] ?? 'Unknown error';
      throw Exception('API error (${response.statusCode}): $errorMessage');
    }
  }

  /// Check if error warrants fallback to next model
  bool _shouldFallback(dynamic error) {
    final message = error.toString().toLowerCase();
    return message.contains('overloaded') ||
        message.contains('503') ||
        message.contains('rate limit') ||
        message.contains('429') ||
        message.contains('unavailable') ||
        message.contains('resource exhausted') ||
        message.contains('quota') ||
        message.contains('not found') ||
        message.contains('404');
  }

  /// Stream content using Gemini REST API
  Stream<String> streamContent({
    required String model,
    required String prompt,
    double temperature = 0.7,
    int maxOutputTokens = 65536,
  }) async* {
    final url = Uri.parse(
      '$baseUrl/models/$model:streamGenerateContent?key=$apiKey&alt=sse',
    );

    try {
      AppLogger.i('🔄 Streaming from Gemini API: $model');

      final request = http.Request('POST', url)
        ..headers.addAll({'Content-Type': 'application/json'})
        ..body = jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt},
              ],
            },
          ],
          'generationConfig': {
            'temperature': temperature,
            'maxOutputTokens': maxOutputTokens,
          },
        });

      final streamedResponse = await client.send(request);

      if (streamedResponse.statusCode != 200) {
        final responseBody = await streamedResponse.stream.bytesToString();
        throw Exception(
          'Stream error (${streamedResponse.statusCode}): $responseBody',
        );
      }

      await for (final chunk in streamedResponse.stream.transform(
        utf8.decoder,
      )) {
        // Parse SSE format: data: {...}
        final lines = chunk.split('\n');
        for (final line in lines) {
          if (line.startsWith('data: ')) {
            final jsonStr = line.substring(6).trim();
            if (jsonStr.isEmpty || jsonStr == '[DONE]') continue;

            try {
              final data = jsonDecode(jsonStr);
              final text =
                  data['candidates']?[0]?['content']?['parts']?[0]?['text']
                      as String?;
              if (text != null && text.isNotEmpty) {
                yield text;
              }
            } catch (e) {
              AppLogger.w('Failed to parse chunk: $e');
            }
          }
        }
      }

      AppLogger.i('✅ Stream completed');
    } catch (e) {
      AppLogger.e('Gemini stream error', error: e);
      rethrow;
    }
  }

  /// List available models
  Future<List<String>> listModels() async {
    final url = Uri.parse('$baseUrl/models?key=$apiKey');

    try {
      final response = await client.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final models =
            (data['models'] as List?)
                ?.map((m) => m['name'] as String)
                .where((name) => name.contains('gemini'))
                .map((name) => name.replaceAll('models/', ''))
                .toList() ??
            [];

        AppLogger.i('📋 Available models: ${models.join(', ')}');
        return models;
      } else {
        throw Exception('Failed to list models: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.e('Failed to list models', error: e);
      return [];
    }
  }
}
