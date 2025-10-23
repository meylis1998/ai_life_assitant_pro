import '../../domain/entities/calendar_event.dart';

class CalendarEventModel extends CalendarEvent {
  const CalendarEventModel({
    required super.id,
    required super.title,
    required super.startTime,
    required super.endTime,
    super.location,
    super.description,
    required super.isAllDay,
    super.calendarName,
  });

  factory CalendarEventModel.fromDeviceCalendar(dynamic event) {
    return CalendarEventModel(
      id: event.eventId as String,
      title: event.title as String? ?? 'Untitled Event',
      startTime: event.start as DateTime,
      endTime: event.end as DateTime,
      location: event.location as String?,
      description: event.description as String?,
      isAllDay: event.allDay as bool? ?? false,
      calendarName: null, // Will be set separately
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'location': location,
      'description': description,
      'isAllDay': isAllDay,
      'calendarName': calendarName,
    };
  }

  factory CalendarEventModel.fromJson(Map<String, dynamic> json) {
    return CalendarEventModel(
      id: json['id'] as String,
      title: json['title'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      location: json['location'] as String?,
      description: json['description'] as String?,
      isAllDay: json['isAllDay'] as bool,
      calendarName: json['calendarName'] as String?,
    );
  }
}
