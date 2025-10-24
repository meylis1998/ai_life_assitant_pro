import 'package:device_calendar/device_calendar.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/calendar_event_model.dart';

/// Local data source for calendar data using device_calendar plugin
abstract class CalendarLocalDataSource {
  /// Request calendar permission
  Future<bool> requestPermission();

  /// Check if calendar permission is granted
  Future<bool> hasPermission();

  /// Get today's calendar events
  Future<List<CalendarEventModel>> getTodayEvents();

  /// Get events for a specific date range
  Future<List<CalendarEventModel>> getEvents({
    required DateTime startDate,
    required DateTime endDate,
  });
}

class CalendarLocalDataSourceImpl implements CalendarLocalDataSource {
  final DeviceCalendarPlugin deviceCalendarPlugin;

  CalendarLocalDataSourceImpl({
    DeviceCalendarPlugin? deviceCalendarPlugin,
  }) : deviceCalendarPlugin = deviceCalendarPlugin ?? DeviceCalendarPlugin();

  @override
  Future<bool> requestPermission() async {
    try {
      final status = await Permission.calendar.request();
      return status.isGranted;
    } catch (e) {
      throw Exception('Failed to request calendar permission: $e');
    }
  }

  @override
  Future<bool> hasPermission() async {
    try {
      final status = await Permission.calendar.status;
      return status.isGranted;
    } catch (e) {
      throw Exception('Failed to check calendar permission: $e');
    }
  }

  @override
  Future<List<CalendarEventModel>> getTodayEvents() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return await getEvents(startDate: startOfDay, endDate: endOfDay);
  }

  @override
  Future<List<CalendarEventModel>> getEvents({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      // Check permission first
      if (!await hasPermission()) {
        throw Exception('Calendar permission not granted');
      }

      // Get all calendars
      final calendarsResult = await deviceCalendarPlugin.retrieveCalendars();

      if (calendarsResult.isSuccess && calendarsResult.data != null) {
        final calendars = calendarsResult.data!;
        final allEvents = <CalendarEventModel>[];

        // Fetch events from each calendar
        for (final calendar in calendars) {
          final eventsResult = await deviceCalendarPlugin.retrieveEvents(
            calendar.id,
            RetrieveEventsParams(
              startDate: startDate,
              endDate: endDate,
            ),
          );

          if (eventsResult.isSuccess && eventsResult.data != null) {
            final events = eventsResult.data!
                .map((event) => CalendarEventModel.fromDeviceCalendar(
                      event,
                      calendar.name,
                    ))
                .toList();
            allEvents.addAll(events);
          }
        }

        // Sort events by start time
        allEvents.sort((a, b) => a.startTime.compareTo(b.startTime));

        return allEvents;
      }

      return [];
    } catch (e) {
      throw Exception('Failed to fetch calendar events: $e');
    }
  }
}
