import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/network/api_client.dart';
import 'core/network/network_info.dart';
import 'core/utils/logger.dart';

// Import feature dependencies
// AI Chat Feature
import 'features/ai_chat/data/datasources/ai_chat_local_datasource.dart';
import 'features/ai_chat/data/datasources/ai_chat_remote_datasource.dart';
import 'features/ai_chat/data/repositories/ai_chat_repository_impl.dart';
import 'features/ai_chat/data/repositories/ai_chat_repository_impl_enhanced.dart';
import 'features/ai_chat/domain/repositories/ai_chat_repository.dart';
import 'features/ai_chat/domain/usecases/get_chat_history.dart';
import 'features/ai_chat/domain/usecases/send_message.dart';
import 'features/ai_chat/domain/usecases/stream_response.dart';
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

// Usage Tracking Feature
import 'features/usage_tracking/data/datasources/usage_local_datasource.dart';
import 'features/usage_tracking/data/datasources/usage_remote_datasource.dart';
import 'features/usage_tracking/data/repositories/usage_repository_impl.dart';
import 'features/usage_tracking/domain/repositories/usage_repository.dart';
import 'features/usage_tracking/domain/usecases/check_quota.dart';
import 'features/usage_tracking/domain/usecases/get_quota_status.dart';
import 'features/usage_tracking/domain/usecases/get_user_subscription.dart';
import 'features/usage_tracking/domain/usecases/get_user_usage_stats.dart';
import 'features/usage_tracking/domain/usecases/log_message_usage.dart';
import 'features/usage_tracking/presentation/bloc/usage_bloc.dart';

final sl = GetIt.instance;

Future<void> init() async {
  AppLogger.i('🚀 Initializing dependencies...');

  //! Features
  // Initialize Firebase
  await _initFirebase();

  // Auth Feature (must be first)
  _initAuthFeature();

  // Usage Tracking Feature (depends on Auth)
  _initUsageTrackingFeature();

  // AI Chat Feature (depends on Auth and Usage Tracking)
  _initAIChatFeature();

  //! Core
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));

  sl.registerLazySingleton<ApiClient>(() => ApiClient());

  //! External
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);

  sl.registerLazySingleton(() => Dio());
  sl.registerLazySingleton(() => Connectivity());

  // Security
  sl.registerLazySingleton(() => const FlutterSecureStorage());
  sl.registerLazySingleton(() => LocalAuthentication());

  AppLogger.i('✅ Dependencies initialized successfully');
}

// Feature-specific initialization functions
void _initAIChatFeature() {
  // Bloc - with enhanced dependencies for usage tracking
  sl.registerFactory(
    () => ChatBloc(
      sendMessage: sl(),
      streamResponse: sl(),
      getChatHistory: sl(),
      authRepository: sl(),
      usageRepository: sl(),
      usageBloc: sl.isRegistered<UsageBloc>() ? sl<UsageBloc>() : null,
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => SendMessage(sl()));
  sl.registerLazySingleton(() => StreamResponse(sl()));
  sl.registerLazySingleton(() => GetChatHistory(sl()));

  // Repository - use enhanced version if Firebase is available
  if (sl.isRegistered<firebase_auth.FirebaseAuth>()) {
    sl.registerLazySingleton<AIChatRepository>(
      () => AIChatRepositoryImplEnhanced(
        remoteDataSource: sl(),
        localDataSource: sl(),
        networkInfo: sl(),
        authRepository: sl(),
        usageRepository: sl(),
      ),
    );
    AppLogger.i('✅ Enhanced AI Chat repository registered');
  } else {
    // Fallback to basic repository without auth/usage tracking
    sl.registerLazySingleton<AIChatRepository>(
      () => AIChatRepositoryImpl(
        remoteDataSource: sl(),
        localDataSource: sl(),
        networkInfo: sl(),
      ),
    );
    AppLogger.w('⚠️ Using basic AI Chat repository (no auth/usage tracking)');
  }

  // Data sources
  sl.registerLazySingleton<AIChatRemoteDataSource>(
    () => AIChatRemoteDataSourceImpl(apiClient: sl()),
  );

  sl.registerLazySingleton<AIChatLocalDataSource>(
    () => AIChatLocalDataSourceImpl(sharedPreferences: sl()),
  );
}

// Initialize Usage Tracking Feature
void _initUsageTrackingFeature() {
  // Check if Firebase is available for remote tracking
  if (sl.isRegistered<firebase_auth.FirebaseAuth>()) {
    // Bloc
    sl.registerLazySingleton(() => UsageBloc(usageRepository: sl()));

    // Use cases
    sl.registerLazySingleton(() => CheckQuota(sl()));
    sl.registerLazySingleton(() => GetQuotaStatus(sl()));
    sl.registerLazySingleton(() => GetUserSubscription(sl()));
    sl.registerLazySingleton(() => GetUserUsageStats(sl()));
    sl.registerLazySingleton(() => LogMessageUsage(sl()));

    // Repository
    sl.registerLazySingleton<UsageRepository>(
      () => UsageRepositoryImpl(firestore: sl(), networkInfo: sl()),
    );

    // Data sources
    sl.registerLazySingleton<UsageRemoteDataSource>(
      () => UsageRemoteDataSourceImpl(firestore: sl()),
    );

    sl.registerLazySingleton<UsageLocalDataSource>(
      () => UsageLocalDataSourceImpl(
        sharedPreferences: sl(),
        secureStorage: sl(),
      ),
    );

    AppLogger.i('✅ Usage tracking feature initialized');
  } else {
    AppLogger.w('⚠️ Usage tracking feature skipped - Firebase not available');
  }
}

// Initialize Firebase
Future<void> _initFirebase() async {
  try {
    await Firebase.initializeApp();

    // Register Firebase services
    sl.registerLazySingleton(() => firebase_auth.FirebaseAuth.instance);
    sl.registerLazySingleton(() => FirebaseFirestore.instance);
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
    // Bloc
    sl.registerFactory(
      () => AuthBloc(
        signInWithGoogle: sl(),
        signInWithApple: sl(),
        signOut: sl(),
        getCurrentUser: sl(),
        linkGoogleAccount: sl(),
        linkAppleAccount: sl(),
        updateUserProfile: sl(),
        authRepository: sl(),
        usageRepository: sl(),
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
        firestore: sl(),
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
