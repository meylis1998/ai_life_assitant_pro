import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/calendar_event.dart';
import '../entities/daily_briefing.dart';
import '../entities/news_article.dart';
import '../entities/weather.dart';

abstract class BriefingRepository {
  /// Get current weather data for the given location
  Future<Either<Failure, Weather>> getWeather({
    String? cityName,
    double? latitude,
    double? longitude,
  });

  /// Get top news headlines
  Future<Either<Failure, List<NewsArticle>>> getTopNews({
    String? category,
    String? country,
    int limit = 10,
  });

  /// Get today's calendar events
  Future<Either<Failure, List<CalendarEvent>>> getTodayEvents();

  /// Generate AI-powered insights based on briefing data
  Future<Either<Failure, AIInsights>> generateAIInsights({
    required Weather weather,
    required List<NewsArticle> news,
    required List<CalendarEvent> events,
    String? userName,
  });

  /// Generate complete daily briefing
  Future<Either<Failure, DailyBriefing>> generateDailyBriefing({
    String? userName,
    String? cityName,
    double? latitude,
    double? longitude,
  });

  /// Get cached briefing
  Future<Either<Failure, DailyBriefing>> getCachedBriefing();

  /// Cache briefing for offline access
  Future<Either<Failure, void>> cacheBriefing(DailyBriefing briefing);
}
