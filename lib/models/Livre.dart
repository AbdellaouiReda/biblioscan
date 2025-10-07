class Book {
  final int? id;
  final int libraryId;
  final String title;
  final String? author;
  final int? year;
  final int row;
  final int column;
  final String? imageUrl;
  final bool manualCorrection;
  final String? videoPath;
  final String? imagePath;

  Book({
    this.id,
    required this.libraryId,
    required this.title,
    this.author,
    this.year,
    required this.row,
    required this.column,
    this.imageUrl,
    this.manualCorrection = false,
    this.videoPath,
    this.imagePath,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['livre_id'] != null ? int.tryParse(json['livre_id'].toString()) : null,
      libraryId: int.tryParse(json['biblio_id'].toString()) ?? 0,
      title: json['titre'] ?? '',
      author: json['auteur'],
      year: json['annee_publication'] != null ? int.tryParse(json['annee_publication'].toString()) : null,
      row: int.tryParse(json['position_ligne'].toString()) ?? 0,
      column: int.tryParse(json['position_colonne'].toString()) ?? 0,
      imageUrl: json['couverture_url'],
      manualCorrection: (json['correction_manuelle'] == 1 || json['correction_manuelle'] == true),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'livre_id': id,
      'biblio_id': libraryId,
      'titre': title,
      'auteur': author,
      'annee_publication': year,
      'position_ligne': row,
      'position_colonne': column,
      'couverture_url': imageUrl,
      'correction_manuelle': manualCorrection,
      if (videoPath != null) 'video_path': videoPath,
      if (imagePath != null) 'image_path': imagePath,
    };
  }

  @override
  String toString() {
    return 'Book(id: $id, title: $title, author: $author, pos: ($row, $column))';
  }
}
