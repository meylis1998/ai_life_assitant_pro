import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/ai_insights_model.dart';
import '../../domain/repositories/ai_insights_repository.dart';

/// Remote data source for AI-generated insights using Google Gemini API
abstract class AIInsightsDataSource {
  /// Generate personalized AI insights based on context
  Future<AIInsightsModel> generateInsights({
    required AIInsightsContext context,
  });
}

class AIInsightsDataSourceImpl implements AIInsightsDataSource {
  String get _apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';

  @override
  Future<AIInsightsModel> generateInsights({
    required AIInsightsContext context,
  }) async {
    try {
      // List of models to try in order (updated for 2025)
      final modelsToTry = [
        'gemini-2.5-flash',
        'gemini-2.5-flash-lite',
        'gemini-2.0-flash',
      ];

      Exception? lastException;

      for (final modelName in modelsToTry) {
        try {
          // Initialize Gemini API
          final model = GenerativeModel(
            model: modelName,
            apiKey: _apiKey,
          );

          // Build the prompt
          final prompt = _buildPrompt(context);

          // Generate content with timeout
          final response = await model.generateContent([Content.text(prompt)])
              .timeout(const Duration(seconds: 30));

          if (response.text == null || response.text!.isEmpty) {
            throw Exception('Empty response from Gemini API');
          }

          // Parse the response
          return AIInsightsModel.fromGeminiResponse(response.text!);
        } catch (e) {
          lastException = e as Exception;
          print('Failed to use model $modelName: $e');
          // Try next model if this one fails
          continue;
        }
      }

      // All models failed - return a fallback response
      print('All Gemini models failed, creating fallback insights');
      return _createFallbackInsights(context);
    } catch (e) {
      // Create fallback insights if everything fails
      return _createFallbackInsights(context);
    }
  }

  /// Create fallback AI insights when Gemini API is unavailable
  AIInsightsModel _createFallbackInsights(AIInsightsContext context) {
    final greeting = context.userName != null
        ? 'Good morning, ${context.userName}!'
        : 'Good morning!';

    final summary = context.weather != null
        ? 'Today looks like a ${context.weather!.condition.toLowerCase()} day with temperatures around ${context.weather!.temperature.round()}°C.'
        : 'Hope you have a wonderful day ahead!';

    final priorities = <String>[
      if (context.events.isNotEmpty) 'Check your calendar - you have ${context.events.length} event${context.events.length > 1 ? 's' : ''} today',
      if (context.weather != null && context.weather!.temperature < 10) 'Dress warmly - it\'s quite cold today',
      'Stay hydrated and take breaks throughout the day',
    ];

    final suggestions = <String>[
      if (context.weather != null && context.weather!.condition.toLowerCase().contains('rain')) 'Don\'t forget your umbrella!',
      if (context.news.isNotEmpty) 'Check the latest news when you have time',
      'Take a moment to plan your day',
    ];

    // Create a simple insights response
    final insightsText = '''
GREETING: $greeting
SUMMARY: $summary
PRIORITIES:
${priorities.map((p) => '- $p').join('\n')}
SUGGESTIONS:
${suggestions.map((s) => '- $s').join('\n')}
WEATHER_ALERT: NONE
TRAFFIC_ALERT: NONE
    '''.trim();

    return AIInsightsModel.fromGeminiResponse(insightsText);
  }

  String _buildPrompt(AIInsightsContext context) {
    final buffer = StringBuffer();

    buffer.writeln('Generate a personalized daily briefing based on the following information:');
    buffer.writeln();

    // Weather section
    if (context.weather != null) {
      final weather = context.weather!;
      buffer.writeln('WEATHER:');
      buffer.writeln('- Location: ${weather.location}');
      buffer.writeln('- Temperature: ${weather.temperature.toStringAsFixed(1)}°C (Feels like ${weather.feelsLike.toStringAsFixed(1)}°C)');
      buffer.writeln('- Condition: ${weather.condition}');
      buffer.writeln('- Humidity: ${weather.humidity}%');
      buffer.writeln('- Wind Speed: ${weather.windSpeed} m/s');
      if (weather.forecast.isNotEmpty) {
        buffer.writeln('- Forecast: ${weather.forecast.first.condition} with temperatures ${weather.forecast.first.minTemperature.toStringAsFixed(0)}°-${weather.forecast.first.maxTemperature.toStringAsFixed(0)}°C');
      }
      buffer.writeln();
    }

    // Calendar section
    if (context.events.isNotEmpty) {
      buffer.writeln('TODAY\'S CALENDAR (${context.events.length} events):');
      for (final event in context.events.take(5)) {
        final timeStr = event.isAllDay
            ? 'All day'
            : '${event.startTime.hour}:${event.startTime.minute.toString().padLeft(2, '0')}';
        buffer.writeln('- $timeStr: ${event.title}${event.location != null ? " at ${event.location}" : ""}');
      }
      buffer.writeln();
    }

    // News section
    if (context.news.isNotEmpty) {
      buffer.writeln('TOP NEWS HEADLINES:');
      for (final article in context.news.take(3)) {
        buffer.writeln('- ${article.title} (${article.source})');
      }
      buffer.writeln();
    }

    // User context
    if (context.userName != null) {
      buffer.writeln('USER: ${context.userName}');
    }
    if (context.userInterests != null && context.userInterests!.isNotEmpty) {
      buffer.writeln('INTERESTS: ${context.userInterests!.join(", ")}');
    }

    buffer.writeln();
    buffer.writeln('Please provide a personalized daily briefing in EXACTLY this format:');
    buffer.writeln();
    buffer.writeln('GREETING: <A warm, personalized greeting>');
    buffer.writeln('SUMMARY: <A brief 1-2 sentence summary of the day ahead>');
    buffer.writeln('PRIORITIES:');
    buffer.writeln('- <Top priority 1>');
    buffer.writeln('- <Top priority 2>');
    buffer.writeln('- <Top priority 3>');
    buffer.writeln('SUGGESTIONS:');
    buffer.writeln('- <Actionable suggestion 1>');
    buffer.writeln('- <Actionable suggestion 2>');
    buffer.writeln('- <Actionable suggestion 3>');
    buffer.writeln('WEATHER_ALERT: <Any weather-related alert or "NONE">');
    buffer.writeln('TRAFFIC_ALERT: <Any traffic/commute alert or "NONE">');
    buffer.writeln();
    buffer.writeln('Make it friendly, concise, and actionable. Focus on what matters for today.');

    return buffer.toString();
  }
}
