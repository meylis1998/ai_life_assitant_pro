import 'package:equatable/equatable.dart';

/// Represents a weather forecast for a specific day
class Forecast extends Equatable {
  final DateTime date;
  final double minTemperature;
  final double maxTemperature;
  final String condition;
  final String? conditionDescription;
  final String? icon;
  final int? humidity;
  final double? windSpeed;
  final double? precipitation; // Probability of precipitation (0-100)

  const Forecast({
    required this.date,
    required this.minTemperature,
    required this.maxTemperature,
    required this.condition,
    this.conditionDescription,
    this.icon,
    this.humidity,
    this.windSpeed,
    this.precipitation,
  });

  @override
  List<Object?> get props => [
        date,
        minTemperature,
        maxTemperature,
        condition,
        conditionDescription,
        icon,
        humidity,
        windSpeed,
        precipitation,
      ];
}
