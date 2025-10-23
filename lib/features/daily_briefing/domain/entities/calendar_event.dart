import 'package:equatable/equatable.dart';

class CalendarEvent extends Equatable {
  final String id;
  final String title;
  final DateTime startTime;
  final DateTime endTime;
  final String? location;
  final String? description;
  final bool isAllDay;
  final String? calendarName;

  const CalendarEvent({
    required this.id,
    required this.title,
    required this.startTime,
    required this.endTime,
    this.location,
    this.description,
    required this.isAllDay,
    this.calendarName,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        startTime,
        endTime,
        location,
        description,
        isAllDay,
        calendarName,
      ];
}
