import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Accueil', style: AppTextStyles.title),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textLight,
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: AppButtonStyles.elevated,
                  onPressed: () => Navigator.pushNamed(context, '/login'),
                  child: const Text('Connexion'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: AppButtonStyles.outlined,
                  onPressed: () => Navigator.pushNamed(context, '/register'),
                  child: const Text('Inscription'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
