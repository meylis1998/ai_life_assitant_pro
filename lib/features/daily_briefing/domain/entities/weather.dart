import 'package:equatable/equatable.dart';
import 'forecast.dart';

/// Represents current weather conditions and forecast
class Weather extends Equatable {
  final String location;
  final String? country;
  final String? region;
  final double temperature;
  final double feelsLike;
  final String condition;
  final String? conditionDescription;
  final String? icon;
  final int humidity;
  final double windSpeed;
  final int? pressure;
  final int? visibility;
  final DateTime timestamp;
  final List<Forecast> forecast;

  const Weather({
    required this.location,
    this.country,
    this.region,
    required this.temperature,
    required this.feelsLike,
    required this.condition,
    this.conditionDescription,
    this.icon,
    required this.humidity,
    required this.windSpeed,
    this.pressure,
    this.visibility,
    required this.timestamp,
    required this.forecast,
  });

  @override
  List<Object?> get props => [
        location,
        country,
        region,
        temperature,
        feelsLike,
        condition,
        conditionDescription,
        icon,
        humidity,
        windSpeed,
        pressure,
        visibility,
        timestamp,
        forecast,
      ];
}
