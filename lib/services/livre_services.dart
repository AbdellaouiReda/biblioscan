import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/livre.dart';

class LivreService {
  final String baseUrl = 'https://fancy-dog-formally.ngrok-free.app/bibliodb_api/';

  /// 🔹 Ajouter un livre à une bibliothèque
  Future<bool> ajouterLivre(String token, Livre livre) async {
    final response = await http.post(
      Uri.parse('${baseUrl}aj_livre.php'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'biblio_id': livre.biblioId,
        'titre': livre.titre,
        'auteur': livre.auteur,
        'date_pub': livre.datePub,
        'position_ligne': livre.positionLigne,
        'position_colonne': livre.positionColonne,
      }),
    );

    if (response.statusCode == 200) {
      final body = response.body.isNotEmpty ? jsonDecode(response.body) : null;
      if (body is Map && body['success'] == true) return true;
      return true;
    } else {
      return false;
    }
  }

  /// 🔹 Chercher un livre (par titre, auteur ou date)
  Future<List<Livre>> chercherLivre({
    required String token,
    String? titre,
    String? auteur,
    DateTime? datePub,
  }) async {
    if (titre == null && auteur == null && datePub == null) {
      throw Exception('Veuillez fournir au moins un critère de recherche.');
    }

    final body = {
      if (titre != null) 'titre': titre,
      if (auteur != null) 'auteur': auteur,
      if (datePub != null) 'date_pub': datePub.toIso8601String(),
    };

    final response = await http.post(
      Uri.parse('${baseUrl}chercher_livre.php'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data is List) {
        return data.map((json) {
          final livre = Livre.fromJson(json);
          livre.token = token;
          return livre;
        }).toList();
      } else if (data is Map<String, dynamic>) {
        final livre = Livre.fromJson(data);
        livre.token = token;
        return [livre];
      }
    }

    return [];
  }

  /// 🔹 Modifier un livre existant
  Future<bool> modifierLivre(String token, Livre livre) async {
    final response = await http.post(
      Uri.parse('${baseUrl}modifier_livre.php'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'livre_id': livre.livreId,
        'titre': livre.titre,
        'auteur': livre.auteur,
        'date_pub': livre.datePub,
        'position_ligne': livre.positionLigne,
        'position_colonne': livre.positionColonne,
      }),
    );

    if (response.statusCode == 200) {
      final body = response.body.isNotEmpty ? jsonDecode(response.body) : null;
      if (body is Map && body['success'] == true) return true;
      return true;
    } else {
      return false;
    }
  }

  /// 🔹 Supprimer un livre
  Future<bool> supprimerLivre(String token, int livreId) async {
    final response = await http.post(
      Uri.parse('${baseUrl}supprimer_livre.php'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'livre_id': livreId,
      }),
    );

    if (response.statusCode == 200) {
      final body = response.body.isNotEmpty ? jsonDecode(response.body) : null;
      if (body is Map && body['success'] == true) return true;
      return true;
    } else {
      return false;
    }
  }
}