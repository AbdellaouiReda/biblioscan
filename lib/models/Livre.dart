class Livre {
  final int? livreId;           // ID unique du livre
  final int biblioId;           // ID de la bibliothèque
  final String titre;           // Titre du livre
  final String? auteur;         // Auteur du livre
  final int? anneePublication;  // Année de publication
  final int positionLigne;      // Ligne (étagère)
  final int positionColonne;    // Colonne
  final String? couvertureUrl;  // URL de la couverture
  final bool correctionManuelle; // Livre modifié manuellement ?

  // ✅ Champs locaux facultatifs (non persistés mais utiles dans l’app)
  final String? imagePath;      // Photo locale (scan image)
  final String? videoPath;      // Vidéo locale (scan vidéo)

  Livre({
    this.livreId,
    required this.biblioId,
    required this.titre,
    this.auteur,
    this.anneePublication,
    required this.positionLigne,
    required this.positionColonne,
    this.couvertureUrl,
    this.correctionManuelle = false,
    this.imagePath,
    this.videoPath,
  });

  // 🔁 Conversion depuis JSON
  factory Livre.fromJson(Map<String, dynamic> json) {
    return Livre(
      livreId: json['livre_id'] != null
          ? int.tryParse(json['livre_id'].toString())
          : null,
      biblioId: int.tryParse(json['biblio_id'].toString()) ?? 0,
      titre: json['titre'] ?? '',
      auteur: json['auteur'],
      anneePublication: json['annee_publication'] != null
          ? int.tryParse(json['annee_publication'].toString())
          : null,
      positionLigne: int.tryParse(json['position_ligne'].toString()) ?? 0,
      positionColonne: int.tryParse(json['position_colonne'].toString()) ?? 0,
      couvertureUrl: json['couverture_url'],
      correctionManuelle: (json['correction_manuelle'] == 1 ||
          json['correction_manuelle'] == true),
    );
  }

  // 🔁 Conversion vers JSON
  Map<String, dynamic> toJson() {
    return {
      if (livreId != null) 'livre_id': livreId,
      'biblio_id': biblioId,
      'titre': titre,
      'auteur': auteur,
      'annee_publication': anneePublication,
      'position_ligne': positionLigne,
      'position_colonne': positionColonne,
      'couverture_url': couvertureUrl,
      'correction_manuelle': correctionManuelle,
    };
  }

  @override
  String toString() {
    return 'Livre(livreId: $livreId, titre: $titre, auteur: $auteur, position: ($positionLigne, $positionColonne))';
  }
}
