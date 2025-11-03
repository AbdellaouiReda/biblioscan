import 'Livre.dart';

class Bibliotheque {
  final int? biblioId;
  final int userId;
  final String nom;
  final int nbLignes;
  final int nbColonnes;
  List<Livre> books; // ✅ Liste de livres liée à la bibliothèque

  Bibliotheque({
    this.biblioId,
    required this.userId,
    required this.nom,
    required this.nbLignes,
    required this.nbColonnes,
    this.books = const [],
  });

  factory Bibliotheque.fromJson(Map<String, dynamic> json) {
    return Bibliotheque(
      biblioId: json['biblio_id'] != null
          ? int.tryParse(json['biblio_id'].toString())
          : null,
      userId: int.tryParse(json['user_id'].toString()) ?? 0,
      nom: json['nom'] ?? '',
      nbLignes: int.tryParse(json['nb_lignes'].toString()) ?? 0,
      nbColonnes: int.tryParse(json['nb_colonnes'].toString()) ?? 0,
      books: [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (biblioId != null) 'biblio_id': biblioId,
      'user_id': userId,
      'nom': nom,
      'nb_lignes': nbLignes,
      'nb_colonnes': nbColonnes,
    };
  }

  @override
  String toString() {
    return 'Bibliotheque(biblioId: $biblioId, nom: $nom, lignes: $nbLignes, colonnes: $nbColonnes, livres: ${books.length})';
  }
}
