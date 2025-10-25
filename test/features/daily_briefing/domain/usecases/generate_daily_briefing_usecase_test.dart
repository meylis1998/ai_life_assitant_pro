import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dartz/dartz.dart';

import 'package:ai_life_assistant_pro/core/errors/failures.dart';
import 'package:ai_life_assistant_pro/features/daily_briefing/domain/entities/daily_briefing.dart';
import 'package:ai_life_assistant_pro/features/daily_briefing/domain/entities/weather.dart';
import 'package:ai_life_assistant_pro/features/daily_briefing/domain/entities/news_article.dart';
import 'package:ai_life_assistant_pro/features/daily_briefing/domain/entities/calendar_event.dart';
import 'package:ai_life_assistant_pro/features/daily_briefing/domain/entities/ai_insights.dart';
import 'package:ai_life_assistant_pro/features/daily_briefing/domain/repositories/briefing_repository.dart';
import 'package:ai_life_assistant_pro/features/daily_briefing/domain/usecases/generate_daily_briefing_usecase.dart';

import 'generate_daily_briefing_usecase_test.mocks.dart';

@GenerateMocks([BriefingRepository])
void main() {
  late GenerateDailyBriefingUseCase useCase;
  late MockBriefingRepository mockRepository;

  setUp(() {
    mockRepository = MockBriefingRepository();
    useCase = GenerateDailyBriefingUseCase(mockRepository);
  });

  group('GenerateDailyBriefingUseCase', () {
    const tPreferences = BriefingPreferences(
      preferredCity: 'Test City',
      country: 'us',
      newsCategories: ['technology', 'business'],
      userName: 'Test User',
    );

    final tBriefing = DailyBriefing(
      id: 'test-id',
      generatedAt: DateTime.now(),
      weather: const Weather(
        temperature: 22.5,
        condition: 'Sunny',
        humidity: 65,
        windSpeed: 5.2,
        location: 'Test City',
        forecast: [],
      ),
      topNews: const [
        NewsArticle(
          title: 'Test News',
          description: 'Test Description',
          source: 'Test Source',
          url: 'https://test.com',
          publishedAt: '2024-01-01T00:00:00Z',
        ),
      ],
      todayEvents: const [
        CalendarEvent(
          title: 'Test Event',
          startTime: '2024-01-01T09:00:00Z',
          endTime: '2024-01-01T10:00:00Z',
          isAllDay: false,
        ),
      ],
      insights: const AIInsights(
        greeting: 'Good morning, Test User!',
        summary: 'Test summary',
        priorities: ['Priority 1', 'Priority 2'],
        suggestions: ['Suggestion 1', 'Suggestion 2'],
      ),
    );

    test('should return DailyBriefing when repository succeeds', () async {
      // arrange
      when(mockRepository.generateBriefing(
        preferences: anyNamed('preferences'),
        forceRefresh: anyNamed('forceRefresh'),
      )).thenAnswer((_) async => Right(tBriefing));

      // act
      final result = await useCase(const GenerateDailyBriefingParams(
        preferences: tPreferences,
        forceRefresh: false,
      ));

      // assert
      expect(result, Right(tBriefing));
      verify(mockRepository.generateBriefing(
        preferences: tPreferences,
        forceRefresh: false,
      ));
      verifyNoMoreInteractions(mockRepository);
    });

    test('should return Failure when repository fails', () async {
      // arrange
      const tFailure = ServerFailure(message: 'Server error');
      when(mockRepository.generateBriefing(
        preferences: anyNamed('preferences'),
        forceRefresh: anyNamed('forceRefresh'),
      )).thenAnswer((_) async => const Left(tFailure));

      // act
      final result = await useCase(const GenerateDailyBriefingParams(
        preferences: tPreferences,
        forceRefresh: false,
      ));

      // assert
      expect(result, const Left(tFailure));
      verify(mockRepository.generateBriefing(
        preferences: tPreferences,
        forceRefresh: false,
      ));
      verifyNoMoreInteractions(mockRepository);
    });

    test('should pass forceRefresh parameter correctly', () async {
      // arrange
      when(mockRepository.generateBriefing(
        preferences: anyNamed('preferences'),
        forceRefresh: anyNamed('forceRefresh'),
      )).thenAnswer((_) async => Right(tBriefing));

      // act
      await useCase(const GenerateDailyBriefingParams(
        preferences: tPreferences,
        forceRefresh: true,
      ));

      // assert
      verify(mockRepository.generateBriefing(
        preferences: tPreferences,
        forceRefresh: true,
      ));
    });
  });
}