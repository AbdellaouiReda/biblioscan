class Livre {
  int? livreId;
  int? biblioId;
  String titre;
  String? bibNom;
  String? auteur;
  String? datePub;
  int? positionLigne;
  int? positionColonne;
  String? couvertureUrl;
  String? token;

  Livre({
    this.livreId,
    this.biblioId,
    required this.titre,
    this.bibNom,
    this.auteur,
    this.datePub,
    this.positionLigne,
    this.positionColonne,
    this.couvertureUrl,
    this.token,
  });

  factory Livre.fromJson(Map<String, dynamic> json) {
    return Livre(
      livreId: json['livre_id'],
      biblioId: json['biblio_id'], // 🔥 Peut être null maintenant
      titre: json['titre'] ?? 'Sans titre', // 🔥 Valeur par défaut
      bibNom: json['nom_biblio'],
      auteur: json['auteur'],
      datePub: json['date_pub'],
      positionLigne: json['position_ligne'], // 🔥 Peut être null
      positionColonne: json['position_colonne'], // 🔥 Peut être null
      couvertureUrl: json['couverture_url'],
      token: json['token'],
    );
  }

  Map<String, dynamic> toJson() => {
    'livre_id': livreId,
    'biblio_id': biblioId,
    'titre': titre,
    'nom_biblio':bibNom,
    'auteur': auteur,
    'date_pub': datePub,
    'position_ligne': positionLigne,
    'position_colonne': positionColonne,
    'couverture_url': couvertureUrl,
    'token': token,
  };
}