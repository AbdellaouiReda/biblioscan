import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/livre.dart';

class LivreService {
  final String baseUrl = 'https://fancy-dog-formally.ngrok-free.app/bibliodb_api/';
  final Duration _timeout = const Duration(seconds: 20);

  // Utilitaire: ajoute un champ seulement s'il est non nul et non vide
  void _putIfNotEmpty(Map<String, dynamic> map, String key, String? value) {
    if (value != null) {
      final v = value.trim();
      if (v.isNotEmpty) map[key] = v;
    }
  }

  /// 🔹 Ajouter un livre à une bibliothèque
  Future<bool> ajouterLivre(String token, Livre livre) async {
    try {
      final body = <String, dynamic>{
        'biblio_id': livre.biblioId,                // int?
        'position_ligne': livre.positionLigne,      // int?
        'position_colonne': livre.positionColonne,  // int?
      };

      _putIfNotEmpty(body, 'titre', livre.titre);
      _putIfNotEmpty(body, 'auteur', livre.auteur);
      _putIfNotEmpty(body, 'date_pub', livre.datePub);
      _putIfNotEmpty(body, 'couverture_url', livre.couvertureUrl);

      final response = await http
          .post(
        Uri.parse('${baseUrl}aj_livre.php'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        if (response.body.isEmpty) return true; // certains scripts ne renvoient rien
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['success'] == true) return true;
        // si le backend renvoie juste un objet créé / liste, on considère succès
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// 🔹 Chercher un livre (par titre, auteur ou date)
  /// NOTE: datePub est une String (ex: "2019")
  Future<List<Livre>> chercherLivre({
    required String token,
    String? titre,
    String? auteur,
    String? datePub,
  }) async {
    try {
      // Vérification minimale
      if ((titre == null || titre.isEmpty) &&
          (auteur == null || auteur.isEmpty) &&
          (datePub == null || datePub.isEmpty)) {
        throw Exception('Veuillez fournir au moins un critère de recherche.');
      }

      // Envoi direct, sans body structuré
      final response = await http.post(
        Uri.parse('${baseUrl}chercher_livre.php'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'titre': titre,
          'auteur': auteur,
          'date_pub': datePub,
        }),
      );

      if (response.statusCode != 200 || response.body.isEmpty) {
        return <Livre>[];
      }

      final decoded = jsonDecode(response.body);

      // ✅ Structure attendue : {"status":"success","livres":[ ... ]}
      if (decoded is Map<String, dynamic> &&
          decoded['status'] == 'success' &&
          decoded['livres'] is List) {
        final List<dynamic> livresJson = decoded['livres'];
        return livresJson.map<Livre>((json) {
          final livre = Livre.fromJson(json as Map<String, dynamic>);
          livre.token = token;
          return livre;
        }).toList();
      }

      // Aucune donnée trouvée
      return <Livre>[];
    } catch (e) {
      print('❌ Erreur chercherLivre: $e');
      return <Livre>[];
    }
  }

  /// 🔹 Modifier un livre existant
  Future<bool> modifierLivre(String token, Livre livre) async {
    try {
      final body = <String, dynamic>{
        'livre_id': livre.livreId,                  // requis par le backend
        'position_ligne': livre.positionLigne,
        'position_colonne': livre.positionColonne,
      };

      _putIfNotEmpty(body, 'titre', livre.titre);
      _putIfNotEmpty(body, 'auteur', livre.auteur);
      _putIfNotEmpty(body, 'date_pub', livre.datePub);
      _putIfNotEmpty(body, 'couverture_url', livre.couvertureUrl);

      final response = await http
          .post(
        Uri.parse('${baseUrl}modifier_livre.php'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        if (response.body.isEmpty) return true;
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['success'] == true) return true;
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// 🔹 Supprimer un livre
  Future<bool> supprimerLivre(String token, int livreId) async {
    try {
      final response = await http
          .post(
        Uri.parse('${baseUrl}supprimer_livre.php'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'livre_id': livreId}),
      )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        if (response.body.isEmpty) return true;
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['success'] == true) return true;
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}