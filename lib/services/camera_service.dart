import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

class UploadService {
  static const String baseUrl =
      'https://fancy-dog-formally.ngrok-free.app/bibliodb_api/';

  Future<(Map<String, dynamic>?, Map<String, dynamic>?)> sendImageAndDetect({
    required String imagePath,
    required int biblioId,
    required int positionLigne,
    required int positionColonne,
    required String bearerToken,
  }) async {
    try {
      final url = Uri.parse('${baseUrl}upload_image.php');
      print("🌍 Envoi de la requête vers : $url");

      final imageFile = File(imagePath);

      if (!await imageFile.exists()) {
        throw Exception('❌ Le fichier image n\'existe pas : $imagePath');
      }

      final request = http.MultipartRequest('POST', url);

      // 🧠 Headers
      request.headers.addAll({
        'Authorization': 'Bearer $bearerToken',
        'Accept': 'application/json',
      });

      // 📦 Fichier image
      final multipartFile = await http.MultipartFile.fromPath(
        'image', // 👈 vérifie que ton PHP attend bien ce nom
        imageFile.path,
        filename: imageFile.uri.pathSegments.last,
      );
      request.files.add(multipartFile);

      // 🔤 Champs supplémentaires
      request.fields.addAll({
        'biblio_id': biblioId.toString(),
        'position_ligne': positionLigne.toString(),
        'position_colonne': positionColonne.toString(),
      });

      print("📸 Champs envoyés : ${request.fields}");
      print("📦 Fichiers attachés : ${request.files.map((f) => f.filename)}");

      // 🚀 Envoi de la requête
      final streamedResponse = await request.send();

      print("📡 Statut HTTP : ${streamedResponse.statusCode}");

      final response = await http.Response.fromStream(streamedResponse);

      print("🧾 Réponse brute : ${response.body}");

      if (response.statusCode >= 200 && response.statusCode < 300) {
        Map<String, dynamic> jsonResponse = {};
        try {
          jsonResponse = json.decode(response.body);
        } catch (_) {
          print("⚠️ Impossible de décoder JSON, réponse texte : ${response.body}");
        }

        final uploadRes = {
          'success': true,
          'statusCode': response.statusCode,
        };

        return (uploadRes, jsonResponse);
      } else {
        print("❌ Erreur HTTP ${response.statusCode} : ${response.body}");
        return ({
          'success': false,
          'statusCode': response.statusCode,
          'error': response.body,
        }, null);
      }
    } catch (e) {
      print("💥 Exception pendant l’envoi : $e");

      return ({
        'success': false,
        'error': 'Exception: $e',
      }, null);
    }
  }
}
