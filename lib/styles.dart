import 'package:flutter/material.dart';

/// 🎨 Palette centrale de l'application
class AppColors {
  // Couleurs principales
  static const primary = Colors.teal; // couleur d’accent globale
  static const secondary = Colors.orangeAccent;

  // Couleurs d'arrière-plan
  static const background = Color(0xFFF5F5F5);
  static const surface = Colors.white;

  // Couleurs du texte
  static const textDark = Colors.black87;
  static const textLight = Colors.white;
  static const textGrey = Colors.grey;

  // États
  static const error = Colors.redAccent;
  static const success = Colors.green;
  static const warning = Colors.amber;
}

/// ✍️ Styles typographiques cohérents
class AppTextStyles {
  static const title = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: AppColors.textDark,
  );

  static const subtitle = TextStyle(
    fontSize: 16,
    color: AppColors.textGrey,
  );

  static const body = TextStyle(
    fontSize: 15,
    color: AppColors.textDark,
  );

  static const button = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textLight,
    letterSpacing: 0.5,
  );

  static const caption = TextStyle(
    fontSize: 13,
    color: AppColors.textGrey,
  );
}

/// 🔘 Styles des boutons
class AppButtonStyles {
  static final elevated = ElevatedButton.styleFrom(
    backgroundColor: AppColors.primary,
    foregroundColor: AppColors.textLight,
    textStyle: AppTextStyles.button,
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    elevation: 2,
  );

  static final outlined = OutlinedButton.styleFrom(
    foregroundColor: AppColors.primary,
    side: const BorderSide(color: AppColors.primary, width: 2),
    textStyle: AppTextStyles.button.copyWith(color: AppColors.primary),
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  );

  static final text = TextButton.styleFrom(
    foregroundColor: AppColors.primary,
    textStyle: AppTextStyles.button.copyWith(
      fontSize: 16,
      color: AppColors.primary,
    ),
  );
}

/// 🧱 Styles de cartes / conteneurs
class AppCardStyles {
  static final base = BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: Colors.black12,
        blurRadius: 4,
        offset: const Offset(0, 2),
      ),
    ],
  );

  static final selected = BoxDecoration(
    color: AppColors.primary.withOpacity(0.15),
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: AppColors.primary.withOpacity(0.2),
        blurRadius: 4,
        offset: const Offset(0, 2),
      ),
    ],
  );
}
