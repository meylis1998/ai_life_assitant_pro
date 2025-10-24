import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/forecast.dart';

part 'forecast_model.g.dart';

@JsonSerializable()
class ForecastModel extends Forecast {
  const ForecastModel({
    required super.date,
    required super.minTemperature,
    required super.maxTemperature,
    required super.condition,
    super.conditionDescription,
    super.icon,
    super.humidity,
    super.windSpeed,
    super.precipitation,
  });

  factory ForecastModel.fromJson(Map<String, dynamic> json) =>
      _$ForecastModelFromJson(json);

  Map<String, dynamic> toJson() => _$ForecastModelToJson(this);

  /// Create from OpenWeatherMap API response (forecast list item)
  factory ForecastModel.fromOpenWeatherMap(Map<String, dynamic> json) {
    final main = json['main'] as Map<String, dynamic>;
    final weather = (json['weather'] as List).first as Map<String, dynamic>;

    return ForecastModel(
      date: DateTime.fromMillisecondsSinceEpoch(
        (json['dt'] as int) * 1000,
      ),
      minTemperature: (main['temp_min'] as num).toDouble(),
      maxTemperature: (main['temp_max'] as num).toDouble(),
      condition: weather['main'] as String,
      conditionDescription: weather['description'] as String?,
      icon: weather['icon'] as String?,
      humidity: main['humidity'] as int?,
      windSpeed: json['wind'] != null
          ? (json['wind']['speed'] as num?)?.toDouble()
          : null,
      precipitation: json['pop'] != null
          ? ((json['pop'] as num) * 100).toDouble()
          : null,
    );
  }

  Forecast toEntity() => Forecast(
        date: date,
        minTemperature: minTemperature,
        maxTemperature: maxTemperature,
        condition: condition,
        conditionDescription: conditionDescription,
        icon: icon,
        humidity: humidity,
        windSpeed: windSpeed,
        precipitation: precipitation,
      );

  /// Create model from entity
  factory ForecastModel.fromEntity(Forecast entity) {
    return ForecastModel(
      date: entity.date,
      minTemperature: entity.minTemperature,
      maxTemperature: entity.maxTemperature,
      condition: entity.condition,
      conditionDescription: entity.conditionDescription,
      icon: entity.icon,
      humidity: entity.humidity,
      windSpeed: entity.windSpeed,
      precipitation: entity.precipitation,
    );
  }
}
