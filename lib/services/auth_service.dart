import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class AuthService {
  // ✅ 1️⃣ — Singleton
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // ✅ 2️⃣ — Variables internes
  final String baseUrl = 'https://fancy-dog-formally.ngrok-free.app/bibliodb_api/';
  bool _isAppOpen = true;
  User? _currentUser;

  // ✅ Getter pour accéder facilement à l’utilisateur courant
  User? get currentUser => _currentUser;

  /// 🔹 Inscription
  Future<bool> register(String firstname, String lastname, String username, String password) async {
    try {
      final url = Uri.parse('${baseUrl}register.php');
      final body = jsonEncode({
        'prenom': firstname,
        'nom': lastname,
        'username': username,
        'password': password,
      });

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['status'] == 'success';
      }
      return false;
    } catch (e) {
      print('❌ Erreur register: $e');
      return false;
    }
  }

  /// 🔹 Connexion
  Future<bool> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${baseUrl}auth.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode != 200) return false;

      final data = jsonDecode(response.body);
      if (data['status'] != 'success') return false;

      final token = data['token'];
      final userId = data['user_id'];

      // ✅ Crée et stocke le user courant
      _currentUser = User(
        userId: userId,
        username: username,
        password: password,
        token: token,
      );

      // ✅ Sauvegarde dans SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);
      await prefs.setInt('userId', userId);
      await prefs.setString('username', username);
      await prefs.setString('password', password);

      return true;
    } catch (e) {
      print('❌ Erreur login: $e');
      return false;
    }
  }

  /// 🔹 Déconnexion
  Future<void> logout(String? token) async {
    try {
      if (token != null && token.isNotEmpty) {
        final response = await http.post(
          Uri.parse('${baseUrl}logout.php'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );

        if (response.statusCode == 200) {
          print('✅ Déconnexion réussie côté serveur');
        } else {
          print('⚠ Erreur serveur lors du logout : ${response.statusCode} - ${response.body}');
        }
      } else {
        print('⚠ Aucun token fourni, logout local uniquement');
      }
    } catch (e) {
      print('❌ Erreur logout: $e');
    }
  }
}
