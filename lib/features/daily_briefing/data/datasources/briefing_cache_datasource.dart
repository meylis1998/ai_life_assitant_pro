import 'package:hive/hive.dart';

import '../models/daily_briefing_model.dart';

abstract class BriefingCacheDataSource {
  Future<DailyBriefingModel> getLastBriefing();
  Future<void> cacheBriefing(DailyBriefingModel briefing);
  Future<void> clearCache();
}

class BriefingCacheDataSourceImpl implements BriefingCacheDataSource {
  static const String _boxName = 'daily_briefing_cache';
  static const String _briefingKey = 'last_briefing';

  @override
  Future<DailyBriefingModel> getLastBriefing() async {
    try {
      final box = await Hive.openBox<DailyBriefingModel>(_boxName);
      final briefing = box.get(_briefingKey);

      if (briefing == null) {
        throw Exception('No cached briefing found');
      }

      return briefing;
    } catch (e) {
      // If cache is corrupted, clear it and rethrow
      if (e.toString().contains('subtype') || e.toString().contains('type cast')) {
        await _clearCorruptedCache();
        throw Exception('Corrupted cache cleared. Please regenerate briefing.');
      }
      rethrow;
    }
  }

  /// Clear corrupted cache data
  Future<void> _clearCorruptedCache() async {
    try {
      await Hive.deleteBoxFromDisk(_boxName);
      print('🗑️ Cleared corrupted briefing cache');
    } catch (e) {
      print('⚠️ Failed to clear cache: $e');
    }
  }

  @override
  Future<void> cacheBriefing(DailyBriefingModel briefing) async {
    final box = await Hive.openBox<DailyBriefingModel>(_boxName);
    await box.put(_briefingKey, briefing);
  }

  @override
  Future<void> clearCache() async {
    final box = await Hive.openBox<DailyBriefingModel>(_boxName);
    await box.clear();
  }
}
