import 'package:equatable/equatable.dart';

/// Represents a calendar event from the device calendar
class CalendarEvent extends Equatable {
  final String id;
  final String title;
  final DateTime startTime;
  final DateTime endTime;
  final String? description;
  final String? location;
  final bool isAllDay;
  final String? calendarName;

  const CalendarEvent({
    required this.id,
    required this.title,
    required this.startTime,
    required this.endTime,
    this.description,
    this.location,
    required this.isAllDay,
    this.calendarName,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        startTime,
        endTime,
        description,
        location,
        isAllDay,
        calendarName,
      ];

  /// Get event duration in minutes
  int get durationInMinutes {
    return endTime.difference(startTime).inMinutes;
  }

  /// Check if event is currently ongoing
  bool get isOngoing {
    final now = DateTime.now();
    return now.isAfter(startTime) && now.isBefore(endTime);
  }

  /// Check if event is upcoming (starts within next hour)
  bool get isUpcoming {
    final now = DateTime.now();
    final oneHourFromNow = now.add(const Duration(hours: 1));
    return startTime.isAfter(now) && startTime.isBefore(oneHourFromNow);
  }
}
