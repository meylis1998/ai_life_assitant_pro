import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:workmanager/workmanager.dart';
import 'core/services/notification_service.dart';
import 'core/services/work_manager_handler.dart';

import 'core/router/app_router.dart';
import 'core/constants/app_theme.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/ai_chat/presentation/bloc/chat_bloc.dart';
import 'features/daily_briefing/presentation/bloc/briefing_bloc.dart';
import 'injection_container.dart' as di;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize Hive
  await Hive.initFlutter();

  // Note: Daily briefing uses JSON serialization with SharedPreferences, not Hive

  await di.init();

  await Workmanager().initialize(
    workManagerCallbackDispatcher,
    isInDebugMode: false,
  );

  final notificationService = di.sl<NotificationService>();
  await notificationService.initialize();

  if (di.sl.isRegistered<AuthBloc>()) {
    di.sl<AuthBloc>().add(const AuthCheckRequested());
  }

  runApp(const AILifeAssistantApp());
}

class AILifeAssistantApp extends StatelessWidget {
  const AILifeAssistantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
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
      },
    );
  }
}
