import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../models/weather_model.dart';

abstract class WeatherApiDataSource {
  Future<WeatherModel> getCurrentWeather({
    String? cityName,
    double? latitude,
    double? longitude,
  });

  Future<List<ForecastModel>> getForecast({
    String? cityName,
    double? latitude,
    double? longitude,
  });
}

class WeatherApiDataSourceImpl implements WeatherApiDataSource {
  final http.Client client;
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5';

  WeatherApiDataSourceImpl({required this.client});

  String get _apiKey => dotenv.env['OPENWEATHER_API_KEY'] ?? '';

  @override
  Future<WeatherModel> getCurrentWeather({
    String? cityName,
    double? latitude,
    double? longitude,
  }) async {
    String url;
    if (cityName != null) {
      url = '$_baseUrl/weather?q=$cityName&appid=$_apiKey&units=metric';
    } else if (latitude != null && longitude != null) {
      url = '$_baseUrl/weather?lat=$latitude&lon=$longitude&appid=$_apiKey&units=metric';
    } else {
      throw Exception('Either cityName or coordinates must be provided');
    }

    final response = await client.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final responseBody = response.body;
      final decodedJson = json.decode(responseBody);

      // Log response for debugging
      print('Weather API Response: $decodedJson');

      return WeatherModel.fromJson(decodedJson);
    } else if (response.statusCode == 401) {
      throw Exception('Invalid API key');
    } else if (response.statusCode == 404) {
      throw Exception('City not found');
    } else {
      final errorBody = response.body;
      throw Exception('Failed to load weather: ${response.statusCode}. Response: $errorBody');
    }
  }

  @override
  Future<List<ForecastModel>> getForecast({
    String? cityName,
    double? latitude,
    double? longitude,
  }) async {
    String url;
    if (cityName != null) {
      url = '$_baseUrl/forecast?q=$cityName&appid=$_apiKey&units=metric&cnt=5';
    } else if (latitude != null && longitude != null) {
      url = '$_baseUrl/forecast?lat=$latitude&lon=$longitude&appid=$_apiKey&units=metric&cnt=5';
    } else {
      throw Exception('Either cityName or coordinates must be provided');
    }

    final response = await client.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final responseBody = response.body;
      final data = json.decode(responseBody);

      // Log response for debugging
      print('Forecast API Response: $data');

      final List<dynamic> forecastList = data['list'];

      // Take one forecast per day (every 8th item, as data comes in 3-hour intervals)
      final dailyForecasts = <ForecastModel>[];
      for (int i = 0; i < forecastList.length; i += 8) {
        if (i < forecastList.length) {
          dailyForecasts.add(ForecastModel.fromJson(forecastList[i]));
        }
      }

      return dailyForecasts;
    } else if (response.statusCode == 401) {
      throw Exception('Invalid API key for forecast endpoint');
    } else if (response.statusCode == 404) {
      throw Exception('City not found for forecast');
    } else {
      final errorBody = response.body;
      throw Exception('Failed to load forecast: ${response.statusCode}. Response: $errorBody');
    }
  }
}
