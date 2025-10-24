import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/ai_insights.dart';

part 'ai_insights_model.g.dart';

@JsonSerializable()
class AIInsightsModel extends AIInsights {
  const AIInsightsModel({
    required super.greeting,
    required super.summary,
    required super.priorities,
    required super.suggestions,
    super.weatherAlert,
    super.trafficAlert,
    required super.generatedAt,
  });

  factory AIInsightsModel.fromJson(Map<String, dynamic> json) =>
      _$AIInsightsModelFromJson(json);

  Map<String, dynamic> toJson() => _$AIInsightsModelToJson(this);

  /// Parse insights from Gemini AI response text
  ///
  /// Expected format:
  /// GREETING: <greeting text>
  /// SUMMARY: <summary text>
  /// PRIORITIES:
  /// - <priority 1>
  /// - <priority 2>
  /// - <priority 3>
  /// SUGGESTIONS:
  /// - <suggestion 1>
  /// - <suggestion 2>
  /// WEATHER_ALERT: <alert text or NONE>
  /// TRAFFIC_ALERT: <alert text or NONE>
  factory AIInsightsModel.fromGeminiResponse(String responseText) {
    try {
      final lines = responseText.split('\n').map((l) => l.trim()).toList();

      String? greeting;
      String? summary;
      final priorities = <String>[];
      final suggestions = <String>[];
      String? weatherAlert;
      String? trafficAlert;

      String? currentSection;

      for (final line in lines) {
        if (line.isEmpty) continue;

        if (line.startsWith('GREETING:')) {
          greeting = line.substring('GREETING:'.length).trim();
          currentSection = null;
        } else if (line.startsWith('SUMMARY:')) {
          summary = line.substring('SUMMARY:'.length).trim();
          currentSection = null;
        } else if (line.startsWith('PRIORITIES:')) {
          currentSection = 'PRIORITIES';
        } else if (line.startsWith('SUGGESTIONS:')) {
          currentSection = 'SUGGESTIONS';
        } else if (line.startsWith('WEATHER_ALERT:')) {
          final alert = line.substring('WEATHER_ALERT:'.length).trim();
          weatherAlert = alert == 'NONE' ? null : alert;
          currentSection = null;
        } else if (line.startsWith('TRAFFIC_ALERT:')) {
          final alert = line.substring('TRAFFIC_ALERT:'.length).trim();
          trafficAlert = alert == 'NONE' ? null : alert;
          currentSection = null;
        } else if (line.startsWith('- ') || line.startsWith('• ')) {
          final item = line.substring(2).trim();
          if (currentSection == 'PRIORITIES' && priorities.length < 3) {
            priorities.add(item);
          } else if (currentSection == 'SUGGESTIONS' && suggestions.length < 3) {
            suggestions.add(item);
          }
        }
      }

      return AIInsightsModel(
        greeting: greeting ?? 'Good day!',
        summary: summary ?? 'Have a productive day ahead.',
        priorities: priorities.isNotEmpty
            ? priorities
            : ['Check your calendar', 'Stay updated with news'],
        suggestions: suggestions.isNotEmpty
            ? suggestions
            : ['Take breaks throughout the day'],
        weatherAlert: weatherAlert,
        trafficAlert: trafficAlert,
        generatedAt: DateTime.now(),
      );
    } catch (e) {
      // Fallback to default insights if parsing fails
      return AIInsightsModel(
        greeting: 'Good day!',
        summary: 'Here\'s your daily briefing.',
        priorities: ['Review today\'s schedule'],
        suggestions: ['Stay focused and productive'],
        generatedAt: DateTime.now(),
      );
    }
  }

  AIInsights toEntity() => AIInsights(
        greeting: greeting,
        summary: summary,
        priorities: priorities,
        suggestions: suggestions,
        weatherAlert: weatherAlert,
        trafficAlert: trafficAlert,
        generatedAt: generatedAt,
      );

  /// Create model from entity
  factory AIInsightsModel.fromEntity(AIInsights entity) {
    return AIInsightsModel(
      greeting: entity.greeting,
      summary: entity.summary,
      priorities: entity.priorities,
      suggestions: entity.suggestions,
      weatherAlert: entity.weatherAlert,
      trafficAlert: entity.trafficAlert,
      generatedAt: entity.generatedAt,
    );
  }
}
