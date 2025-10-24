import 'package:json_annotation/json_annotation.dart';
import 'package:device_calendar/device_calendar.dart' as device_cal;
import '../../domain/entities/calendar_event.dart';

part 'calendar_event_model.g.dart';

@JsonSerializable()
class CalendarEventModel extends CalendarEvent {
  const CalendarEventModel({
    required super.id,
    required super.title,
    required super.startTime,
    required super.endTime,
    super.description,
    super.location,
    required super.isAllDay,
    super.calendarName,
  });

  factory CalendarEventModel.fromJson(Map<String, dynamic> json) =>
      _$CalendarEventModelFromJson(json);

  Map<String, dynamic> toJson() => _$CalendarEventModelToJson(this);

  /// Create from device_calendar plugin Event
  factory CalendarEventModel.fromDeviceCalendar(
    device_cal.Event event,
    String? calendarName,
  ) {
    return CalendarEventModel(
      id: event.eventId ?? '',
      title: event.title ?? 'Untitled Event',
      startTime: event.start ?? DateTime.now(),
      endTime: event.end ?? DateTime.now(),
      description: event.description,
      location: event.location,
      isAllDay: event.allDay ?? false,
      calendarName: calendarName,
    );
  }

  CalendarEvent toEntity() => CalendarEvent(
        id: id,
        title: title,
        startTime: startTime,
        endTime: endTime,
        description: description,
        location: location,
        isAllDay: isAllDay,
        calendarName: calendarName,
      );

  /// Create model from entity
  factory CalendarEventModel.fromEntity(CalendarEvent entity) {
    return CalendarEventModel(
      id: entity.id,
      title: entity.title,
      startTime: entity.startTime,
      endTime: entity.endTime,
      description: entity.description,
      location: entity.location,
      isAllDay: entity.isAllDay,
      calendarName: entity.calendarName,
    );
  }
}
