import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/daily_briefing.dart';

/// Briefing preferences
class BriefingPreferences {
  final String? preferredCity;
  final double? latitude;
  final double? longitude;
  final String? country; // For news
  final List<String>? newsCategories;
  final String? userName;
  final List<String>? interests;

  const BriefingPreferences({
    this.preferredCity,
    this.latitude,
    this.longitude,
    this.country,
    this.newsCategories,
    this.userName,
    this.interests,
  });
}

/// Abstract repository interface for daily briefing orchestration
abstract class BriefingRepository {
  /// Generate a complete daily briefing
  ///
  /// This method orchestrates all data sources (weather, news, calendar, AI)
  /// and combines them into a single briefing.
  ///
  /// Parameters:
  /// - [preferences]: User preferences for the briefing
  /// - [forceRefresh]: If true, bypass cache and fetch fresh data
  ///
  /// Returns:
  /// - Right(DailyBriefing) on success
  /// - Left(Failure) on error
  Future<Either<Failure, DailyBriefing>> generateBriefing({
    required BriefingPreferences preferences,
    bool forceRefresh = false,
  });

  /// Get cached briefing (for offline mode)
  ///
  /// Returns:
  /// - Right(DailyBriefing) if cached briefing exists
  /// - Left(CacheFailure) if no cached data
  Future<Either<Failure, DailyBriefing>> getCachedBriefing();

  /// Save briefing preferences
  Future<Either<Failure, void>> savePreferences(
    BriefingPreferences preferences,
  );

  /// Get saved preferences
  Future<Either<Failure, BriefingPreferences>> getPreferences();
}
