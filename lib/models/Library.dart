import 'Book.dart';

class Library {
  String name;
  int rows;
  int columns;
  List<Book> books;

  Library({
    required this.name,
    required this.rows,
    required this.columns,
    required this.books,
  });
}
