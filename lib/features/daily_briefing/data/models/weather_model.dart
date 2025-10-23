import '../../domain/entities/weather.dart';

class WeatherModel extends Weather {
  const WeatherModel({
    required super.temperature,
    required super.feelsLike,
    required super.condition,
    required super.description,
    required super.humidity,
    required super.windSpeed,
    required super.pressure,
    required super.cityName,
    required super.forecast,
  });

  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    // Check if this is serialized format (from toJson) or API format
    final bool isSerializedFormat = json.containsKey('temperature');

    if (isSerializedFormat) {
      // Handle our own serialized format (from toJson/cache)
      return WeatherModel(
        temperature: (json['temperature'] as num?)?.toDouble() ?? 0.0,
        feelsLike: (json['feelsLike'] as num?)?.toDouble() ?? 0.0,
        condition: json['condition'] as String? ?? 'Unknown',
        description: json['description'] as String? ?? 'No description',
        humidity: json['humidity'] as int? ?? 0,
        windSpeed: (json['windSpeed'] as num?)?.toDouble() ?? 0.0,
        pressure: json['pressure'] as int? ?? 0,
        cityName: json['cityName'] as String? ?? 'Unknown',
        forecast: (json['forecast'] as List?)
                ?.map((f) => ForecastModel.fromJson(f as Map<String, dynamic>))
                .toList() ??
            [],
      );
    }

    // Handle OpenWeather API format
    if (json['main'] == null || json['weather'] == null) {
      final errorMsg = json['message'] ?? json['error'] ?? 'Missing required fields';
      throw FormatException(
        'Invalid weather API response: $errorMsg. Please check your OpenWeather API key in .env file.',
      );
    }

    return WeatherModel(
      temperature: (json['main']?['temp'] as num?)?.toDouble() ?? 0.0,
      feelsLike: (json['main']?['feels_like'] as num?)?.toDouble() ?? 0.0,
      condition: json['weather']?[0]?['main'] as String? ?? 'Unknown',
      description: json['weather']?[0]?['description'] as String? ?? 'No description',
      humidity: json['main']?['humidity'] as int? ?? 0,
      windSpeed: (json['wind']?['speed'] as num?)?.toDouble() ?? 0.0,
      pressure: json['main']?['pressure'] as int? ?? 0,
      cityName: json['name'] as String? ?? 'Unknown',
      forecast: [], // Will be populated separately from forecast API
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'temperature': temperature,
      'feelsLike': feelsLike,
      'condition': condition,
      'description': description,
      'humidity': humidity,
      'windSpeed': windSpeed,
      'pressure': pressure,
      'cityName': cityName,
      'forecast': forecast.map((f) => (f as ForecastModel).toJson()).toList(),
    };
  }
}

class ForecastModel extends Forecast {
  const ForecastModel({
    required super.date,
    required super.maxTemp,
    required super.minTemp,
    required super.condition,
    required super.description,
    required super.humidity,
  });

  factory ForecastModel.fromJson(Map<String, dynamic> json) {
    // Check if this is serialized format (from toJson) or API format
    final bool isSerializedFormat = json.containsKey('maxTemp');

    if (isSerializedFormat) {
      // Handle our own serialized format (from toJson/cache)
      return ForecastModel(
        date: DateTime.fromMillisecondsSinceEpoch(json['dt'] as int),
        maxTemp: (json['maxTemp'] as num?)?.toDouble() ?? 0.0,
        minTemp: (json['minTemp'] as num?)?.toDouble() ?? 0.0,
        condition: json['condition'] as String? ?? 'Unknown',
        description: json['description'] as String? ?? 'No description',
        humidity: json['humidity'] as int? ?? 0,
      );
    }

    // Handle OpenWeather API format
    if (json['main'] == null || json['weather'] == null) {
      throw FormatException('Invalid forecast data from API');
    }

    return ForecastModel(
      date: DateTime.fromMillisecondsSinceEpoch((json['dt'] as int? ?? 0) * 1000),
      maxTemp: (json['main']?['temp_max'] as num?)?.toDouble() ?? 0.0,
      minTemp: (json['main']?['temp_min'] as num?)?.toDouble() ?? 0.0,
      condition: json['weather']?[0]?['main'] as String? ?? 'Unknown',
      description: json['weather']?[0]?['description'] as String? ?? 'No description',
      humidity: json['main']?['humidity'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dt': date.millisecondsSinceEpoch ~/ 1000,
      'maxTemp': maxTemp,
      'minTemp': minTemp,
      'condition': condition,
      'description': description,
      'humidity': humidity,
    };
  }
}
