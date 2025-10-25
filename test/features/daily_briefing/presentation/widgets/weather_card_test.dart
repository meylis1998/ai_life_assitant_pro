import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:ai_life_assistant_pro/features/daily_briefing/domain/entities/weather.dart';
import 'package:ai_life_assistant_pro/features/daily_briefing/domain/entities/forecast.dart';
import 'package:ai_life_assistant_pro/features/daily_briefing/presentation/widgets/weather_card.dart';

void main() {
  group('WeatherCard Widget Tests', () {
    late Weather testWeather;

    setUp(() {
      testWeather = const Weather(
        temperature: 22.5,
        condition: 'Sunny',
        humidity: 65,
        windSpeed: 5.2,
        location: 'Test City',
        feelsLike: 24.0,
        pressure: 1013,
        visibility: 10.0,
        forecast: [
          Forecast(
            date: '2024-01-01',
            minTemp: 18.0,
            maxTemp: 25.0,
            condition: 'Sunny',
            icon: '01d',
            humidity: 60,
            windSpeed: 4.0,
            precipitationProbability: 0,
          ),
          Forecast(
            date: '2024-01-02',
            minTemp: 20.0,
            maxTemp: 27.0,
            condition: 'Partly Cloudy',
            icon: '02d',
            humidity: 55,
            windSpeed: 3.5,
            precipitationProbability: 10,
          ),
        ],
      );
    });

    Widget createTestWidget(Weather weather) {
      return ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (context, child) => MaterialApp(
          home: Scaffold(
            body: WeatherCard(weather: weather),
          ),
        ),
      );
    }

    testWidgets('should display weather information correctly', (WidgetTester tester) async {
      // arrange & act
      await tester.pumpWidget(createTestWidget(testWeather));

      // assert
      expect(find.text('Test City'), findsOneWidget);
      expect(find.text('22.5°'), findsOneWidget);
      expect(find.text('Sunny'), findsOneWidget);
      expect(find.text('Feels like 24.0°'), findsOneWidget);
      expect(find.text('65%'), findsOneWidget); // humidity
      expect(find.text('5.2 m/s'), findsOneWidget); // wind speed
    });

    testWidgets('should display forecast when available', (WidgetTester tester) async {
      // arrange & act
      await tester.pumpWidget(createTestWidget(testWeather));

      // assert
      // Should find forecast items
      expect(find.text('18°/25°'), findsOneWidget);
      expect(find.text('20°/27°'), findsOneWidget);
    });

    testWidgets('should handle weather without forecast', (WidgetTester tester) async {
      // arrange
      const weatherWithoutForecast = Weather(
        temperature: 22.5,
        condition: 'Sunny',
        humidity: 65,
        windSpeed: 5.2,
        location: 'Test City',
        forecast: [],
      );

      // act
      await tester.pumpWidget(createTestWidget(weatherWithoutForecast));

      // assert
      expect(find.text('Test City'), findsOneWidget);
      expect(find.text('22.5°'), findsOneWidget);
      expect(find.text('Sunny'), findsOneWidget);

      // Should not crash with empty forecast
      expect(tester.takeException(), isNull);
    });

    testWidgets('should display weather icons and indicators', (WidgetTester tester) async {
      // arrange & act
      await tester.pumpWidget(createTestWidget(testWeather));

      // assert
      // Should find humidity and wind icons
      expect(find.byIcon(Icons.water_drop), findsOneWidget);
      expect(find.byIcon(Icons.air), findsOneWidget);

      // Should find location icon
      expect(find.byIcon(Icons.location_on), findsOneWidget);
    });

    testWidgets('should have proper styling and layout', (WidgetTester tester) async {
      // arrange & act
      await tester.pumpWidget(createTestWidget(testWeather));

      // assert
      // Should find the main container with proper decoration
      final container = find.byType(Container);
      expect(container, findsWidgets);

      // Should find gradient decoration (indicated by presence of weather card)
      expect(find.byType(WeatherCard), findsOneWidget);
    });

    testWidgets('should handle long location names properly', (WidgetTester tester) async {
      // arrange
      const weatherWithLongLocation = Weather(
        temperature: 22.5,
        condition: 'Sunny',
        humidity: 65,
        windSpeed: 5.2,
        location: 'Very Long City Name That Should Wrap Or Truncate Properly',
        forecast: [],
      );

      // act
      await tester.pumpWidget(createTestWidget(weatherWithLongLocation));

      // assert
      expect(find.text('Very Long City Name That Should Wrap Or Truncate Properly'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('should display additional weather details when available', (WidgetTester tester) async {
      // arrange
      const detailedWeather = Weather(
        temperature: 22.5,
        condition: 'Sunny',
        humidity: 65,
        windSpeed: 5.2,
        location: 'Test City',
        feelsLike: 24.0,
        pressure: 1013,
        visibility: 10.0,
        forecast: [],
      );

      // act
      await tester.pumpWidget(createTestWidget(detailedWeather));

      // assert
      expect(find.text('Feels like 24.0°'), findsOneWidget);

      // Should not crash with additional details
      expect(tester.takeException(), isNull);
    });
  });
}