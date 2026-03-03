import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/bibliotheque.dart';
import '../models/livre.dart';

class BibliothequeService {
  final String baseUrl = 'https://fancy-dog-formally.ngrok-free.app/bibliodb_api/';


  /// 🔹 Ajouter une bibliothèque
  Future<bool> ajouterBibliotheque(String token, String nom, int nbLignes, int nbColonnes) async {
    final response = await http.post(
      Uri.parse('${baseUrl}aj_bib.php'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'nom': nom,
        'nb_lignes': nbLignes,
        'nb_colonnes': nbColonnes,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['success'] == true || response.body.isNotEmpty;
    } else {
      return false;
    }
  }

  /// 🔹 Lister les bibliothèques de l'utilisateur — adapté à ton PHP
  Future<List<Bibliotheque>> listerBibliotheques(String token) async {
    try {
      final resp = await http.post(
        Uri.parse('${baseUrl}lister_bib.php'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token', // ⚠ espace après Bearer
        }, // 👈 aucun body
      );

      if (resp.statusCode != 200 || resp.body.isEmpty) return [];

      final Map<String, dynamic> decoded = jsonDecode(resp.body);

      // Format renvoyé par ton PHP:
      // { "status":"success", "bibliotheques":[ { biblio_id, nom, nb_lignes, nb_colonnes } ] }
      if (decoded['status'] == 'success' && decoded['bibliotheques'] is List) {
        final List<dynamic> list = decoded['bibliotheques'];
        return list.map((e) {
          final b = Bibliotheque.fromJson(e as Map<String, dynamic>);
          b.token = token; // si tu veux le garder dans le modèle
          return b;
        }).toList();
      }

      // Status = error (ex: token manquant/expiré) -> renvoie liste vide
      return [];
    } catch (e) {
      // Optionnel: log
      // print('listerBibliotheques error: $e');
      return[];
    }
  }

  /// 🔹 Supprimer une bibliothèque
  Future<bool> supprimerBibliotheque(String token, int biblioId) async {
    final response = await http.post(
      Uri.parse('${baseUrl}supprimer_bib.php'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'biblio_id': biblioId,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['success'] == true || response.body.isNotEmpty;
    } else {
      return false;
    }
  }

  /// 🔹 Voir tous les livres d’une bibliothèque
  Future<List<Livre>> voirBibliotheque(String token, int biblioId) async {
    final response = await http.post(
      Uri.parse('${baseUrl}voir_bib.php'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'biblio_id': biblioId,
      }),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) {
        final livre = Livre.fromJson(json);
        livre.token = token; // on garde le token dans l'objet
        return livre;
      }).toList();
    } else {
      return[];
    }
  }
}