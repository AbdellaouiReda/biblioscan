import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:shared_preferences/shared_preferences.dart';

/// Service singleton pour gérer l'authentification biométrique
class BiometricService {
  // Singleton pattern
  static final BiometricService _instance = BiometricService._internal();
  factory BiometricService() => _instance;
  BiometricService._internal();

  final LocalAuthentication _localAuth = LocalAuthentication();

  // 🔹 Pour stocker le dernier message d'erreur
  String? lastError;

  // Clés pour SharedPreferences
  static const String _keyBiometricEnabled = 'biometric_enabled';
  static const String _keyStoredUsername = 'biometric_username';
  static const String _keyStoredPassword = 'biometric_password';
  static const String _keyBiometricPrompted =
      'biometric_prompted'; // Si on a déjà proposé

  /// Vérifie si l'appareil supporte la biométrie
  Future<bool> isBiometricAvailable() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      return canCheck || isDeviceSupported; // OR au lieu de AND
    } catch (e) {
      lastError = 'isBiometricAvailable error: $e';
      return false;
    }
  }

  /// Retourne les types de biométrie disponibles
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      lastError = 'getAvailableBiometrics error: $e';
      return [];
    }
  }

  /// Authentifie l'utilisateur avec la biométrie
  /// Retourne un Map avec 'success' et 'error' si échec
  Future<Map<String, dynamic>> authenticateWithDetails(
      {required String reason}) async {
    try {
      // Vérifier d'abord les biométries disponibles
      final biometrics = await getAvailableBiometrics();

      // 🔹 Debug: afficher les biométries disponibles
      if (biometrics.isEmpty) {
        return {
          'success': false,
          'error':
          'Aucune empreinte enregistrée sur cet appareil. Allez dans Paramètres > Sécurité pour en ajouter.',
        };
      }

      final result = await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
          useErrorDialogs: true,
          sensitiveTransaction: false,
        ),
      );

      return {
        'success': result,
        'error': result ? null : 'Authentification annulée'
      };
    } on PlatformException catch (e) {
      String errorMessage;
      switch (e.code) {
        case auth_error.notEnrolled:
          errorMessage =
          'Aucune empreinte enregistrée. Configurez-en une dans les paramètres de votre téléphone.';
          break;
        case auth_error.lockedOut:
          errorMessage = 'Trop de tentatives. Réessayez plus tard.';
          break;
        case auth_error.permanentlyLockedOut:
          errorMessage = 'Biométrie bloquée. Utilisez votre PIN/mot de passe.';
          break;
        case auth_error.notAvailable:
          errorMessage = 'Biométrie non disponible sur cet appareil.';
          break;
        default:
          errorMessage = 'Erreur: ${e.message}';
      }
      lastError = errorMessage;
      return {'success': false, 'error': errorMessage};
    } catch (e) {
      lastError = 'Erreur inattendue: $e';
      return {'success': false, 'error': lastError};
    }
  }

  /// Authentifie l'utilisateur (version simple)
  Future<bool> authenticate({required String reason}) async {
    final result = await authenticateWithDetails(reason: reason);
    return result['success'] as bool;
  }

  /// Vérifie si la biométrie est activée par l'utilisateur
  Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyBiometricEnabled) ?? false;
  }

  /// Active ou désactive la biométrie
  Future<void> setBiometricEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyBiometricEnabled, enabled);
  }

  /// Stocke le nom d'utilisateur et mot de passe pour la connexion biométrique
  Future<void> storeCredentialsForBiometric(
      String username, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyStoredUsername, username);
    await prefs.setString(_keyStoredPassword, password);
  }

  /// Récupère le nom d'utilisateur stocké
  Future<String?> getStoredUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyStoredUsername);
  }

  /// Récupère le mot de passe stocké
  Future<String?> getStoredPassword() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyStoredPassword);
  }

  /// Vérifie si des credentials sont stockés
  Future<bool> hasStoredCredentials() async {
    final username = await getStoredUsername();
    final password = await getStoredPassword();
    return username != null &&
        username.isNotEmpty &&
        password != null &&
        password.isNotEmpty;
  }

  /// Vérifie si on a déjà proposé la biométrie à l'utilisateur
  Future<bool> hasPromptedBiometric() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyBiometricPrompted) ?? false;
  }

  /// Marque que l'on a proposé la biométrie
  Future<void> setPromptedBiometric(bool prompted) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyBiometricPrompted, prompted);
  }

  /// Efface les credentials biométriques stockés
  Future<void> clearStoredCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyStoredUsername);
    await prefs.remove(_keyStoredPassword);
    await prefs.remove(_keyBiometricEnabled);
    await prefs.remove(_keyBiometricPrompted);
  }
}