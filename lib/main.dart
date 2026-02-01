import 'dart:io';

import 'package:financo/common/app_themes.dart';
import 'package:financo/core/router/app_router.dart';
import 'package:financo/core/widgets/no_internet_banner.dart';
import 'package:financo/di/injection_container.dart';
import 'package:financo/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:financo/features/auth/presentation/bloc/auth_event.dart';
import 'package:financo/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Load environment variables from .env file
  await dotenv.load(fileName: ".env");

  // Initialize dependencies (Supabase, Google Sign-In, etc.)
  await initializeDependencies();
  await initializeRevenueCat();

  runApp(const MainApp());
}

Future<void> initializeRevenueCat() async {
  // Platform-specific API keys
  String apiKey;
  if (Platform.isIOS) {
    apiKey = dotenv.env['REVENUE_CAT']!;
  } else if (Platform.isAndroid) {
    apiKey = dotenv.env['REVENUE_CAT']!;
  } else {
    throw UnsupportedError('Platform not supported');
  }

  await Purchases.configure(PurchasesConfiguration(apiKey));
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      // Provide AuthBloc at the root level for global access
      create: (context) => sl<AuthBloc>()..add(const AuthCheckRequested()),
      child: NoInternetBanner(
        child: MaterialApp.router(
          debugShowCheckedModeBanner: false,
          title: 'Financo',
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.dark,
          theme: ThemeData.dark(useMaterial3: true),
          routerConfig: AppRouter.createRouter(),
        ),
      ),
    );
  }
}
