import 'package:equatable/equatable.dart';

import 'calendar_event.dart';
import 'news_article.dart';
import 'weather.dart';

class DailyBriefing extends Equatable {
  final String id;
  final DateTime generatedAt;
  final String greeting;
  final Weather weather;
  final List<NewsArticle> topNews;
  final List<CalendarEvent> todayEvents;
  final AIInsights insights;

  const DailyBriefing({
    required this.id,
    required this.generatedAt,
    required this.greeting,
    required this.weather,
    required this.topNews,
    required this.todayEvents,
    required this.insights,
  });

  @override
  List<Object?> get props => [
        id,
        generatedAt,
        greeting,
        weather,
        topNews,
        todayEvents,
        insights,
      ];
}

class AIInsights extends Equatable {
  final String summary;
  final List<String> priorities;
  final String? trafficAlert;
  final List<String> suggestions;

  const AIInsights({
    required this.summary,
    required this.priorities,
    this.trafficAlert,
    required this.suggestions,
  });

  @override
  List<Object?> get props => [
        summary,
        priorities,
        trafficAlert,
        suggestions,
      ];
}
