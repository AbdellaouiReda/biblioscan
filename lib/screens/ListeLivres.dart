import 'package:flutter/material.dart';
import '../models/Book.dart';
import '../models/Library.dart';
import '../styles.dart';

class ListeLivres extends StatefulWidget {
  final Library? library;
  final List<Book>? scannedBooks;

  const ListeLivres({super.key, this.library, this.scannedBooks});

  @override
  State<ListeLivres> createState() => _ListeLivresState();
}

class _ListeLivresState extends State<ListeLivres> {
  late List<Book> books;
  bool _selectionMode = false;
  final Set<int> _selectedIndexes = {};
  bool _isSearching = false;
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    books = widget.scannedBooks ?? widget.library?.books ?? [];
  }

  // ➕ Ajouter un livre
  void _addBook() {
    String title = "";
    String author = "";

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text("➕ Ajouter un livre", style: AppTextStyles.title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: "Titre"),
                onChanged: (val) => title = val,
              ),
              const SizedBox(height: 10),
              TextField(
                decoration: const InputDecoration(labelText: "Auteur"),
                onChanged: (val) => author = val,
              ),
            ],
          ),
          actions: [
            TextButton(
              style: AppButtonStyles.text,
              onPressed: () => Navigator.pop(context),
              child: const Text("Annuler"),
            ),
            ElevatedButton(
              style: AppButtonStyles.elevated,
              onPressed: () {
                setState(() {
                  books.add(Book(
                    title: title.isNotEmpty ? title : "Nom du Livre",
                    author: author.isNotEmpty ? author : "Auteur inconnu",
                  ));
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("📚 Livre ajouté : ${title.isNotEmpty ? title : "Nom du Livre"}")),
                );
              },
              child: const Text("Ajouter"),
            ),
          ],
        );
      },
    );
  }

  // ✏️ Modifier un livre
  void _editBook(int index) {
    String title = books[index].title;
    String author = books[index].author ?? "";

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text("✏️ Modifier le livre", style: AppTextStyles.title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: TextEditingController(text: title),
                decoration: const InputDecoration(labelText: "Titre"),
                onChanged: (val) => title = val,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: TextEditingController(text: author),
                decoration: const InputDecoration(labelText: "Auteur"),
                onChanged: (val) => author = val,
              ),
            ],
          ),
          actions: [
            TextButton(
              style: AppButtonStyles.text,
              onPressed: () => Navigator.pop(context),
              child: const Text("Annuler"),
            ),
            ElevatedButton(
              style: AppButtonStyles.elevated,
              onPressed: () {
                setState(() {
                  books[index] = Book(
                    title: title.isNotEmpty ? title : "Nom du Livre",
                    author: author.isNotEmpty ? author : "Auteur inconnu",
                  );
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("✅ Livre modifié")),
                );
              },
              child: const Text("Sauvegarder"),
            ),
          ],
        );
      },
    );
  }

  // 🗑️ Supprimer
  void _deleteSelectedBooks() {
    setState(() {
      final toDelete = _selectedIndexes.toList()..sort((a, b) => b.compareTo(a));
      for (var index in toDelete) {
        books.removeAt(index);
      }
      _selectedIndexes.clear();
      _selectionMode = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("🗑️ Livres supprimés")),
    );
  }

  // 🔍 Filtrer
  List<Book> get _filteredBooks {
    if (_searchQuery.isEmpty) return books;
    return books
        .where((b) =>
    b.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        (b.author ?? "").toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredBooks = _filteredBooks;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _selectionMode
              ? "${_selectedIndexes.length} sélectionné(s)"
              : "Mes Livres",
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        actions: [
          if (_selectionMode)
            IconButton(icon: const Icon(Icons.delete), onPressed: _deleteSelectedBooks)
          else
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () => setState(() => _isSearching = !_isSearching),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (_isSearching)
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: "Rechercher un livre...",
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ),

            // 📚 Affichage GridView moderne
            Expanded(
              child: filteredBooks.isEmpty
                  ? const Center(
                child: Text(
                  "Aucun livre ajouté",
                  style: AppTextStyles.subtitle,
                ),
              )
                  : GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.9,
                ),
                itemCount: filteredBooks.length,
                itemBuilder: (context, i) {
                  final book = filteredBooks[i];
                  final isSelected = _selectedIndexes.contains(i);

                  return GestureDetector(
                    onLongPress: () {
                      setState(() {
                        _selectionMode = true;
                        _selectedIndexes.add(i);
                      });
                    },
                    onTap: () {
                      if (_selectionMode) {
                        setState(() {
                          if (isSelected) {
                            _selectedIndexes.remove(i);
                            if (_selectedIndexes.isEmpty) _selectionMode = false;
                          } else {
                            _selectedIndexes.add(i);
                          }
                        });
                      } else {
                        _editBook(i);
                      }
                    },
                    child: Container(
                      decoration: isSelected
                          ? AppCardStyles.selected
                          : AppCardStyles.base,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.book, color: AppColors.primary, size: 40),
                          const SizedBox(height: 8),
                          Text(
                            book.title.isNotEmpty ? book.title : "Nom du Livre",
                            textAlign: TextAlign.center,
                            style: AppTextStyles.title.copyWith(fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            book.author ?? "Auteur inconnu",
                            style: AppTextStyles.subtitle.copyWith(fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Étagère ${(i ~/ 5) + 1} • Colonne ${(i % 5) + 1}",
                            style: AppTextStyles.subtitle.copyWith(
                              fontStyle: FontStyle.italic,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: !_selectionMode
          ? FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: _addBook,
        child: const Icon(Icons.add, color: Colors.white),
      )
          : null,
    );
  }
}
