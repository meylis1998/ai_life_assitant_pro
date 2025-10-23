import 'package:hive/hive.dart';

import '../../domain/entities/daily_briefing.dart';
import 'calendar_event_model.dart';
import 'news_article_model.dart';
import 'weather_model.dart';

part 'daily_briefing_model.g.dart';

@HiveType(typeId: 10)
class DailyBriefingModel extends DailyBriefing {
  @HiveField(0)
  final String hiveId;

  @HiveField(1)
  final DateTime hiveGeneratedAt;

  @HiveField(2)
  final String hiveGreeting;

  @HiveField(3)
  final Map<String, dynamic> hiveWeather;

  @HiveField(4)
  final List<Map<String, dynamic>> hiveTopNews;

  @HiveField(5)
  final List<Map<String, dynamic>> hiveTodayEvents;

  @HiveField(6)
  final Map<String, dynamic> hiveInsights;

  DailyBriefingModel({
    required this.hiveId,
    required this.hiveGeneratedAt,
    required this.hiveGreeting,
    required this.hiveWeather,
    required this.hiveTopNews,
    required this.hiveTodayEvents,
    required this.hiveInsights,
  }) : super(
          id: hiveId,
          generatedAt: hiveGeneratedAt,
          greeting: hiveGreeting,
          weather: WeatherModel.fromJson(hiveWeather),
          topNews: hiveTopNews
              .map((json) => NewsArticleModel.fromJson(json))
              .toList(),
          todayEvents: hiveTodayEvents
              .map((json) => CalendarEventModel.fromJson(json))
              .toList(),
          insights: AIInsightsModel.fromJson(hiveInsights),
        );

  factory DailyBriefingModel.fromEntity(DailyBriefing briefing) {
    return DailyBriefingModel(
      hiveId: briefing.id,
      hiveGeneratedAt: briefing.generatedAt,
      hiveGreeting: briefing.greeting,
      hiveWeather: (briefing.weather as WeatherModel).toJson(),
      hiveTopNews: briefing.topNews
          .map((article) => (article as NewsArticleModel).toJson())
          .toList(),
      hiveTodayEvents: briefing.todayEvents
          .map((event) => (event as CalendarEventModel).toJson())
          .toList(),
      hiveInsights: (briefing.insights as AIInsightsModel).toJson(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': hiveId,
      'generatedAt': hiveGeneratedAt.toIso8601String(),
      'greeting': hiveGreeting,
      'weather': hiveWeather,
      'topNews': hiveTopNews,
      'todayEvents': hiveTodayEvents,
      'insights': hiveInsights,
    };
  }

  factory DailyBriefingModel.fromJson(Map<String, dynamic> json) {
    return DailyBriefingModel(
      hiveId: json['id'] as String,
      hiveGeneratedAt: DateTime.parse(json['generatedAt'] as String),
      hiveGreeting: json['greeting'] as String,
      hiveWeather: json['weather'] as Map<String, dynamic>,
      hiveTopNews: (json['topNews'] as List)
          .map((e) => e as Map<String, dynamic>)
          .toList(),
      hiveTodayEvents: (json['todayEvents'] as List)
          .map((e) => e as Map<String, dynamic>)
          .toList(),
      hiveInsights: json['insights'] as Map<String, dynamic>,
    );
  }
}

@HiveType(typeId: 11)
class AIInsightsModel extends AIInsights {
  @HiveField(0)
  final String hiveSummary;

  @HiveField(1)
  final List<String> hivePriorities;

  @HiveField(2)
  final String? hiveTrafficAlert;

  @HiveField(3)
  final List<String> hiveSuggestions;

  const AIInsightsModel({
    required this.hiveSummary,
    required this.hivePriorities,
    this.hiveTrafficAlert,
    required this.hiveSuggestions,
  }) : super(
          summary: hiveSummary,
          priorities: hivePriorities,
          trafficAlert: hiveTrafficAlert,
          suggestions: hiveSuggestions,
        );

  factory AIInsightsModel.fromJson(Map<String, dynamic> json) {
    return AIInsightsModel(
      hiveSummary: json['summary'] as String,
      hivePriorities: (json['priorities'] as List).cast<String>(),
      hiveTrafficAlert: json['trafficAlert'] as String?,
      hiveSuggestions: (json['suggestions'] as List).cast<String>(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'summary': hiveSummary,
      'priorities': hivePriorities,
      'trafficAlert': hiveTrafficAlert,
      'suggestions': hiveSuggestions,
    };
  }
}
