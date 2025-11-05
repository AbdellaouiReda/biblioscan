class Bibliotheque {
  int? biblioId;
  int? userId;
  String nom;
  int nbLignes;
  int nbColonnes;
  String? token;

  Bibliotheque({
    this.biblioId,
    required this.userId,
    required this.nom,
    required this.nbLignes,
    required this.nbColonnes,
    this.token,
  });

  factory Bibliotheque.fromJson(Map<String, dynamic> json) {
    return Bibliotheque(
      biblioId: json['biblio_id'],
      userId: json['user_id'],
      nom: json['nom'],
      nbLignes: json['nb_lignes'],
      nbColonnes: json['nb_colonnes'],
      token: json['token'],
    );
  }

  Map<String, dynamic> toJson() => {
    'biblio_id': biblioId,
    'user_id': userId,
    'nom': nom,
    'nb_lignes': nbLignes,
    'nb_colonnes': nbColonnes,
    'token': token,
  };
}