// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'forecast_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ForecastModel _$ForecastModelFromJson(Map<String, dynamic> json) =>
    ForecastModel(
      date: DateTime.parse(json['date'] as String),
      minTemperature: (json['minTemperature'] as num).toDouble(),
      maxTemperature: (json['maxTemperature'] as num).toDouble(),
      condition: json['condition'] as String,
      conditionDescription: json['conditionDescription'] as String?,
      icon: json['icon'] as String?,
      humidity: (json['humidity'] as num?)?.toInt(),
      windSpeed: (json['windSpeed'] as num?)?.toDouble(),
      precipitation: (json['precipitation'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$ForecastModelToJson(ForecastModel instance) =>
    <String, dynamic>{
      'date': instance.date.toIso8601String(),
      'minTemperature': instance.minTemperature,
      'maxTemperature': instance.maxTemperature,
      'condition': instance.condition,
      'conditionDescription': instance.conditionDescription,
      'icon': instance.icon,
      'humidity': instance.humidity,
      'windSpeed': instance.windSpeed,
      'precipitation': instance.precipitation,
    };
