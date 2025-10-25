import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dartz/dartz.dart';

import 'package:ai_life_assistant_pro/core/errors/failures.dart';
import 'package:ai_life_assistant_pro/core/usecases/usecase.dart';
import 'package:ai_life_assistant_pro/features/daily_briefing/domain/entities/daily_briefing.dart';
import 'package:ai_life_assistant_pro/features/daily_briefing/domain/entities/weather.dart';
import 'package:ai_life_assistant_pro/features/daily_briefing/domain/entities/news_article.dart';
import 'package:ai_life_assistant_pro/features/daily_briefing/domain/entities/calendar_event.dart';
import 'package:ai_life_assistant_pro/features/daily_briefing/domain/entities/ai_insights.dart';
import 'package:ai_life_assistant_pro/features/daily_briefing/domain/repositories/briefing_repository.dart';
import 'package:ai_life_assistant_pro/features/daily_briefing/domain/usecases/generate_daily_briefing_usecase.dart';
import 'package:ai_life_assistant_pro/features/daily_briefing/domain/usecases/get_preferences_usecase.dart';
import 'package:ai_life_assistant_pro/features/daily_briefing/domain/usecases/save_preferences_usecase.dart';
import 'package:ai_life_assistant_pro/features/daily_briefing/domain/usecases/get_cached_briefing_usecase.dart';
import 'package:ai_life_assistant_pro/features/daily_briefing/presentation/bloc/briefing_bloc.dart';

import 'briefing_bloc_test.mocks.dart';

@GenerateMocks([
  GenerateDailyBriefingUseCase,
  GetPreferencesUseCase,
  SavePreferencesUseCase,
  GetCachedBriefingUseCase,
])
void main() {
  late BriefingBloc bloc;
  late MockGenerateDailyBriefingUseCase mockGenerateDailyBriefingUseCase;
  late MockGetPreferencesUseCase mockGetPreferencesUseCase;
  late MockSavePreferencesUseCase mockSavePreferencesUseCase;
  late MockGetCachedBriefingUseCase mockGetCachedBriefingUseCase;

  setUp(() {
    mockGenerateDailyBriefingUseCase = MockGenerateDailyBriefingUseCase();
    mockGetPreferencesUseCase = MockGetPreferencesUseCase();
    mockSavePreferencesUseCase = MockSavePreferencesUseCase();
    mockGetCachedBriefingUseCase = MockGetCachedBriefingUseCase();

    bloc = BriefingBloc(
      generateDailyBriefingUseCase: mockGenerateDailyBriefingUseCase,
      getPreferencesUseCase: mockGetPreferencesUseCase,
      savePreferencesUseCase: mockSavePreferencesUseCase,
      getCachedBriefingUseCase: mockGetCachedBriefingUseCase,
    );
  });

  tearDown(() {
    bloc.close();
  });

  group('BriefingBloc', () {
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

    test('initial state should be BriefingInitial', () {
      expect(bloc.state, equals(const BriefingInitial()));
    });

    group('BriefingRequested', () {
      blocTest<BriefingBloc, BriefingState>(
        'should emit [BriefingLoading, BriefingLoaded] when briefing generation succeeds',
        build: () {
          when(mockGetPreferencesUseCase(any))
              .thenAnswer((_) async => const Right(tPreferences));
          when(mockGenerateDailyBriefingUseCase(any))
              .thenAnswer((_) async => Right(tBriefing));
          return bloc;
        },
        act: (bloc) => bloc.add(const BriefingRequested()),
        expect: () => [
          const BriefingLoading(),
          BriefingLoaded(
            briefing: tBriefing,
            preferences: tPreferences,
            isFromCache: false,
          ),
        ],
      );

      blocTest<BriefingBloc, BriefingState>(
        'should emit [BriefingLoading, BriefingError] when preferences fetch fails',
        build: () {
          when(mockGetPreferencesUseCase(any))
              .thenAnswer((_) async => const Left(ServerFailure()));
          return bloc;
        },
        act: (bloc) => bloc.add(const BriefingRequested()),
        expect: () => [
          const BriefingLoading(),
          isA<BriefingError>(),
        ],
      );

      blocTest<BriefingBloc, BriefingState>(
        'should emit [BriefingLoading, BriefingError] with cached data when briefing generation fails but cache exists',
        build: () {
          when(mockGetPreferencesUseCase(any))
              .thenAnswer((_) async => const Right(tPreferences));
          when(mockGenerateDailyBriefingUseCase(any))
              .thenAnswer((_) async => const Left(ServerFailure()));
          when(mockGetCachedBriefingUseCase(any))
              .thenAnswer((_) async => Right(tBriefing));
          return bloc;
        },
        act: (bloc) => bloc.add(const BriefingRequested()),
        expect: () => [
          const BriefingLoading(),
          isA<BriefingError>().having(
            (state) => state.cachedBriefing,
            'cachedBriefing',
            equals(tBriefing),
          ),
        ],
      );
    });

    group('BriefingRefreshed', () {
      blocTest<BriefingBloc, BriefingState>(
        'should emit [BriefingLoaded] when refresh succeeds',
        build: () {
          when(mockGetPreferencesUseCase(any))
              .thenAnswer((_) async => const Right(tPreferences));
          when(mockGenerateDailyBriefingUseCase(any))
              .thenAnswer((_) async => Right(tBriefing));
          return bloc;
        },
        act: (bloc) => bloc.add(const BriefingRefreshed()),
        expect: () => [
          BriefingLoaded(
            briefing: tBriefing,
            preferences: tPreferences,
            isFromCache: false,
          ),
        ],
      );
    });

    group('CachedBriefingRequested', () {
      blocTest<BriefingBloc, BriefingState>(
        'should emit [BriefingLoading, BriefingLoaded] when cached briefing exists',
        build: () {
          when(mockGetPreferencesUseCase(any))
              .thenAnswer((_) async => const Right(tPreferences));
          when(mockGetCachedBriefingUseCase(any))
              .thenAnswer((_) async => Right(tBriefing));
          return bloc;
        },
        act: (bloc) => bloc.add(const CachedBriefingRequested()),
        expect: () => [
          const BriefingLoading(),
          BriefingLoaded(
            briefing: tBriefing,
            preferences: tPreferences,
            isFromCache: true,
          ),
        ],
      );

      blocTest<BriefingBloc, BriefingState>(
        'should emit [BriefingLoading, BriefingError] when no cached briefing exists',
        build: () {
          when(mockGetPreferencesUseCase(any))
              .thenAnswer((_) async => const Right(tPreferences));
          when(mockGetCachedBriefingUseCase(any))
              .thenAnswer((_) async => const Left(CacheFailure()));
          return bloc;
        },
        act: (bloc) => bloc.add(const CachedBriefingRequested()),
        expect: () => [
          const BriefingLoading(),
          isA<BriefingError>(),
        ],
      );
    });

    group('PreferencesSaved', () {
      blocTest<BriefingBloc, BriefingState>(
        'should update current state preferences when save succeeds and state is BriefingLoaded',
        build: () {
          when(mockSavePreferencesUseCase(any))
              .thenAnswer((_) async => const Right(null));
          return bloc;
        },
        seed: () => BriefingLoaded(
          briefing: tBriefing,
          preferences: tPreferences,
          isFromCache: false,
        ),
        act: (bloc) {
          const newPreferences = BriefingPreferences(
            preferredCity: 'New City',
            country: 'ca',
            newsCategories: ['sports'],
            userName: 'New User',
          );
          bloc.add(const PreferencesSaved(newPreferences));
        },
        expect: () => [
          isA<BriefingLoaded>().having(
            (state) => state.preferences.preferredCity,
            'preferredCity',
            equals('New City'),
          ),
        ],
      );
    });

    group('PreferencesRequested', () {
      blocTest<BriefingBloc, BriefingState>(
        'should emit [PreferencesLoaded] when preferences fetch succeeds',
        build: () {
          when(mockGetPreferencesUseCase(any))
              .thenAnswer((_) async => const Right(tPreferences));
          return bloc;
        },
        act: (bloc) => bloc.add(const PreferencesRequested()),
        expect: () => [
          const PreferencesLoaded(tPreferences),
        ],
      );

      blocTest<BriefingBloc, BriefingState>(
        'should emit [BriefingError] when preferences fetch fails',
        build: () {
          when(mockGetPreferencesUseCase(any))
              .thenAnswer((_) async => const Left(ServerFailure()));
          return bloc;
        },
        act: (bloc) => bloc.add(const PreferencesRequested()),
        expect: () => [
          isA<BriefingError>(),
        ],
      );
    });
  });
}