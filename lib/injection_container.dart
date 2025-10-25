import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_calendar/device_calendar.dart';
import 'package:dio/dio.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/network/api_client.dart';
import 'core/network/network_info.dart';
import 'core/services/api_key_service.dart';
import 'core/services/gemini_http_service.dart';
import 'core/services/gemini_model_manager.dart';
import 'core/services/location_service.dart';
import 'core/services/briefing_preferences_service.dart';
import 'core/utils/logger.dart';
import 'core/services/notification_service.dart';
import 'firebase_options.dart';

// Import feature dependencies
// AI Chat Feature
import 'features/ai_chat/data/datasources/ai_chat_local_datasource.dart';
import 'features/ai_chat/data/datasources/ai_chat_remote_datasource.dart';
import 'features/ai_chat/data/repositories/ai_chat_repository_impl.dart';
import 'features/ai_chat/domain/repositories/ai_chat_repository.dart';
import 'features/ai_chat/domain/usecases/get_chat_history.dart';
import 'features/ai_chat/domain/usecases/send_message.dart';
import 'features/ai_chat/domain/usecases/stream_response.dart' as usecases;
import 'features/ai_chat/presentation/bloc/chat_bloc.dart';

// Auth Feature
import 'features/auth/data/datasources/firebase_auth_datasource.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/domain/usecases/get_current_user.dart';
import 'features/auth/domain/usecases/link_apple_account.dart';
import 'features/auth/domain/usecases/link_google_account.dart';
import 'features/auth/domain/usecases/sign_in_with_apple.dart';
import 'features/auth/domain/usecases/sign_in_with_google.dart';
import 'features/auth/domain/usecases/sign_out.dart';
import 'features/auth/domain/usecases/update_user_profile.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';

// Daily Briefing Feature
import 'features/daily_briefing/data/datasources/weather_api_datasource.dart';
import 'features/daily_briefing/data/datasources/news_api_datasource.dart';
import 'features/daily_briefing/data/datasources/calendar_local_datasource.dart';
import 'features/daily_briefing/data/datasources/ai_insights_datasource.dart';
import 'features/daily_briefing/data/datasources/briefing_local_datasource.dart';
import 'features/daily_briefing/data/repositories/weather_repository_impl.dart';
import 'features/daily_briefing/data/repositories/news_repository_impl.dart';
import 'features/daily_briefing/data/repositories/calendar_repository_impl.dart';
import 'features/daily_briefing/data/repositories/ai_insights_repository_impl.dart';
import 'features/daily_briefing/data/repositories/briefing_repository_impl.dart';
import 'features/daily_briefing/domain/repositories/weather_repository.dart';
import 'features/daily_briefing/domain/repositories/news_repository.dart';
import 'features/daily_briefing/domain/repositories/calendar_repository.dart';
import 'features/daily_briefing/domain/repositories/ai_insights_repository.dart';
import 'features/daily_briefing/domain/repositories/briefing_repository.dart';
import 'features/daily_briefing/domain/usecases/get_weather_usecase.dart';
import 'features/daily_briefing/domain/usecases/get_news_usecase.dart';
import 'features/daily_briefing/domain/usecases/get_calendar_events_usecase.dart';
import 'features/daily_briefing/domain/usecases/generate_ai_insights_usecase.dart';
import 'features/daily_briefing/domain/usecases/generate_daily_briefing_usecase.dart';
import 'features/daily_briefing/domain/usecases/schedule_briefing_usecase.dart';
import 'features/daily_briefing/domain/usecases/get_preferences_usecase.dart';
import 'features/daily_briefing/domain/usecases/save_preferences_usecase.dart';
import 'features/daily_briefing/domain/usecases/get_cached_briefing_usecase.dart';
import 'features/daily_briefing/presentation/bloc/briefing_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  AppLogger.i('🚀 Initializing dependencies...');

  //! Features
  // Initialize Firebase
  await _initFirebase();

  _initAuthFeature();

  _initAIChatFeature();

  _initDailyBriefingFeature();

  //! Core
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));
  sl.registerLazySingleton(() => ApiClient());
  sl.registerLazySingleton(() => LocationService());
  sl.registerLazySingleton(() => BriefingPreferencesService(sl()));

  // Notification service
  final notificationsPlugin = FlutterLocalNotificationsPlugin();
  sl.registerLazySingleton(() => notificationsPlugin);
  sl.registerLazySingleton(() => NotificationService(sl()));
  sl.registerLazySingleton(() => const ApiKeyService());
  sl.registerLazySingleton(() => GeminiModelManager());

  //! External
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);

  sl.registerLazySingleton(() => Connectivity());

  // Security
  sl.registerLazySingleton(() => const FlutterSecureStorage());
  sl.registerLazySingleton(() => LocalAuthentication());

  AppLogger.i('✅ Dependencies initialized successfully');
}

// Feature-specific initialization functions
void _initAIChatFeature() {
  // Bloc - Singleton to maintain conversation state
  sl.registerLazySingleton(
    () => ChatBloc(
      sendMessage: sl(),
      streamResponse: sl(),
      getChatHistory: sl(),
      authRepository: sl.isRegistered<AuthRepository>()
          ? sl<AuthRepository>()
          : null,
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => SendMessage(sl()));
  sl.registerLazySingleton(() => usecases.StreamResponse(sl()));
  sl.registerLazySingleton(() => GetChatHistory(sl()));

  // Repository
  sl.registerLazySingleton<AIChatRepository>(
    () => AIChatRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
    ),
  );
  AppLogger.i('✅ AI Chat repository registered');

  // Data sources
  sl.registerLazySingleton<AIChatRemoteDataSource>(
    () => AIChatRemoteDataSourceImpl(
      apiClient: sl(),
      apiKeyService: sl(),
      modelManager: sl(),
    ),
  );

  sl.registerLazySingleton<AIChatLocalDataSource>(
    () => AIChatLocalDataSourceImpl(sharedPreferences: sl()),
  );
}

// Feature-specific initialization for Daily Briefing
void _initDailyBriefingFeature() {
  // Daily Briefing Data Sources
  sl.registerLazySingleton<WeatherApiDataSource>(
    () => WeatherApiDataSourceImpl(dio: sl()),
  );

  sl.registerLazySingleton<NewsApiDataSource>(
    () => NewsApiDataSourceImpl(dio: sl()),
  );

  sl.registerLazySingleton<CalendarLocalDataSource>(
    () => CalendarLocalDataSourceImpl(),
  );

  sl.registerLazySingleton<AIInsightsDataSource>(
    () => AIInsightsDataSourceImpl(),
  );

  sl.registerLazySingleton<BriefingLocalDataSource>(
    () => BriefingLocalDataSourceImpl(
      sharedPreferences: sl<SharedPreferences>(),
    ),
  );

  // Daily Briefing Repositories
  sl.registerLazySingleton<WeatherRepository>(
    () => WeatherRepositoryImpl(
      remoteDataSource: sl<WeatherApiDataSource>(),
      networkInfo: sl<NetworkInfo>(),
    ),
  );

  sl.registerLazySingleton<NewsRepository>(
    () => NewsRepositoryImpl(
      remoteDataSource: sl<NewsApiDataSource>(),
      networkInfo: sl<NetworkInfo>(),
    ),
  );

  sl.registerLazySingleton<CalendarRepository>(
    () => CalendarRepositoryImpl(
      localDataSource: sl<CalendarLocalDataSource>(),
    ),
  );

  sl.registerLazySingleton<AIInsightsRepository>(
    () => AIInsightsRepositoryImpl(
      remoteDataSource: sl<AIInsightsDataSource>(),
    ),
  );

  sl.registerLazySingleton<BriefingRepository>(
    () => BriefingRepositoryImpl(
      weatherRepository: sl<WeatherRepository>(),
      newsRepository: sl<NewsRepository>(),
      calendarRepository: sl<CalendarRepository>(),
      aiInsightsRepository: sl<AIInsightsRepository>(),
      localDataSource: sl<BriefingLocalDataSource>(),
      networkInfo: sl<NetworkInfo>(),
      locationService: sl<LocationService>(),
    ),
  );

  // Daily Briefing Use Cases
  sl.registerLazySingleton<GetWeatherUseCase>(
    () => GetWeatherUseCase(sl<WeatherRepository>()),
  );

  sl.registerLazySingleton<GetNewsUseCase>(
    () => GetNewsUseCase(sl<NewsRepository>()),
  );

  sl.registerLazySingleton<GetCalendarEventsUseCase>(
    () => GetCalendarEventsUseCase(sl<CalendarRepository>()),
  );

  sl.registerLazySingleton<GenerateAIInsightsUseCase>(
    () => GenerateAIInsightsUseCase(sl<AIInsightsRepository>()),
  );

  sl.registerLazySingleton<GenerateDailyBriefingUseCase>(
    () => GenerateDailyBriefingUseCase(sl<BriefingRepository>()),
  );

  sl.registerLazySingleton<ScheduleBriefingUseCase>(
    () => ScheduleBriefingUseCase(),
  );

  sl.registerLazySingleton<GetPreferencesUseCase>(
    () => GetPreferencesUseCase(sl<BriefingRepository>()),
  );

  sl.registerLazySingleton<SavePreferencesUseCase>(
    () => SavePreferencesUseCase(sl<BriefingRepository>()),
  );

  sl.registerLazySingleton<GetCachedBriefingUseCase>(
    () => GetCachedBriefingUseCase(sl<BriefingRepository>()),
  );

  // Daily Briefing BLoC
  sl.registerFactory<BriefingBloc>(
    () => BriefingBloc(
      generateDailyBriefingUseCase: sl<GenerateDailyBriefingUseCase>(),
      getPreferencesUseCase: sl<GetPreferencesUseCase>(),
      savePreferencesUseCase: sl<SavePreferencesUseCase>(),
      getCachedBriefingUseCase: sl<GetCachedBriefingUseCase>(),
    ),
  );

  // Register Dio for HTTP requests
  if (!sl.isRegistered<Dio>()) {
    sl.registerLazySingleton(() => Dio());
  }

  AppLogger.i('✅ Daily Briefing feature initialized');
}

// Initialize Firebase
Future<void> _initFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Register Firebase services
    sl.registerLazySingleton(() => firebase_auth.FirebaseAuth.instance);
    sl.registerLazySingleton(() => GoogleSignIn());

    AppLogger.i('✅ Firebase initialized successfully');
  } catch (e) {
    AppLogger.e('❌ Failed to initialize Firebase: $e');
    // Continue without Firebase - app can still work in guest mode
  }
}

// Initialize Auth Feature
void _initAuthFeature() {
  // Check if Firebase is available
  if (sl.isRegistered<firebase_auth.FirebaseAuth>()) {
    // Bloc - Singleton so router and UI use the same instance
    sl.registerLazySingleton(
      () => AuthBloc(
        signInWithGoogle: sl(),
        signInWithApple: sl(),
        signOut: sl(),
        getCurrentUser: sl(),
        linkGoogleAccount: sl(),
        linkAppleAccount: sl(),
        updateUserProfile: sl(),
        authRepository: sl(),
      ),
    );

    // Use cases
    sl.registerLazySingleton(() => SignInWithGoogle(sl()));
    sl.registerLazySingleton(() => SignInWithApple(sl()));
    sl.registerLazySingleton(() => SignOut(sl()));
    sl.registerLazySingleton(() => GetCurrentUser(sl()));
    sl.registerLazySingleton(() => LinkGoogleAccount(sl()));
    sl.registerLazySingleton(() => LinkAppleAccount(sl()));
    sl.registerLazySingleton(() => UpdateUserProfile(sl()));

    // Repository
    sl.registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(remoteDataSource: sl(), networkInfo: sl()),
    );

    // Data source
    sl.registerLazySingleton<FirebaseAuthDataSource>(
      () => FirebaseAuthDataSourceImpl(
        firebaseAuth: sl(),
        googleSignIn: sl(),
        localAuth: sl(),
        secureStorage: sl(),
      ),
    );

    AppLogger.i('✅ Auth feature initialized');
  } else {
    AppLogger.w('⚠️ Auth feature skipped - Firebase not available');
  }
}
