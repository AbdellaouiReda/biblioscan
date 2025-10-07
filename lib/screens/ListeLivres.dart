import 'package:flutter/material.dart';
import '../models/Livre.dart';
import '../models/Bibliotheque.dart';
import '../styles.dart';

class ListeLivres extends StatefulWidget {
  final Bibliotheque? library;
  final List<Livre>? scannedBooks;

  const ListeLivres({super.key, this.library, this.scannedBooks});

  @override
  State<ListeLivres> createState() => _ListeLivresState();
}

class _ListeLivresState extends State<ListeLivres> {
  late List<Livre> books;
  bool _selectionMode = false;
  final Set<int> _selectedIndexes = {};
  bool _isSearching = false;
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    books = widget.scannedBooks ?? [];
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
                if (title.isEmpty) title = "Nom du Livre";
                if (author.isEmpty) author = "Auteur inconnu";

                setState(() {
                  books.add(Livre(
                    biblioId: widget.library?.biblioId ?? 1,
                    titre: title,
                    auteur: author,
                    positionLigne: (books.length ~/ 5),
                    positionColonne: (books.length % 5),
                  ));
                });

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("📚 Livre ajouté : $title")),
                );
              },
              child: const Text("Ajouter"),
            ),
          ],
        );
      },
    );
  }

  // ✏️ Modifier la position du livre
  void _editBook(int index) {
    int positionLigne = books[index].positionLigne;
    int positionColonne = books[index].positionColonne;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text(" Modifier la position", style: AppTextStyles.title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: TextEditingController(text: (positionLigne + 1).toString()),
                decoration: const InputDecoration(
                  labelText: "Numéro d’étagère",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (val) =>
                positionLigne = (int.tryParse(val) ?? 1) - 1,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: TextEditingController(text: (positionColonne + 1).toString()),
                decoration: const InputDecoration(
                  labelText: "Numéro de colonne",
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (val) =>
                positionColonne = (int.tryParse(val) ?? 1) - 1,
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
                  books[index] = Livre(
                    livreId: books[index].livreId,
                    biblioId: widget.library?.biblioId ?? 1,
                    titre: books[index].titre,
                    auteur: books[index].auteur,
                    positionLigne: positionLigne,
                    positionColonne: positionColonne,
                  );
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("✅ Position mise à jour")),
                );
              },
              child: const Text("Sauvegarder"),
            ),
          ],
        );
      },
    );
  }

  // 🗑️ Supprimer des livres
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

  // 🔍 Filtrage par titre/auteur
  List<Livre> get _filteredBooks {
    if (_searchQuery.isEmpty) return books;
    return books
        .where((b) =>
    b.titre.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        (b.auteur ?? "").toLowerCase().contains(_searchQuery.toLowerCase()))
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

            // 📚 Grille des livres
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
                          const Icon(Icons.book,
                              color: AppColors.primary, size: 40),
                          const SizedBox(height: 8),
                          Text(
                            book.titre,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.title
                                .copyWith(fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            book.auteur ?? "Auteur inconnu",
                            style: AppTextStyles.subtitle
                                .copyWith(fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Étagère ${book.positionLigne + 1} • Colonne ${book.positionColonne + 1}",
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
