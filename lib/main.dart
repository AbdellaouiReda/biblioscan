import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'biblio_scan',
      theme: AppTheme.light,        // <-- thème global
      initialRoute: '/',            // <-- routes simples et claires
      routes: {
        '/':        (_) => const HomePage(),
        '/login':   (_) => const LoginPage(),
        '/register':(_) => const RegisterPage(),
      },
    );
  }
}
