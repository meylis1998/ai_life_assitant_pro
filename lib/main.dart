import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'config/router/app_router.dart';
import 'core/constants/app_theme.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/ai_chat/presentation/bloc/chat_bloc.dart';
import 'injection_container.dart' as di;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Initialize dependency injection (includes Firebase initialization)
  await di.init();

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
          BlocProvider<AuthBloc>(
            create: (context) => di.sl<AuthBloc>(),
          ),
        BlocProvider<ChatBloc>(
          create: (context) => di.sl<ChatBloc>(),
        ),
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

