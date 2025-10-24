import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../domain/entities/weather.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../core/theme/color_palette.dart';

class WeatherCard extends StatelessWidget {
  final Weather weather;

  const WeatherCard({super.key, required this.weather});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _getWeatherGradient(weather.condition),
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 20.w,
                          color: Colors.white.withOpacity(0.9),
                        ),
                        SizedBox(width: 6.w),
                        Expanded(
                          child: Text(
                            _getLocationDisplay(weather),
                            style: AppTextStyles.heading3.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Padding(
                      padding: EdgeInsets.only(left: 26.w),
                      child: Text(
                        weather.condition,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (weather.icon != null)
                Image.network(
                  'https://openweathermap.org/img/wn/${weather.icon}@2x.png',
                  width: 60.w,
                  height: 60.w,
                  errorBuilder: (context, error, stackTrace) =>
                      Icon(Icons.cloud, size: 60.w, color: Colors.white),
                ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${weather.temperature.toStringAsFixed(0)}°',
                style: TextStyle(
                  fontSize: 64.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  height: 1,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 8.h),
                    _buildWeatherDetail(
                      'Feels like ${weather.feelsLike.toStringAsFixed(0)}°',
                    ),
                    _buildWeatherDetail('Humidity ${weather.humidity}%'),
                    _buildWeatherDetail(
                      'Wind ${weather.windSpeed.toStringAsFixed(1)} m/s',
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (weather.forecast.isNotEmpty) ...[
            SizedBox(height: 20.h),
            const Divider(color: Colors.white38),
            SizedBox(height: 12.h),
            Text(
              '5-Day Forecast',
              style: AppTextStyles.bodyMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 12.h),
            SizedBox(
              height: 80.h,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: weather.forecast.length,
                itemBuilder: (context, index) {
                  final forecast = weather.forecast[index];
                  return Container(
                    width: 70.w,
                    margin: EdgeInsets.only(right: 12.w),
                    child: Column(
                      children: [
                        Text(
                          _formatDay(forecast.date),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        SizedBox(height: 4.h),
                        if (forecast.icon != null)
                          Image.network(
                            'https://openweathermap.org/img/wn/${forecast.icon}.png',
                            width: 32.w,
                            height: 32.w,
                            errorBuilder: (context, error, stackTrace) =>
                                Icon(Icons.cloud, size: 32.w, color: Colors.white70),
                          ),
                        SizedBox(height: 4.h),
                        Text(
                          '${forecast.maxTemperature.toStringAsFixed(0)}°/${forecast.minTemperature.toStringAsFixed(0)}°',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
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
    );
  }

  Widget _buildWeatherDetail(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4.h),
      child: Text(
        text,
        style: AppTextStyles.bodySmall.copyWith(
          color: Colors.white.withOpacity(0.9),
        ),
      ),
    );
  }

  String _formatDay(DateTime date) {
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));

    if (date.day == now.day) return 'Today';
    if (date.day == tomorrow.day) return 'Tomorrow';

    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }

  List<Color> _getWeatherGradient(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
        return [const Color(0xFF56CCF2), const Color(0xFF2F80ED)];
      case 'clouds':
        return [const Color(0xFF7F7FD5), const Color(0xFF86A8E7)];
      case 'rain':
      case 'drizzle':
        return [const Color(0xFF4A5568), const Color(0xFF2D3748)];
      case 'thunderstorm':
        return [const Color(0xFF2C3E50), const Color(0xFF4CA1AF)];
      case 'snow':
        return [const Color(0xFFE0EAFC), const Color(0xFFCFDEF3)];
      default:
        return [ColorPalette.primary, ColorPalette.primary.withOpacity(0.8)];
    }
  }

  /// Format location display with city and country
  String _getLocationDisplay(Weather weather) {
    final location = weather.location;
    final country = weather.country;

    if (country != null && country.isNotEmpty) {
      // Convert country code to full name if available
      final countryName = _getCountryName(country);
      return '$location, $countryName';
    }

    // Special handling for known locations without country data
    if (location.toLowerCase().contains('mountain view')) {
      return '$location, California, United States'; // Mountain View is typically in California, US
    }

    // Check if location might indicate a specific region
    final detectedCountry = _detectCountryFromLocation(location);
    if (detectedCountry != null) {
      return '$location, $detectedCountry';
    }

    // Fallback to just the city name
    return location;
  }

  /// Try to detect country from location name patterns
  String? _detectCountryFromLocation(String location) {
    final lowerLocation = location.toLowerCase();

    // Add patterns for common cities that might appear without country codes
    if (lowerLocation.contains('london') && !lowerLocation.contains('ontario')) {
      return 'United Kingdom';
    }
    if (lowerLocation.contains('paris') && !lowerLocation.contains('texas')) {
      return 'France';
    }
    if (lowerLocation.contains('moscow')) {
      return 'Russia';
    }
    if (lowerLocation.contains('tokyo')) {
      return 'Japan';
    }
    if (lowerLocation.contains('beijing')) {
      return 'China';
    }

    // Add Turkmenistan cities
    const turkmenCities = ['ashgabat', 'turkmenbashi', 'mary', 'turkmenabat', 'balkanabat'];
    for (final city in turkmenCities) {
      if (lowerLocation.contains(city)) {
        return 'Turkmenistan';
      }
    }

    return null;
  }

  /// Convert country code to readable country name
  String _getCountryName(String countryCode) {
    const countryNames = {
      'US': 'United States',
      'GB': 'United Kingdom',
      'CA': 'Canada',
      'AU': 'Australia',
      'DE': 'Germany',
      'FR': 'France',
      'IT': 'Italy',
      'ES': 'Spain',
      'JP': 'Japan',
      'CN': 'China',
      'IN': 'India',
      'BR': 'Brazil',
      'RU': 'Russia',
      'MX': 'Mexico',
      'NL': 'Netherlands',
      'SE': 'Sweden',
      'NO': 'Norway',
      'DK': 'Denmark',
      'FI': 'Finland',
      'CH': 'Switzerland',
      'AT': 'Austria',
      'BE': 'Belgium',
      'IE': 'Ireland',
      'PT': 'Portugal',
      'PL': 'Poland',
      'CZ': 'Czech Republic',
      'HU': 'Hungary',
      'GR': 'Greece',
      'TR': 'Turkey',
      'TM': 'Turkmenistan',
      'EG': 'Egypt',
      'ZA': 'South Africa',
      'NG': 'Nigeria',
      'KE': 'Kenya',
      'AR': 'Argentina',
      'CL': 'Chile',
      'PE': 'Peru',
      'CO': 'Colombia',
      'VE': 'Venezuela',
      'TH': 'Thailand',
      'VN': 'Vietnam',
      'MY': 'Malaysia',
      'SG': 'Singapore',
      'ID': 'Indonesia',
      'PH': 'Philippines',
      'KR': 'South Korea',
      'TW': 'Taiwan',
      'HK': 'Hong Kong',
      'NZ': 'New Zealand',
    };

    return countryNames[countryCode.toUpperCase()] ?? countryCode;
  }
}
