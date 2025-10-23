import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage Daily Briefing preferences
class BriefingPreferencesService {
  final SharedPreferences _prefs;

  BriefingPreferencesService(this._prefs);

  // Keys
  static const String _keyUseGps = 'briefing_use_gps';
  static const String _keyCity = 'briefing_city';
  static const String _keyCountry = 'briefing_country';
  static const String _keyNewsCategories = 'briefing_news_categories';
  static const String _keyScheduleEnabled = 'briefing_schedule_enabled';
  static const String _keyScheduleHour = 'briefing_schedule_hour';
  static const String _keyScheduleMinute = 'briefing_schedule_minute';
  static const String _keyNotificationsEnabled = 'briefing_notifications_enabled';

  // Location Settings
  bool get useGps => _prefs.getBool(_keyUseGps) ?? true;

  Future<void> setUseGps(bool value) async {
    await _prefs.setBool(_keyUseGps, value);
  }

  String get city => _prefs.getString(_keyCity) ?? 'New York';

  Future<void> setCity(String value) async {
    await _prefs.setString(_keyCity, value);
  }

  String get country => _prefs.getString(_keyCountry) ?? 'us';

  Future<void> setCountry(String value) async {
    await _prefs.setString(_keyCountry, value);
  }

  // News Settings
  List<String> get newsCategories {
    final categories = _prefs.getStringList(_keyNewsCategories);
    return categories ?? ['general', 'technology', 'business'];
  }

  Future<void> setNewsCategories(List<String> categories) async {
    await _prefs.setStringList(_keyNewsCategories, categories);
  }

  // Schedule Settings
  bool get scheduleEnabled => _prefs.getBool(_keyScheduleEnabled) ?? false;

  Future<void> setScheduleEnabled(bool value) async {
    await _prefs.setBool(_keyScheduleEnabled, value);
  }

  int get scheduleHour => _prefs.getInt(_keyScheduleHour) ?? 7; // 7 AM default

  Future<void> setScheduleHour(int value) async {
    await _prefs.setInt(_keyScheduleHour, value);
  }

  int get scheduleMinute => _prefs.getInt(_keyScheduleMinute) ?? 0;

  Future<void> setScheduleMinute(int value) async {
    await _prefs.setInt(_keyScheduleMinute, value);
  }

  // Notification Settings
  bool get notificationsEnabled => _prefs.getBool(_keyNotificationsEnabled) ?? true;

  Future<void> setNotificationsEnabled(bool value) async {
    await _prefs.setBool(_keyNotificationsEnabled, value);
  }

  // Helper to get schedule time as string
  String get scheduleTimeString {
    final hour = scheduleHour > 12 ? scheduleHour - 12 : scheduleHour;
    final amPm = scheduleHour >= 12 ? 'PM' : 'AM';
    final minute = scheduleMinute.toString().padLeft(2, '0');
    return '${hour == 0 ? 12 : hour}:$minute $amPm';
  }

  // Clear all preferences
  Future<void> clearAll() async {
    await _prefs.remove(_keyUseGps);
    await _prefs.remove(_keyCity);
    await _prefs.remove(_keyCountry);
    await _prefs.remove(_keyNewsCategories);
    await _prefs.remove(_keyScheduleEnabled);
    await _prefs.remove(_keyScheduleHour);
    await _prefs.remove(_keyScheduleMinute);
    await _prefs.remove(_keyNotificationsEnabled);
  }
}
