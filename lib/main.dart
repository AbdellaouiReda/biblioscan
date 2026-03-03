import 'package:flutter/material.dart';
import 'theme/app_theme.dart';

import 'screens/home_page.dart';
import 'screens/register_page.dart';
import 'screens/login_page.dart';
import 'screens/accesBib.dart';
import 'screens/camera.dart';
import 'screens/book_search_screen.dart'; // 🔹 Ajouté
import 'screens/listeLivres.dart';       // 🔹 Ajouté
import 'models/bibliotheque.dart';      // 🔹 Pour le cast de l'objet Bibliotheque

// Tes fichiers
import 'features/onboarding/tuto_wrapper.dart';

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

      initialRoute: '/',

      onGenerateRoute: (settings) {
        Widget page;

        switch (settings.name) {
          case '/':
          case '/home':
            page = const TutoWrapper(
              tutoKey: 'home',
              title: "Accueil BiblioScan",
              description: "Bienvenue ! Connectez-vous pour commencer à scanner vos livres.",
              child: HomePage(),
            );
            break;

          case '/accesbib':
            page = const TutoWrapper(
              tutoKey: 'biblio',
              title: "Vos Bibliothèques",
              description: "Ici vous pouvez voir vos étagères. Appui long pour supprimer, clic pour ouvrir.",
              child: AccesBib(),
            );
            break;

          case '/camera':
            final args = settings.arguments as Map<String, dynamic>?;
            page = TutoWrapper(
              tutoKey: 'camera',
              title: "Le Scanner",
              description: "Cadrez bien la tranche du livre. Pensez à sélectionner l'étagère avant de scanner.",
              child: Camera(
                rows: args?['rows'] ?? 1,
                columns: args?['columns'] ?? 1,
                libraryName: args?['libraryName'],
                biblioId: args?['biblioId'],
              ),
            );
            break;

          case '/search':
            page = const TutoWrapper(
              tutoKey: 'search',
              title: "Recherche Globale",
              description: "Retrouvez n'importe quel livre en tapant son titre ou son auteur, peu importe sa bibliothèque.",
              child: BookSearchScreen(),
            );
            break;

          case '/listeLivres':
          // On récupère l'objet bibliothèque passé en argument
            final biblio = settings.arguments as Bibliotheque;
            page = TutoWrapper(
              tutoKey: 'liste',
              title: "Gestion des Livres",
              description: "Ici, vous pouvez voir les détails de vos livres, les modifier ou les supprimer de l'étagère.",
              child: ListeLivres(library: biblio),
            );
            break;

          case '/login': page = const LoginPage(); break;
          case '/register': page = const RegisterPage(); break;

          default:
            page = const HomePage();
        }

        return MaterialPageRoute(builder: (context) => page, settings: settings);
      },
    );
  }
}