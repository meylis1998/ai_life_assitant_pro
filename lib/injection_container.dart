import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/network/api_client.dart';
import 'core/network/network_info.dart';
import 'core/utils/logger.dart';

// Import feature dependencies
import 'features/ai_chat/data/datasources/ai_chat_local_datasource.dart';
import 'features/ai_chat/data/datasources/ai_chat_remote_datasource.dart';
import 'features/ai_chat/data/repositories/ai_chat_repository_impl.dart';
import 'features/ai_chat/domain/repositories/ai_chat_repository.dart';
import 'features/ai_chat/domain/usecases/get_chat_history.dart';
import 'features/ai_chat/domain/usecases/send_message.dart';
import 'features/ai_chat/domain/usecases/stream_response.dart';
import 'features/ai_chat/presentation/bloc/chat_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  AppLogger.i('🚀 Initializing dependencies...');

  //! Features
  // AI Chat Feature
  _initAIChatFeature();

  //! Core
  sl.registerLazySingleton<NetworkInfo>(
    () => NetworkInfoImpl(sl()),
  );

  sl.registerLazySingleton<ApiClient>(
    () => ApiClient(),
  );

  //! External
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);

  sl.registerLazySingleton(() => Dio());
  sl.registerLazySingleton(() => Connectivity());

  // Register Gemini API if key exists
  final geminiKey = dotenv.env['GEMINI_API_KEY'];
  if (geminiKey != null && geminiKey.isNotEmpty) {
    sl.registerLazySingleton(
      () => GenerativeModel(
        model: 'gemini-pro',
        apiKey: geminiKey,
      ),
    );
    AppLogger.i('✅ Gemini API registered');
  } else {
    AppLogger.w('⚠️ Gemini API key not found');
  }

  AppLogger.i('✅ Dependencies initialized successfully');
}

// Feature-specific initialization functions
void _initAIChatFeature() {
  // Bloc
  sl.registerFactory(
    () => ChatBloc(
      sendMessage: sl(),
      streamResponse: sl(),
      getChatHistory: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => SendMessage(sl()));
  sl.registerLazySingleton(() => StreamResponse(sl()));
  sl.registerLazySingleton(() => GetChatHistory(sl()));

  // Repository
  sl.registerLazySingleton<AIChatRepository>(
    () => AIChatRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  // Data sources
  sl.registerLazySingleton<AIChatRemoteDataSource>(
    () => AIChatRemoteDataSourceImpl(
      apiClient: sl(),
    ),
  );

  sl.registerLazySingleton<AIChatLocalDataSource>(
    () => AIChatLocalDataSourceImpl(
      sharedPreferences: sl(),
    ),
  );
}