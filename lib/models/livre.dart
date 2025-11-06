class Livre {
  int? livreId;
  int biblioId;
  String titre;
  String? auteur;
  String? datePub;
  int positionLigne;
  int positionColonne;
  String? couvertureUrl;
  bool correctionManuelle;
  String? token;

  Livre({
    this.livreId,
    required this.biblioId,
    required this.titre,
    this.auteur,
    this.datePub,
    required this.positionLigne,
    required this.positionColonne,
    this.couvertureUrl,
    this.correctionManuelle = false,
    this.token,
  });

  factory Livre.fromJson(Map<String, dynamic> json) {
    return Livre(
      livreId: json['livre_id'],
      biblioId: json['biblio_id'],
      titre: json['titre'],
      auteur: json['auteur'],
      datePub:json['date_pub'],
      positionLigne: json['position_ligne'],
      positionColonne: json['position_colonne'],
      couvertureUrl: json['couverture_url'],
      correctionManuelle: json['correction_manuelle'] == 1,
      token: json['token'],
    );
  }

  Map<String, dynamic> toJson() => {
    'livre_id': livreId,
    'biblio_id': biblioId,
    'titre': titre,
    'auteur': auteur,
    'date_pub': datePub,
    'position_ligne': positionLigne,
    'position_colonne': positionColonne,
    'couverture_url': couvertureUrl,
    'correction_manuelle': correctionManuelle ? 1 : 0,
    'token': token,
  };
}
