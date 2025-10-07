class Bibliotheque {
  final int? biblioId;          // ID unique (nullable car auto-généré côté backend)
  final int userId;             // ID utilisateur (lié à la session)
  final String nom;             // Nom de la bibliothèque
  final int nbLignes;           // Nombre d'étagères
  final int nbColonnes;         // Nombre de colonnes

  Bibliotheque({
    this.biblioId,
    required this.userId,
    required this.nom,
    required this.nbLignes,
    required this.nbColonnes,
  });

  // 🔁 Conversion depuis JSON
  factory Bibliotheque.fromJson(Map<String, dynamic> json) {
    return Bibliotheque(
      biblioId: json['biblio_id'] != null
          ? int.tryParse(json['biblio_id'].toString())
          : null,
      userId: int.tryParse(json['user_id'].toString()) ?? 0,
      nom: json['nom'] ?? '',
      nbLignes: int.tryParse(json['nb_lignes'].toString()) ?? 0,
      nbColonnes: int.tryParse(json['nb_colonnes'].toString()) ?? 0,
    );
  }

  // 🔁 Conversion vers JSON
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
    return 'Bibliotheque(biblioId: $biblioId, nom: $nom, lignes: $nbLignes, colonnes: $nbColonnes)';
  }
}
