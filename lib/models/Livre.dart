class Livre {
  final int? livreId; // ID unique du livre
  final int biblioId; // ID de la bibliothèque
  String titre;
  String? auteur;
  int? anneePublication;
  int positionLigne;
  int positionColonne;
  bool correctionManuelle;
  String? imagePath; // ✅ chemin de l’image capturée
  String? videoPath; // ✅ chemin de la vidéo enregistrée

  Livre({
    this.livreId,
    required this.biblioId,
    required this.titre,
    this.auteur,
    this.anneePublication,
    required this.positionLigne,
    required this.positionColonne,
    this.correctionManuelle = false,
    this.imagePath,
    this.videoPath,
  });

  // 🔁 Conversion depuis JSON / SQLite
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
      correctionManuelle:
      (json['correction_manuelle'] == 1 || json['correction_manuelle'] == true),
      imagePath: json['image_path'],
      videoPath: json['video_path'],
    );
  }

  // 🔄 Vers JSON / SQLite
  Map<String, dynamic> toJson() {
    return {
      if (livreId != null) 'livre_id': livreId,
      'biblio_id': biblioId,
      'titre': titre,
      'auteur': auteur,
      'annee_publication': anneePublication,
      'position_ligne': positionLigne,
      'position_colonne': positionColonne,
      'correction_manuelle': correctionManuelle ? 1 : 0,
      'image_path': imagePath,
      'video_path': videoPath,
    };
  }

  @override
  String toString() {
    return 'Livre(id: $livreId, titre: $titre, auteur: $auteur, étagère: $positionLigne, colonne: $positionColonne, image: $imagePath, video: $videoPath)';
  }
}
