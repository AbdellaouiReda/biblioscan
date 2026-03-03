import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'accesBib.dart';
import '../services/auth_service.dart';
import '../services/biometric_service.dart'; // 🔹 Import du service biométrique

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _user = TextEditingController();
  final _pwd = TextEditingController();
  bool _obscure = true;
  bool _isLoading = false;
  bool _isBiometricAvailable = false; // 🔹 Si l'appareil supporte la biométrie
  bool _hasBiometricCredentials =
  false; // 🔹 Si des credentials biométriques existent

  // ✅ Services
  final AuthService _authService = AuthService();
  final BiometricService _biometricService = BiometricService();

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
    _tryBiometricLogin();
  }

  /// 🔹 Vérifie si la biométrie est disponible et configurée
  Future<void> _checkBiometricAvailability() async {
    final isAvailable = await _biometricService.isBiometricAvailable();
    final hasCredentials = await _biometricService.hasStoredCredentials();
    final isEnabled = await _biometricService.isBiometricEnabled();
    if (mounted) {
      setState(() {
        _isBiometricAvailable = isAvailable;
        _hasBiometricCredentials = hasCredentials && isEnabled;
      });
    }
  }

  /// 🔹 Tente la connexion biométrique automatique si activée
  Future<void> _tryBiometricLogin() async {
    final isEnabled = await _biometricService.isBiometricEnabled();
    final hasCredentials = await _biometricService.hasStoredCredentials();

    if (isEnabled && hasCredentials) {
      final authenticated = await _biometricService.authenticate(
        reason: 'Authentifiez-vous pour accéder à BiblioScan',
      );

      if (authenticated && mounted) {
        // 🔹 Connexion avec les credentials stockés
        final username = await _biometricService.getStoredUsername();
        final password = await _biometricService.getStoredPassword();

        if (username != null && password != null) {
          final success = await _authService.login(username, password);
          if (success && mounted) {
            Navigator.pushReplacementNamed(context, '/accesbib');
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _user.dispose();
    _pwd.dispose();
    super.dispose();
  }

  /// 🔹 Tentative de connexion avec AuthService
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final username = _user.text.trim();
    final password = _pwd.text.trim();
    final success = await _authService.login(username, password);

    setState(() => _isLoading = false);

    if (success) {
      if (!mounted) return;

      // 🔹 Vérifier si on doit proposer la biométrie (première fois)
      final hasPrompted = await _biometricService.hasPromptedBiometric();
      final isEnabled = await _biometricService.isBiometricEnabled();

      if (_isBiometricAvailable && !hasPrompted && !isEnabled) {
        // 🔹 Afficher le dialog pour proposer la biométrie
        await _showBiometricPromptDialog(username, password);
      } else {
        _navigateToHome();
      }
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Échec de la connexion ❌')),
      );
    }
  }

  /// 🔹 Affiche le dialog pour proposer l'authentification biométrique
  Future<void> _showBiometricPromptDialog(
      String username, String password) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.fingerprint, color: AppColors.primary, size: 32),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Empreinte digitale',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: const Text(
          'Voulez-vous associer vos identifiants à votre empreinte digitale ?\n\nVous pourrez vous connecter plus rapidement lors de vos prochaines visites.',
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Non merci'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.fingerprint),
            label: const Text('Activer'),
          ),
        ],
      ),
    );

    // 🔹 Marquer qu'on a proposé la biométrie
    await _biometricService.setPromptedBiometric(true);

    if (result == true) {
      // 🔹 L'utilisateur veut activer → demander l'empreinte pour confirmer
      final authResult = await _biometricService.authenticateWithDetails(
        reason: 'Confirmez votre empreinte pour l\'associer à vos identifiants',
      );

      if (authResult['success'] == true) {
        await _biometricService.setBiometricEnabled(true);
        await _biometricService.storeCredentialsForBiometric(
            username, password);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Empreinte digitale activée !'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // 🔹 L'authentification a échoué - afficher le message d'erreur
        if (mounted) {
          final errorMsg = authResult['error'] ?? 'Erreur inconnue';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ $errorMsg'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    }

    _navigateToHome();
  }

  /// 🔹 Navigation vers la page d'accueil
  void _navigateToHome() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const AccesBib()),
    );
  }

  /// 🔹 Connexion rapide avec empreinte digitale
  Future<void> _loginWithBiometric() async {
    final username = await _biometricService.getStoredUsername();
    final password = await _biometricService.getStoredPassword();

    if (username == null || password == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Connectez-vous d\'abord normalement pour activer l\'empreinte.'),
        ),
      );
      return;
    }

    final authenticated = await _biometricService.authenticate(
      reason: 'Authentifiez-vous pour accéder à BiblioScan',
    );

    if (authenticated) {
      setState(() => _isLoading = true);

      // 🔹 Connexion avec les credentials stockés
      final success = await _authService.login(username, password);

      setState(() => _isLoading = false);

      if (success && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AccesBib()),
        );
      } else {
        if (!mounted) return;
        // 🔹 Si échec, les credentials ont peut-être changé
        await _biometricService.clearStoredCredentials();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
            Text('Identifiants invalides. Reconnectez-vous manuellement.'),
          ),
        );
        // Rafraîchir l'UI pour cacher le bouton empreinte
        _checkBiometricAvailability();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Connexion', style: AppTextStyles.title),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textLight,
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _user,
                    decoration: const InputDecoration(
                      labelText: 'Nom d’utilisateur',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Nom d’utilisateur requis'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _pwd,
                    obscureText: _obscure,
                    decoration: InputDecoration(
                      labelText: 'Mot de passe',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure ? Icons.visibility : Icons.visibility_off,
                          color: AppColors.primary,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    validator: (v) =>
                    (v == null || v.isEmpty) ? 'Mot de passe requis' : null,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: AppButtonStyles.elevated,
                      onPressed: _isLoading ? null : _login,
                      child: _isLoading
                          ? const CircularProgressIndicator(
                        color: Colors.white,
                      )
                          : const Text('Se connecter'),
                    ),
                  ),
                  // 🔹 Bouton connexion rapide avec empreinte (seulement si configuré)
                  if (_hasBiometricCredentials)
                    Column(
                      children: [
                        const SizedBox(height: 16),
                        const Text(
                          'ou',
                          style: TextStyle(color: AppColors.textGrey),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            style: AppButtonStyles.outlined,
                            onPressed: _isLoading ? null : _loginWithBiometric,
                            icon: const Icon(Icons.fingerprint, size: 28),
                            label: const Text('Connexion avec empreinte'),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}