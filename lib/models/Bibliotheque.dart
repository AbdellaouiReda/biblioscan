class Library {
  final int? id;
  final int userId;
  final String name;
  final int rows;
  final int columns;

  Library({
    this.id,
    required this.userId,
    required this.name,
    required this.rows,
    required this.columns,
  });

  factory Library.fromJson(Map<String, dynamic> json) {
    return Library(
      id: json['biblio_id'] != null ? int.tryParse(json['biblio_id'].toString()) : null,
      userId: int.tryParse(json['user_id'].toString()) ?? 0,
      name: json['nom'] ?? '',
      rows: int.tryParse(json['nb_lignes'].toString()) ?? 0,
      columns: int.tryParse(json['nb_colonnes'].toString()) ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'biblio_id': id,
      'user_id': userId,
      'nom': name,
      'nb_lignes': rows,
      'nb_colonnes': columns,
    };
  }

  @override
  String toString() {
    return 'Library(id: $id, name: $name, rows: $rows, columns: $columns)';
  }
}
