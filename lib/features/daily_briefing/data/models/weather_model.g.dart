// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'weather_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WeatherModel _$WeatherModelFromJson(Map<String, dynamic> json) => WeatherModel(
      location: json['location'] as String,
      country: json['country'] as String?,
      region: json['region'] as String?,
      temperature: (json['temperature'] as num).toDouble(),
      feelsLike: (json['feelsLike'] as num).toDouble(),
      condition: json['condition'] as String,
      conditionDescription: json['conditionDescription'] as String?,
      icon: json['icon'] as String?,
      humidity: (json['humidity'] as num).toInt(),
      windSpeed: (json['windSpeed'] as num).toDouble(),
      pressure: (json['pressure'] as num?)?.toInt(),
      visibility: (json['visibility'] as num?)?.toInt(),
      timestamp: DateTime.parse(json['timestamp'] as String),
      forecast: (json['forecast'] as List<dynamic>)
          .map((e) => ForecastModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$WeatherModelToJson(WeatherModel instance) =>
    <String, dynamic>{
      'location': instance.location,
      'country': instance.country,
      'region': instance.region,
      'temperature': instance.temperature,
      'feelsLike': instance.feelsLike,
      'condition': instance.condition,
      'conditionDescription': instance.conditionDescription,
      'icon': instance.icon,
      'humidity': instance.humidity,
      'windSpeed': instance.windSpeed,
      'pressure': instance.pressure,
      'visibility': instance.visibility,
      'timestamp': instance.timestamp.toIso8601String(),
      'forecast': instance.forecast,
    };
