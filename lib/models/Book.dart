class Book {
  String title;
  String? author;     // facultatif → pour ajout manuel
  String? videoPath;  // facultatif → pour scan vidéo
  String? imagePath;  // facultatif → pour scan photo

  Book({
    required String title,
    String? author,
    this.videoPath,
    this.imagePath,
  })  : title = title.isNotEmpty ? title : "Nom du livre",   // ✅ valeur par défaut
        author = (author != null && author.isNotEmpty) ? author : "Auteur inconnu"; // ✅ valeur par défaut
}
