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

  /// 🔹 Récupère l'utilisateur connecté (depuis mémoire ou stockage)
  Future<User?> getCurrentUser() async {
    if (_currentUser != null) return _currentUser;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final userId = prefs.getInt('userId');
    final username = prefs.getString('username');
    final password = prefs.getString('password');

    if (token == null || userId == null) return null;

    _currentUser = User(
      userId: userId,
      username: username ?? '',
      password: password ?? '',
      token: token,
    );

    return _currentUser;
  }

  /// 🔹 App quittée → compte à rebours de 10 min
  Future<void> appQuit() async {
    _isAppOpen = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      'tokenExpiry',
      DateTime.now().add(const Duration(minutes: 10)).millisecondsSinceEpoch,
    );
  }

  /// 🔹 App ouverte
  void appOpen() {
    _isAppOpen = true;
  }

  /// 🔹 Récupère le token stocké
  Future<String?> getToken() async {
    if (_currentUser != null) return _currentUser!.token;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  /// 🔹 Récupère le userId stocké
  Future<int?> getUserId() async {
    if (_currentUser != null) return _currentUser!.userId;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('userId');
  }
}
