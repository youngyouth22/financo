import 'package:financo/common/app_themes.dart';
import 'package:financo/core/router/app_router.dart';
import 'package:financo/di/injection_container.dart';
import 'package:financo/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:financo/features/auth/presentation/bloc/auth_event.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables from .env file
  await dotenv.load(fileName: ".env");
  
  // Initialize dependencies (Supabase, Google Sign-In, etc.)
  await initializeDependencies();
  
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      // Provide AuthBloc at the root level for global access
      create: (context) => sl<AuthBloc>()..add(const AuthCheckRequested()),
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        title: 'Financo',
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark,
        theme: ThemeData.dark(useMaterial3: true),
        routerConfig: AppRouter.createRouter(),
      ),
    );
  }
}
