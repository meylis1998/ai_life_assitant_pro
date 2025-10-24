import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/ai_insights.dart';
import '../entities/weather.dart';
import '../entities/news_article.dart';
import '../entities/calendar_event.dart';

/// Context data for AI insights generation
class AIInsightsContext {
  final Weather? weather;
  final List<NewsArticle> news;
  final List<CalendarEvent> events;
  final String? userName;
  final List<String>? userInterests;

  const AIInsightsContext({
    this.weather,
    required this.news,
    required this.events,
    this.userName,
    this.userInterests,
  });
}

/// Abstract repository interface for AI-generated insights
abstract class AIInsightsRepository {
  /// Generate personalized AI insights based on context
  ///
  /// Parameters:
  /// - [context]: Context data (weather, news, calendar, preferences)
  ///
  /// Returns:
  /// - Right(AIInsights) on success
  /// - Left(Failure) on error
  Future<Either<Failure, AIInsights>> generateInsights({
    required AIInsightsContext context,
  });
}
