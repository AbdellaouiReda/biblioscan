import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '../theme/app_theme.dart';
import '../services/biometric_service.dart';
import '../services/auth_service.dart';

/// Page de paramètres pour gérer l'authentification biométrique
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final BiometricService _biometricService = BiometricService();
  final AuthService _authService = AuthService();

  bool _isBiometricAvailable = false;
  bool _isBiometricEnabled = false;
  List<BiometricType> _availableBiometrics = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final isAvailable = await _biometricService.isBiometricAvailable();
    final isEnabled = await _biometricService.isBiometricEnabled();
    final biometrics = await _biometricService.getAvailableBiometrics();

    if (mounted) {
      setState(() {
        _isBiometricAvailable = isAvailable;
        _isBiometricEnabled = isEnabled;
        _availableBiometrics = biometrics;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    if (value) {
      // 🔹 Demander le mot de passe pour activer la biométrie
      final password = await _showPasswordDialog();
      if (password == null || password.isEmpty) return;

      // Activer la biométrie - vérifier d'abord l'authentification
      final authResult = await _biometricService.authenticateWithDetails(
        reason: 'Confirmez votre identité pour activer l\'empreinte digitale',
      );

      if (authResult['success'] == true) {
        final user = await _authService.getCurrentUser();
        if (user != null) {
          await _biometricService.setBiometricEnabled(true);
          await _biometricService.storeCredentialsForBiometric(
              user.username, password);
          await _biometricService.setPromptedBiometric(true);
          setState(() => _isBiometricEnabled = true);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Authentification biométrique activée ✅'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } else {
        // 🔹 L'authentification biométrique a échoué - afficher l'erreur détaillée
        if (mounted) {
          final errorMsg = authResult['error'] ?? 'Erreur inconnue';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ $errorMsg'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } else {
      // Désactiver la biométrie
      await _biometricService.clearStoredCredentials();
      setState(() => _isBiometricEnabled = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Authentification biométrique désactivée'),
          ),
        );
      }
    }
  }

  /// 🔹 Dialog pour demander le mot de passe
  Future<String?> _showPasswordDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmation'),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Entrez votre mot de passe',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  String _getBiometricTypeName(BiometricType type) {
    switch (type) {
      case BiometricType.fingerprint:
        return 'Empreinte digitale';
      case BiometricType.face:
        return 'Reconnaissance faciale';
      case BiometricType.iris:
        return 'Scan de l\'iris';
      case BiometricType.strong:
        return 'Biométrie forte';
      case BiometricType.weak:
        return 'Biométrie faible';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Paramètres', style: AppTextStyles.title),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textLight,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Section Sécurité
                const Text(
                  'Sécurité',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 12),

                // Carte biométrie
                Card(
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.fingerprint,
                              color: _isBiometricAvailable
                                  ? AppColors.primary
                                  : Colors.grey,
                              size: 32,
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Authentification biométrique',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (_isBiometricAvailable) ...[
                          // Types disponibles
                          if (_availableBiometrics.isNotEmpty) ...[
                            Text(
                              'Types disponibles: ${_availableBiometrics.map(_getBiometricTypeName).join(", ")}',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textGrey,
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],

                          // Switch pour activer/désactiver
                          SwitchListTile(
                            title: const Text('Activer l\'empreinte digitale'),
                            subtitle: const Text(
                              'Connexion rapide avec votre empreinte',
                            ),
                            value: _isBiometricEnabled,
                            activeColor: AppColors.primary,
                            onChanged: _toggleBiometric,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ] else ...[
                          // Message si biométrie non disponible
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.orange.shade200),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.warning_amber,
                                    color: Colors.orange, size: 24),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'L\'authentification biométrique n\'est pas disponible sur cet appareil.',
                                    style: TextStyle(fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Section À propos
                const Text(
                  'À propos',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 12),

                Card(
                  elevation: 2,
                  child: ListTile(
                    leading: const Icon(Icons.info_outline,
                        color: AppColors.primary),
                    title: const Text('BiblioScan'),
                    subtitle: const Text('Version 1.0.0'),
                  ),
                ),
              ],
            ),
    );
  }
}
