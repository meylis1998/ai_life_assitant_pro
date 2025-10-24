import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/daily_briefing_model.dart';
import '../../domain/repositories/briefing_repository.dart';

/// Local data source for caching briefings and preferences
abstract class BriefingLocalDataSource {
  /// Cache a daily briefing
  Future<void> cacheBriefing(DailyBriefingModel briefing);

  /// Get cached briefing
  Future<DailyBriefingModel?> getCachedBriefing();

  /// Save preferences
  Future<void> savePreferences(BriefingPreferences preferences);

  /// Get preferences
  Future<BriefingPreferences> getPreferences();

  /// Clear cached briefing
  Future<void> clearCache();
}

class BriefingLocalDataSourceImpl implements BriefingLocalDataSource {
  final SharedPreferences sharedPreferences;

  static const String _briefingCacheKey = 'daily_briefing_cache';
  static const String _preferencesKey = 'briefing_preferences';

  BriefingLocalDataSourceImpl({required this.sharedPreferences});

  @override
  Future<void> cacheBriefing(DailyBriefingModel briefing) async {
    try {
      final json = briefing.toJson();
      final jsonString = jsonEncode(json);
      await sharedPreferences.setString(_briefingCacheKey, jsonString);
    } catch (e) {
      throw Exception('Failed to cache briefing: $e');
    }
  }

  @override
  Future<DailyBriefingModel?> getCachedBriefing() async {
    try {
      final jsonString = sharedPreferences.getString(_briefingCacheKey);
      if (jsonString == null) return null;

      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return DailyBriefingModel.fromJson(json);
    } catch (e) {
      // If parsing fails, clear the cache
      await clearCache();
      return null;
    }
  }

  @override
  Future<void> savePreferences(BriefingPreferences preferences) async {
    try {
      final json = <String, dynamic>{
        if (preferences.preferredCity != null)
          'preferredCity': preferences.preferredCity,
        if (preferences.latitude != null) 'latitude': preferences.latitude,
        if (preferences.longitude != null) 'longitude': preferences.longitude,
        if (preferences.country != null) 'country': preferences.country,
        if (preferences.newsCategories != null)
          'newsCategories': preferences.newsCategories,
        if (preferences.userName != null) 'userName': preferences.userName,
        if (preferences.interests != null) 'interests': preferences.interests,
      };

      final jsonString = jsonEncode(json);
      await sharedPreferences.setString(_preferencesKey, jsonString);
    } catch (e) {
      throw Exception('Failed to save preferences: $e');
    }
  }

  @override
  Future<BriefingPreferences> getPreferences() async {
    try {
      final jsonString = sharedPreferences.getString(_preferencesKey);
      if (jsonString == null) {
        // Return default preferences
        return const BriefingPreferences(
          country: 'us',
          newsCategories: ['general', 'technology'],
        );
      }

      final json = jsonDecode(jsonString) as Map<String, dynamic>;

      return BriefingPreferences(
        preferredCity: json['preferredCity'] as String?,
        latitude: json['latitude'] as double?,
        longitude: json['longitude'] as double?,
        country: json['country'] as String?,
        newsCategories: (json['newsCategories'] as List?)?.cast<String>(),
        userName: json['userName'] as String?,
        interests: (json['interests'] as List?)?.cast<String>(),
      );
    } catch (e) {
      // Return default preferences on error
      return const BriefingPreferences(
        country: 'us',
        newsCategories: ['general', 'technology'],
      );
    }
  }

  @override
  Future<void> clearCache() async {
    await sharedPreferences.remove(_briefingCacheKey);
  }
}
