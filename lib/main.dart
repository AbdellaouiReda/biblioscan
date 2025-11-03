import 'package:flutter/material.dart';
import 'theme/app_theme.dart';

import 'screens/home_page.dart';
import 'screens/login_page.dart';
import 'screens/register_page.dart';
import 'screens/accesBib.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BiblioScanApp());
}

class BiblioScanApp extends StatelessWidget {
  const BiblioScanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BiblioScan',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        scaffoldBackgroundColor: AppColors.background,
        textTheme: const TextTheme(
          titleLarge: AppTextStyles.title,
          bodyMedium: AppTextStyles.subtitle,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textLight,
          elevation: 0,
          centerTitle: true,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textLight,
        ),
      ),

      home: const HomePage(),

      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/home': (context) => const HomePage(),
        '/accesbib': (context) => const AccesBib(),

      },
    );
  }
}
