import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/services/location_service.dart';
import '../../domain/entities/daily_briefing.dart';
import '../../domain/entities/news_article.dart';
import '../../domain/entities/calendar_event.dart';
import '../../domain/repositories/briefing_repository.dart';
import '../../domain/repositories/weather_repository.dart';
import '../../domain/repositories/news_repository.dart';
import '../../domain/repositories/calendar_repository.dart';
import '../../domain/repositories/ai_insights_repository.dart';
import '../datasources/briefing_local_datasource.dart';
import '../models/daily_briefing_model.dart';
import '../models/weather_model.dart';
import '../models/news_article_model.dart';
import '../models/calendar_event_model.dart';
import '../models/ai_insights_model.dart';

class BriefingRepositoryImpl implements BriefingRepository {
  final WeatherRepository weatherRepository;
  final NewsRepository newsRepository;
  final CalendarRepository calendarRepository;
  final AIInsightsRepository aiInsightsRepository;
  final BriefingLocalDataSource localDataSource;
  final NetworkInfo networkInfo;
  final LocationService locationService;

  BriefingRepositoryImpl({
    required this.weatherRepository,
    required this.newsRepository,
    required this.calendarRepository,
    required this.aiInsightsRepository,
    required this.localDataSource,
    required this.networkInfo,
    required this.locationService,
  });

  @override
  Future<Either<Failure, DailyBriefing>> generateBriefing({
    required BriefingPreferences preferences,
    bool forceRefresh = false,
  }) async {
    try {
      // Check if we should use cached data
      if (!forceRefresh && !await networkInfo.isConnected) {
        return getCachedBriefing();
      }

      final errors = <String>[];
      WeatherModel? weather;
      List<NewsArticleModel> news = [];
      List<CalendarEventModel> events = [];
      AIInsightsModel? insights;

      // Fetch weather (in parallel with news)
      final weatherFuture = _fetchWeather(preferences);
      final newsFuture = _fetchNews(preferences);

      // Wait for weather and news
      final weatherResult = await weatherFuture;
      final newsResult = await newsFuture;

      weatherResult.fold(
        (failure) => errors.add('Weather: ${failure.message}'),
        (weatherEntity) => weather = WeatherModel.fromEntity(weatherEntity),
      );

      newsResult.fold(
        (failure) => errors.add('News: ${failure.message}'),
        (newsEntities) => news = newsEntities.map((e) => NewsArticleModel.fromEntity(e)).toList(),
      );

      // Fetch calendar events
      final eventsResult = await _fetchCalendarEvents();
      eventsResult.fold(
        (failure) {
          // Calendar permission denied is not a critical error
          if (failure is! PermissionFailure) {
            errors.add('Calendar: ${failure.message}');
          }
        },
        (eventEntities) => events = eventEntities.map((e) => CalendarEventModel.fromEntity(e)).toList(),
      );

      // Generate AI insights if we have at least some data
      if (weather != null || news.isNotEmpty || events.isNotEmpty) {
        final insightsResult = await _generateInsights(
          weather: weather?.toEntity(),
          news: news.map((e) => e.toEntity()).toList(),
          events: events.map((e) => e.toEntity()).toList(),
          preferences: preferences,
        );

        insightsResult.fold(
          (failure) => errors.add('AI Insights: ${failure.message}'),
          (insightsEntity) => insights = AIInsightsModel.fromEntity(insightsEntity),
        );
      }

      // Create the briefing
      final briefing = DailyBriefingModel.partial(
        id: const Uuid().v4(),
        generatedAt: DateTime.now(),
        weather: weather,
        topNews: news,
        todayEvents: events,
        insights: insights,
        errorMessage: errors.isNotEmpty ? errors.join('; ') : '',
      );

      // Cache the briefing
      await localDataSource.cacheBriefing(briefing);

      return Right(briefing.toEntity());
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to generate briefing: $e'));
    }
  }

  Future<Either<Failure, dynamic>> _fetchWeather(
    BriefingPreferences preferences,
  ) async {
    try {
      // First priority: Try to get device's current location
      final position = await locationService.getCurrentPosition();

      if (position != null) {
        print('🗺️ Using device location: ${position.latitude}, ${position.longitude}');

        // Use device location for most accurate weather
        final result = await weatherRepository.getWeather(
          latitude: position.latitude,
          longitude: position.longitude,
        );

        // Save the location to preferences for future use
        await _saveLocationToPreferences(position.latitude, position.longitude);

        return result;
      }

      // Second priority: Use saved coordinates from preferences
      if (preferences.latitude != null && preferences.longitude != null) {
        return await weatherRepository.getWeather(
          latitude: preferences.latitude!,
          longitude: preferences.longitude!,
        );
      }

      // Third priority: Use preferred city from preferences
      if (preferences.preferredCity != null && preferences.preferredCity!.isNotEmpty) {
        return await weatherRepository.getWeatherByCity(
          preferences.preferredCity!,
        );
      }

      // Final fallback: Use default city with helpful message
      final result = await weatherRepository.getWeatherByCity('London');

      return result.fold(
        (failure) => Left(ValidationFailure(
          message: 'Location permission needed for accurate weather. Grant location access or set your city in settings. Showing London weather as fallback.',
        )),
        (weather) {
          return Right(weather);
        },
      );
    } catch (e) {
      return Left(WeatherFailure(message: e.toString()));
    }
  }

  /// Save device location to preferences for future use
  Future<void> _saveLocationToPreferences(double latitude, double longitude) async {
    try {
      final currentPrefs = await localDataSource.getPreferences();
      final updatedPrefs = BriefingPreferences(
        preferredCity: currentPrefs.preferredCity,
        latitude: latitude,
        longitude: longitude,
        country: currentPrefs.country,
        newsCategories: currentPrefs.newsCategories,
        userName: currentPrefs.userName,
        interests: currentPrefs.interests,
      );
      await localDataSource.savePreferences(updatedPrefs);
    } catch (e) {
      // Don't fail the whole operation if we can't save preferences
      print('Failed to save location to preferences: $e');
    }
  }

  Future<Either<Failure, List<dynamic>>> _fetchNews(
    BriefingPreferences preferences,
  ) async {
    try {
      final category = preferences.newsCategories?.first;
      return await newsRepository.getTopHeadlines(
        country: preferences.country,
        category: category,
        pageSize: 10,
      );
    } catch (e) {
      return Left(NewsFailure(message: e.toString()));
    }
  }

  Future<Either<Failure, List<dynamic>>> _fetchCalendarEvents() async {
    try {
      return await calendarRepository.getTodayEvents();
    } catch (e) {
      return Left(CalendarFailure(message: e.toString()));
    }
  }

  Future<Either<Failure, dynamic>> _generateInsights({
    required dynamic weather,
    required List<dynamic> news,
    required List<dynamic> events,
    required BriefingPreferences preferences,
  }) async {
    try {
      final context = AIInsightsContext(
        weather: weather,
        news: news.cast<NewsArticle>(),
        events: events.cast<CalendarEvent>(),
        userName: preferences.userName,
        userInterests: preferences.interests,
      );

      return await aiInsightsRepository.generateInsights(context: context);
    } catch (e) {
      return Left(AIProviderFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, DailyBriefing>> getCachedBriefing() async {
    try {
      final cached = await localDataSource.getCachedBriefing();

      if (cached == null) {
        return const Left(
          CacheFailure(message: 'No cached briefing available'),
        );
      }

      return Right(cached.toEntity());
    } catch (e) {
      return Left(CacheFailure(message: 'Failed to get cached briefing: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> savePreferences(
    BriefingPreferences preferences,
  ) async {
    try {
      await localDataSource.savePreferences(preferences);
      return const Right(null);
    } catch (e) {
      return Left(
        CacheFailure(message: 'Failed to save preferences: $e'),
      );
    }
  }

  @override
  Future<Either<Failure, BriefingPreferences>> getPreferences() async {
    try {
      final preferences = await localDataSource.getPreferences();
      return Right(preferences);
    } catch (e) {
      return Left(
        CacheFailure(message: 'Failed to get preferences: $e'),
      );
    }
  }
}
