import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/services/gemini_http_service.dart';
import '../../domain/entities/calendar_event.dart';
import '../../domain/entities/daily_briefing.dart';
import '../../domain/entities/news_article.dart';
import '../../domain/entities/weather.dart';
import '../../domain/repositories/briefing_repository.dart';
import '../datasources/briefing_cache_datasource.dart';
import '../datasources/calendar_local_datasource.dart';
import '../datasources/news_api_datasource.dart';
import '../datasources/weather_api_datasource.dart';
import '../models/calendar_event_model.dart';
import '../models/daily_briefing_model.dart';
import '../models/news_article_model.dart';
import '../models/weather_model.dart';

class BriefingRepositoryImpl implements BriefingRepository {
  final WeatherApiDataSource weatherDataSource;
  final NewsApiDataSource newsDataSource;
  final CalendarLocalDataSource calendarDataSource;
  final BriefingCacheDataSource cacheDataSource;
  final NetworkInfo networkInfo;
  final GeminiHttpService geminiService;

  BriefingRepositoryImpl({
    required this.weatherDataSource,
    required this.newsDataSource,
    required this.calendarDataSource,
    required this.cacheDataSource,
    required this.networkInfo,
    required this.geminiService,
  });

  @override
  Future<Either<Failure, Weather>> getWeather({
    String? cityName,
    double? latitude,
    double? longitude,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final weather = await weatherDataSource.getCurrentWeather(
        cityName: cityName,
        latitude: latitude,
        longitude: longitude,
      );

      final forecast = await weatherDataSource.getForecast(
        cityName: cityName,
        latitude: latitude,
        longitude: longitude,
      );

      // Create weather with forecast
      final weatherWithForecast = WeatherModel(
        temperature: weather.temperature,
        feelsLike: weather.feelsLike,
        condition: weather.condition,
        description: weather.description,
        humidity: weather.humidity,
        windSpeed: weather.windSpeed,
        pressure: weather.pressure,
        cityName: weather.cityName,
        forecast: forecast,
      );

      return Right(weatherWithForecast);
    } catch (e) {
      return Left(WeatherFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<NewsArticle>>> getTopNews({
    String? category,
    String? country,
    int limit = 10,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final news = await newsDataSource.getTopHeadlines(
        category: category,
        country: country,
        limit: limit,
      );
      return Right(news);
    } catch (e) {
      return Left(NewsFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<CalendarEvent>>> getTodayEvents() async {
    try {
      final events = await calendarDataSource.getTodayEvents();
      return Right(events);
    } catch (e) {
      return Left(CalendarFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, AIInsights>> generateAIInsights({
    required Weather weather,
    required List<NewsArticle> news,
    required List<CalendarEvent> events,
    String? userName,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      // Build context for AI
      final weatherContext =
          '${weather.condition} with temperature ${weather.temperature}°C (feels like ${weather.feelsLike}°C), ${weather.description}';

      final eventsContext = events.isEmpty
          ? 'No events scheduled for today'
          : events
              .map((e) =>
                  '- ${e.title} at ${_formatTime(e.startTime)}${e.location != null ? ' (${e.location})' : ''}')
              .join('\n');

      final newsContext = news
          .take(5)
          .map((n) => '- ${n.title} (${n.source})')
          .join('\n');

      // Create prompt for AI
      final prompt = '''
Based on the following information, generate a personalized daily briefing:

WEATHER:
$weatherContext in ${weather.cityName}

TODAY'S CALENDAR:
$eventsContext

TOP NEWS:
$newsContext

${userName != null ? 'USER: $userName\n' : ''}

Please provide:
1. A warm, personalized greeting ${userName != null ? 'using their name' : ''}
2. Top 3 priorities or recommendations for the day based on weather and schedule
3. Any weather-related alerts or preparation tips
4. 2-3 personalized suggestions based on the news and schedule

Format your response as JSON with these keys:
{
  "greeting": "warm greeting message",
  "priorities": ["priority 1", "priority 2", "priority 3"],
  "trafficAlert": "weather alert or null",
  "suggestions": ["suggestion 1", "suggestion 2"]
}
''';

      // Use HTTP service with gemini-2.5-flash model
      final aiText = await geminiService.generateContent(
        model: 'gemini-2.5-flash',
        prompt: prompt,
        temperature: 0.7,
        maxOutputTokens: 2048,
      );

      // Parse AI response
      final insights = _parseAIInsights(aiText, userName);

      return Right(insights);
    } catch (e) {
      return Left(AIProviderFailure(message: 'Failed to generate insights: $e'));
    }
  }

  @override
  Future<Either<Failure, DailyBriefing>> generateDailyBriefing({
    String? userName,
    String? cityName,
    double? latitude,
    double? longitude,
  }) async {
    try {
      // Fetch weather
      final weatherResult = await getWeather(
        cityName: cityName,
        latitude: latitude,
        longitude: longitude,
      );
      if (weatherResult.isLeft()) {
        return Left((weatherResult as Left).value);
      }
      final weather = (weatherResult as Right).value as Weather;

      // Fetch news
      final newsResult = await getTopNews(limit: 10);
      if (newsResult.isLeft()) {
        return Left((newsResult as Left).value);
      }
      final news = (newsResult as Right).value as List<NewsArticle>;

      // Fetch calendar events
      final eventsResult = await getTodayEvents();
      final events = eventsResult.fold(
        (failure) => <CalendarEvent>[], // Continue even if calendar fails
        (events) => events,
      );

      // Generate AI insights
      final insightsResult = await generateAIInsights(
        weather: weather,
        news: news,
        events: events,
        userName: userName,
      );
      if (insightsResult.isLeft()) {
        return Left((insightsResult as Left).value);
      }
      final insights = (insightsResult as Right).value as AIInsights;

      // Create briefing
      final briefing = DailyBriefingModel(
        hiveId: const Uuid().v4(),
        hiveGeneratedAt: DateTime.now(),
        hiveGreeting: insights.summary,
        hiveWeather: (weather as WeatherModel).toJson(),
        hiveTopNews: news.map((n) => (n as NewsArticleModel).toJson()).toList(),
        hiveTodayEvents:
            events.map((e) => (e as CalendarEventModel).toJson()).toList(),
        hiveInsights: (insights as AIInsightsModel).toJson(),
      );

      // Cache the briefing
      await cacheDataSource.cacheBriefing(briefing);

      return Right(briefing);
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to generate briefing: $e'));
    }
  }

  @override
  Future<Either<Failure, DailyBriefing>> getCachedBriefing() async {
    try {
      final briefing = await cacheDataSource.getLastBriefing();
      return Right(briefing);
    } catch (e) {
      return const Left(CacheFailure(message: 'No cached briefing available'));
    }
  }

  @override
  Future<Either<Failure, void>> cacheBriefing(DailyBriefing briefing) async {
    try {
      final model = DailyBriefingModel.fromEntity(briefing);
      await cacheDataSource.cacheBriefing(model);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to cache briefing: $e'));
    }
  }

  // Helper methods
  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour;
    final amPm = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '${hour == 0 ? 12 : hour}:${dateTime.minute.toString().padLeft(2, '0')} $amPm';
  }

  AIInsightsModel _parseAIInsights(String aiText, String? userName) {
    try {
      // Try to extract JSON from the response
      final jsonStart = aiText.indexOf('{');
      final jsonEnd = aiText.lastIndexOf('}');

      if (jsonStart != -1 && jsonEnd != -1) {
        final jsonText = aiText.substring(jsonStart, jsonEnd + 1);
        final parsedJson = json.decode(jsonText) as Map<String, dynamic>;
        return AIInsightsModel.fromJson(parsedJson);
      }
    } catch (e) {
      // Fallback parsing if JSON fails
    }

    // Fallback: create basic insights from text
    final greeting = userName != null
        ? 'Good morning, $userName!'
        : 'Good morning!';

    return AIInsightsModel(
      hiveSummary: greeting,
      hivePriorities: [
        'Check your schedule for the day',
        'Stay updated with the latest news',
        'Be prepared for the weather',
      ],
      hiveTrafficAlert: null,
      hiveSuggestions: [
        'Review your calendar events',
        'Check weather conditions',
      ],
    );
  }
}
