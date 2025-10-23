import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:workmanager/workmanager.dart';
import 'core/services/notification_service.dart';
import 'core/services/work_manager_handler.dart';

import 'config/router/app_router.dart';
import 'core/constants/app_theme.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/ai_chat/presentation/bloc/chat_bloc.dart';
import 'features/daily_briefing/presentation/bloc/briefing_bloc.dart';
import 'injection_container.dart' as di;
import 'features/daily_briefing/data/models/daily_briefing_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize Hive
  await Hive.initFlutter();

  // Register Hive type adapters for Daily Briefing
  Hive.registerAdapter(DailyBriefingModelAdapter());
  Hive.registerAdapter(AIInsightsModelAdapter());

  // Initialize dependency injection (includes Firebase initialization)
  await di.init();

  // Initialize WorkManager for background tasks
  await Workmanager().initialize(
    workManagerCallbackDispatcher,
    isInDebugMode: false,
  );

  // Initialize notifications
  final notificationService = di.sl<NotificationService>();
  await notificationService.initialize();

  // Check auth status on app start (only if auth is available)
  if (di.sl.isRegistered<AuthBloc>()) {
    di.sl<AuthBloc>().add(const AuthCheckRequested());
  }

  runApp(const AILifeAssistantApp());
}

class AILifeAssistantApp extends StatelessWidget {
  const AILifeAssistantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        if (di.sl.isRegistered<AuthBloc>())
          BlocProvider<AuthBloc>(create: (context) => di.sl<AuthBloc>()),
        BlocProvider<ChatBloc>(create: (context) => di.sl<ChatBloc>()),
        BlocProvider<BriefingBloc>(create: (context) => di.sl<BriefingBloc>()),
      ],
      child: MaterialApp.router(
        title: 'AI Life Assistant Pro',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        routerConfig: AppRouter.router,
      ),
    );
  }
}
