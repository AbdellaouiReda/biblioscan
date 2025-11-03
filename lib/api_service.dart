import 'dart:async'; // Nécessaire pour Future.delayed

class Book {
  final String isbn;
  final String title;
  final String author;
  final String? publicationDate;

  Book({
    required this.isbn,
    required this.title,
    required this.author,
    this.publicationDate,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      isbn: json['isbn'] ?? 'ISBN inconnu',
      title: json['title'] ?? 'Titre inconnu',
      author: json['author'] ?? 'Auteur inconnu',
      publicationDate: json['publication_date'],
    );
  }
}

class SearchResultItem {
  final Book book;
  final String bookshelfName;
  final String bookshelfLocation;
  final String shelfName;
  final String? columnName;

  SearchResultItem({
    required this.book,
    required this.bookshelfName,
    required this.bookshelfLocation,
    required this.shelfName,
    this.columnName,
  });
}

class ApiService {
  // La recherche globale est maintenant une simulation locale
  static Future<List<SearchResultItem>> searchBooksGlobally(
    String query,
  ) async {
    // SIMULATION D'UN APPEL RÉSEAU
    await Future.delayed(const Duration(seconds: 1));

    if (query.isEmpty) {
      return [];
    }

    final List<SearchResultItem> results = [];
    final lowerCaseQuery = query.toLowerCase();

    for (var bookshelfData in _mockHierarchicalData) {
      final String bookshelfName = bookshelfData['name'];
      final String bookshelfLocation = bookshelfData['location'];

      for (var shelfData in bookshelfData['shelves']) {
        final String shelfName = shelfData['name'];
        final String? columnName = shelfData['column'];

        for (var bookData in shelfData['books']) {
          final book = Book.fromJson(bookData);
          // Si le livre correspond à la recherche...
          if (book.title.toLowerCase().contains(lowerCaseQuery) ||
              book.author.toLowerCase().contains(lowerCaseQuery)) {
            // ... on crée un objet plat SearchResultItem et on l'ajoute aux résultats.
            results.add(
              SearchResultItem(
                book: book,
                bookshelfName: bookshelfName,
                bookshelfLocation: bookshelfLocation,
                shelfName: shelfName,
                columnName: columnName,
              ),
            );
          }
        }
      }
    }

    return results;
  }
}

// --- NOUVELLES DONNÉES DE TEST HIERARCHIQUES ---
final List<Map<String, dynamic>> _mockHierarchicalData = [
  {
    "id": 1,
    "name": "Bibliothèque du salon",
    "location": "Près de la fenêtre",
    "shelves": [
      {
        "id": 10,
        "name": "Étagère 2",
        "column": "Colonne A",
        "books": [
          {
            "isbn": "978-2266228692",
            "title": "L'Appel de l'ange",
            "author": "Guillaume Musso",
            "publication_date": "2011-03-31",
          },
        ],
      },
      {
        "id": 11,
        "name": "Étagère 4",
        "column": "Colonne B",
        "books": [
          {
            "isbn": "978-2253004222",
            "title": "Le Meilleur des mondes",
            "author": "Aldous Huxley",
            "publication_date": "1932-01-01",
          },
        ],
      },
    ],
  },
  {
    "id": 2,
    "name": "Étagère du bureau",
    "location": "Contre le mur",
    "shelves": [
      {
        "id": 20,
        "name": "Étagère 1",
        "column": "Colonne C",
        "books": [
          {
            "isbn": "978-2070360024",
            "title": "L'Étranger",
            "author": "Albert Camus",
            "publication_date": "1942-05-19",
          },
          {
            "isbn": "978-0451524935",
            "title": "1984",
            "author": "George Orwell",
            "publication_date": "1949-06-08",
          },
        ],
      },
    ],
  },
];
