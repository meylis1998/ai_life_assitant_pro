import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/weather.dart';
import 'forecast_model.dart';

part 'weather_model.g.dart';

@JsonSerializable()
class WeatherModel extends Weather {
  @override
  final List<ForecastModel> forecast;

  const WeatherModel({
    required super.location,
    super.country,
    super.region,
    required super.temperature,
    required super.feelsLike,
    required super.condition,
    super.conditionDescription,
    super.icon,
    required super.humidity,
    required super.windSpeed,
    super.pressure,
    super.visibility,
    required super.timestamp,
    required this.forecast,
  }) : super(forecast: forecast);

  factory WeatherModel.fromJson(Map<String, dynamic> json) =>
      _$WeatherModelFromJson(json);

  Map<String, dynamic> toJson() => _$WeatherModelToJson(this);

  /// Create from OpenWeatherMap combined API response
  ///
  /// Combines data from both /weather (current) and /forecast (5-day) endpoints
  factory WeatherModel.fromOpenWeatherMap({
    required Map<String, dynamic> currentWeather,
    required Map<String, dynamic> forecastData,
  }) {
    final main = currentWeather['main'] as Map<String, dynamic>;
    final weather =
        (currentWeather['weather'] as List).first as Map<String, dynamic>;
    final wind = currentWeather['wind'] as Map<String, dynamic>;

    // Parse forecast data (get one forecast per day, using midday forecast)
    final forecastList = (forecastData['list'] as List)
        .map((item) => ForecastModel.fromOpenWeatherMap(item as Map<String, dynamic>))
        .toList();

    // Group forecasts by date and take the midday one for each day
    final dailyForecasts = <DateTime, ForecastModel>{};
    for (final forecast in forecastList) {
      final dateKey = DateTime(
        forecast.date.year,
        forecast.date.month,
        forecast.date.day,
      );

      // Prefer forecasts around noon (12:00)
      if (!dailyForecasts.containsKey(dateKey) ||
          (forecast.date.hour - 12).abs() <
              (dailyForecasts[dateKey]!.date.hour - 12).abs()) {
        dailyForecasts[dateKey] = forecast;
      }
    }

    // Take up to 5 days of forecast
    final sortedForecasts = dailyForecasts.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    final next5Days = sortedForecasts.take(5).toList();

    // Extract country information from sys object
    final sys = currentWeather['sys'] as Map<String, dynamic>?;
    final country = sys?['country'] as String?;

    // Debug logging
    print('🌍 Weather API Response:');
    print('  City: ${currentWeather['name']}');
    print('  Country: $country');
    print('  Sys object: $sys');

    return WeatherModel(
      location: currentWeather['name'] as String,
      country: country,
      region: null, // OpenWeatherMap doesn't provide region/state info
      temperature: (main['temp'] as num).toDouble(),
      feelsLike: (main['feels_like'] as num).toDouble(),
      condition: weather['main'] as String,
      conditionDescription: weather['description'] as String?,
      icon: weather['icon'] as String?,
      humidity: main['humidity'] as int,
      windSpeed: (wind['speed'] as num).toDouble(),
      pressure: main['pressure'] as int?,
      visibility: currentWeather['visibility'] as int?,
      timestamp: DateTime.now(),
      forecast: next5Days,
    );
  }

  Weather toEntity() => Weather(
        location: location,
        country: country,
        region: region,
        temperature: temperature,
        feelsLike: feelsLike,
        condition: condition,
        conditionDescription: conditionDescription,
        icon: icon,
        humidity: humidity,
        windSpeed: windSpeed,
        pressure: pressure,
        visibility: visibility,
        timestamp: timestamp,
        forecast: forecast.map((f) => f.toEntity()).toList(),
      );

  /// Create model from entity
  factory WeatherModel.fromEntity(Weather entity) {
    return WeatherModel(
      location: entity.location,
      temperature: entity.temperature,
      feelsLike: entity.feelsLike,
      condition: entity.condition,
      conditionDescription: entity.conditionDescription,
      icon: entity.icon,
      humidity: entity.humidity,
      windSpeed: entity.windSpeed,
      pressure: entity.pressure,
      visibility: entity.visibility,
      timestamp: entity.timestamp,
      forecast: entity.forecast.map((f) => ForecastModel.fromEntity(f)).toList(),
    );
  }
}
