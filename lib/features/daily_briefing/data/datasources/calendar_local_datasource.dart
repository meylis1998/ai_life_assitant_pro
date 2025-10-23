import 'package:device_calendar/device_calendar.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/calendar_event_model.dart';

abstract class CalendarLocalDataSource {
  Future<List<CalendarEventModel>> getTodayEvents();
  Future<bool> requestCalendarPermission();
}

class CalendarLocalDataSourceImpl implements CalendarLocalDataSource {
  final DeviceCalendarPlugin deviceCalendarPlugin;

  CalendarLocalDataSourceImpl({required this.deviceCalendarPlugin});

  @override
  Future<bool> requestCalendarPermission() async {
    final status = await Permission.calendarFullAccess.request();
    return status.isGranted;
  }

  @override
  Future<List<CalendarEventModel>> getTodayEvents() async {
    try {
      // Request permission
      final hasPermission = await requestCalendarPermission();
      if (!hasPermission) {
        throw Exception('Calendar permission denied');
      }

      // Get all calendars
      final calendarsResult = await deviceCalendarPlugin.retrieveCalendars();
      if (!calendarsResult.isSuccess || calendarsResult.data == null) {
        throw Exception('Failed to retrieve calendars');
      }

      final calendars = calendarsResult.data!;
      final allEvents = <CalendarEventModel>[];

      // Get today's date range
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

      // Fetch events from each calendar
      for (final calendar in calendars) {
        if (calendar.id == null) continue;

        final eventsResult = await deviceCalendarPlugin.retrieveEvents(
          calendar.id!,
          RetrieveEventsParams(
            startDate: startOfDay,
            endDate: endOfDay,
          ),
        );

        if (eventsResult.isSuccess && eventsResult.data != null) {
          for (final event in eventsResult.data!) {
            final eventModel = CalendarEventModel.fromDeviceCalendar(event);
            allEvents.add(CalendarEventModel(
              id: eventModel.id,
              title: eventModel.title,
              startTime: eventModel.startTime,
              endTime: eventModel.endTime,
              location: eventModel.location,
              description: eventModel.description,
              isAllDay: eventModel.isAllDay,
              calendarName: calendar.name,
            ));
          }
        }
      }

      // Sort events by start time
      allEvents.sort((a, b) => a.startTime.compareTo(b.startTime));

      return allEvents;
    } catch (e) {
      throw Exception('Failed to get calendar events: $e');
    }
  }
}
