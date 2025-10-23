import 'package:equatable/equatable.dart';

class Weather extends Equatable {
  final double temperature;
  final double feelsLike;
  final String condition;
  final String description;
  final int humidity;
  final double windSpeed;
  final int pressure;
  final String cityName;
  final List<Forecast> forecast;

  const Weather({
    required this.temperature,
    required this.feelsLike,
    required this.condition,
    required this.description,
    required this.humidity,
    required this.windSpeed,
    required this.pressure,
    required this.cityName,
    required this.forecast,
  });

  @override
  List<Object?> get props => [
        temperature,
        feelsLike,
        condition,
        description,
        humidity,
        windSpeed,
        pressure,
        cityName,
        forecast,
      ];
}

class Forecast extends Equatable {
  final DateTime date;
  final double maxTemp;
  final double minTemp;
  final String condition;
  final String description;
  final int humidity;

  const Forecast({
    required this.date,
    required this.maxTemp,
    required this.minTemp,
    required this.condition,
    required this.description,
    required this.humidity,
  });

  @override
  List<Object?> get props => [
        date,
        maxTemp,
        minTemp,
        condition,
        description,
        humidity,
      ];
}
