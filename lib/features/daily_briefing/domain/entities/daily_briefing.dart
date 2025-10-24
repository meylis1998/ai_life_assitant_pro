import 'package:equatable/equatable.dart';
import 'weather.dart';
import 'news_article.dart';
import 'calendar_event.dart';
import 'ai_insights.dart';

/// Aggregate root entity representing a complete daily briefing
class DailyBriefing extends Equatable {
  final String id;
  final DateTime generatedAt;
  final Weather? weather;
  final List<NewsArticle> topNews;
  final List<CalendarEvent> todayEvents;
  final AIInsights? insights;
  final String errorMessage; // Contains any error messages from failed data sources

  const DailyBriefing({
    required this.id,
    required this.generatedAt,
    this.weather,
    required this.topNews,
    required this.todayEvents,
    this.insights,
    this.errorMessage = '',
  });

  @override
  List<Object?> get props => [
        id,
        generatedAt,
        weather,
        topNews,
        todayEvents,
        insights,
        errorMessage,
      ];

  /// Check if briefing has any content
  bool get hasContent =>
      weather != null ||
      topNews.isNotEmpty ||
      todayEvents.isNotEmpty ||
      insights != null;

  /// Check if briefing is complete (all data sources successful)
  bool get isComplete =>
      weather != null && topNews.isNotEmpty && insights != null;

  /// Check if briefing is partial (some data sources failed)
  bool get isPartial => hasContent && !isComplete;

  /// Check if briefing has errors
  bool get hasErrors => errorMessage.isNotEmpty;

  /// Get count of data sources that succeeded
  int get successfulDataSources {
    var count = 0;
    if (weather != null) count++;
    if (topNews.isNotEmpty) count++;
    if (todayEvents.isNotEmpty) count++;
    if (insights != null) count++;
    return count;
  }

  /// Get count of today's events
  int get eventCount => todayEvents.length;

  /// Get count of news articles
  int get newsCount => topNews.length;

  /// Get upcoming events (next 2 hours)
  List<CalendarEvent> get upcomingEvents {
    final now = DateTime.now();
    final twoHoursFromNow = now.add(const Duration(hours: 2));
    return todayEvents
        .where((event) =>
            event.startTime.isAfter(now) &&
            event.startTime.isBefore(twoHoursFromNow))
        .toList();
  }

  /// Get ongoing events
  List<CalendarEvent> get ongoingEvents {
    return todayEvents.where((event) => event.isOngoing).toList();
  }
}
