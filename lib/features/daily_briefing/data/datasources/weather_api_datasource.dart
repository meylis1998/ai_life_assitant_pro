import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/weather_model.dart';

/// Remote data source for weather data using OpenWeatherMap API
abstract class WeatherApiDataSource {
  /// Get current weather and forecast by coordinates
  Future<WeatherModel> getWeather({
    required double latitude,
    required double longitude,
  });

  /// Get current weather and forecast by city name
  Future<WeatherModel> getWeatherByCity(String cityName);
}

class WeatherApiDataSourceImpl implements WeatherApiDataSource {
  final Dio dio;
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5';

  WeatherApiDataSourceImpl({required this.dio});

  String get _apiKey => dotenv.env['OPENWEATHER_API_KEY'] ?? '';

  @override
  Future<WeatherModel> getWeather({
    required double latitude,
    required double longitude,
  }) async {
    try {
      // Fetch current weather
      final currentResponse = await dio.get(
        '$_baseUrl/weather',
        queryParameters: {
          'lat': latitude,
          'lon': longitude,
          'appid': _apiKey,
          'units': 'metric', // Celsius
        },
      );

      // Fetch 5-day forecast
      final forecastResponse = await dio.get(
        '$_baseUrl/forecast',
        queryParameters: {
          'lat': latitude,
          'lon': longitude,
          'appid': _apiKey,
          'units': 'metric',
        },
      );

      return WeatherModel.fromOpenWeatherMap(
        currentWeather: currentResponse.data as Map<String, dynamic>,
        forecastData: forecastResponse.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Unexpected error fetching weather: $e');
    }
  }

  @override
  Future<WeatherModel> getWeatherByCity(String cityName) async {
    try {
      // Fetch current weather
      final currentResponse = await dio.get(
        '$_baseUrl/weather',
        queryParameters: {
          'q': cityName,
          'appid': _apiKey,
          'units': 'metric',
        },
      );

      // Extract coordinates for forecast
      final coord = currentResponse.data['coord'] as Map<String, dynamic>;
      final lat = (coord['lat'] as num).toDouble();
      final lon = (coord['lon'] as num).toDouble();

      // Fetch forecast
      final forecastResponse = await dio.get(
        '$_baseUrl/forecast',
        queryParameters: {
          'lat': lat,
          'lon': lon,
          'appid': _apiKey,
          'units': 'metric',
        },
      );

      return WeatherModel.fromOpenWeatherMap(
        currentWeather: currentResponse.data as Map<String, dynamic>,
        forecastData: forecastResponse.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Unexpected error fetching weather: $e');
    }
  }

  Exception _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return Exception('Connection timeout. Please check your internet.');
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        if (statusCode == 401) {
          return Exception('Invalid API key');
        } else if (statusCode == 404) {
          return Exception('Location not found');
        } else if (statusCode == 429) {
          return Exception('API rate limit exceeded');
        }
        return Exception('Server error: ${error.response?.statusMessage}');
      case DioExceptionType.cancel:
        return Exception('Request cancelled');
      case DioExceptionType.unknown:
        return Exception('Network error. Please check your connection.');
      default:
        return Exception('Unexpected error occurred');
    }
  }
}
