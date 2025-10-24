// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calendar_event_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CalendarEventModel _$CalendarEventModelFromJson(Map<String, dynamic> json) =>
    CalendarEventModel(
      id: json['id'] as String,
      title: json['title'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      description: json['description'] as String?,
      location: json['location'] as String?,
      isAllDay: json['isAllDay'] as bool,
      calendarName: json['calendarName'] as String?,
    );

Map<String, dynamic> _$CalendarEventModelToJson(CalendarEventModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'startTime': instance.startTime.toIso8601String(),
      'endTime': instance.endTime.toIso8601String(),
      'description': instance.description,
      'location': instance.location,
      'isAllDay': instance.isAllDay,
      'calendarName': instance.calendarName,
    };
