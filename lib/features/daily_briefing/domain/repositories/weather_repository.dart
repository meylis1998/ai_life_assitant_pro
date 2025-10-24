import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/weather.dart';

/// Abstract repository interface for weather data
abstract class WeatherRepository {
  /// Get current weather and forecast for a specific location
  ///
  /// Parameters:
  /// - [latitude]: Location latitude
  /// - [longitude]: Location longitude
  ///
  /// Returns:
  /// - Right(Weather) on success
  /// - Left(Failure) on error (network, server, cache, etc.)
  Future<Either<Failure, Weather>> getWeather({
    required double latitude,
    required double longitude,
  });

  /// Get current weather by city name
  ///
  /// Parameters:
  /// - [cityName]: Name of the city
  ///
  /// Returns:
  /// - Right(Weather) on success
  /// - Left(Failure) on error
  Future<Either<Failure, Weather>> getWeatherByCity(String cityName);
}
