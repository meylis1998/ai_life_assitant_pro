import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/weather.dart';

class WeatherCard extends StatelessWidget {
  final Weather weather;

  const WeatherCard({super.key, required this.weather});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.wb_sunny, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Weather',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      weather.cityName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${weather.temperature.toStringAsFixed(0)}°C',
                      style: Theme.of(context).textTheme.displayMedium,
                    ),
                    Text(
                      'Feels like ${weather.feelsLike.toStringAsFixed(0)}°C',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      weather.condition,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(weather.description),
                    const SizedBox(height: 8),
                    Text('Humidity: ${weather.humidity}%'),
                    Text('Wind: ${weather.windSpeed.toStringAsFixed(1)} m/s'),
                  ],
                ),
              ],
            ),
            if (weather.forecast.isNotEmpty) ...[
              const Divider(height: 24),
              Text(
                '5-Day Forecast',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: weather.forecast.length,
                  itemBuilder: (context, index) {
                    final forecast = weather.forecast[index];
                    return Container(
                      width: 80,
                      margin: const EdgeInsets.only(right: 12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            DateFormat('EEE').format(forecast.date),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 2),
                          _getWeatherIcon(forecast.condition),
                          const SizedBox(height: 2),
                          Text(
                            '${forecast.maxTemp.toStringAsFixed(0)}°',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          Text(
                            '${forecast.minTemp.toStringAsFixed(0)}°',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _getWeatherIcon(String condition) {
    IconData icon;
    switch (condition.toLowerCase()) {
      case 'clear':
        icon = Icons.wb_sunny;
        break;
      case 'clouds':
        icon = Icons.cloud;
        break;
      case 'rain':
      case 'drizzle':
        icon = Icons.water_drop;
        break;
      case 'snow':
        icon = Icons.ac_unit;
        break;
      case 'thunderstorm':
        icon = Icons.flash_on;
        break;
      default:
        icon = Icons.wb_cloudy;
    }
    return Icon(icon, size: 24);
  }
}
