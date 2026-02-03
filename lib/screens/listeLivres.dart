import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/livre.dart';
import '../models/bibliotheque.dart';
import '../theme/app_theme.dart';

import '../services/bib_services.dart';
import '../services/livre_services.dart';
import 'BookCoverWidget.dart';
import 'book_details_dialog.dart';

class ListeLivres extends StatefulWidget {
  final Bibliotheque library;
  final List<Livre>? scannedBooks;

  const ListeLivres({super.key, required this.library, this.scannedBooks});

  @override
  State<ListeLivres> createState() => _ListeLivresState();
}

class _ListeLivresState extends State<ListeLivres> {
  List<Livre> books = [];
  List<Livre> selectedBooks = [];

  bool selectionMode = false; // ✅ MODE SÉLECTION (GALERIE)

  SharedPreferences? _prefs;
  String? _token;

  final _bibService = BibliothequeService();
  final _livreService = LivreService();

  @override
  void initState() {
    super.initState();
    _initAndLoad();
  }

  Future<void> _initAndLoad() async {
    _prefs = await SharedPreferences.getInstance();
    _token = _prefs!.getString('token');
    await _loadBooks();
  }

  Future<void> _loadBooks() async {
    final biblioId = widget.library.biblioId;
    if (_token == null || biblioId == null) return;

    if (widget.scannedBooks != null) {
      for (var livre in widget.scannedBooks!) {
        livre.biblioId = biblioId;
        await _livreService.ajouterLivre(_token!, livre);
      }
    }

    final apiBooks = await _bibService.voirBibliotheque(_token!, biblioId);
    if (!mounted) return;

    setState(() {
      books = apiBooks;
      selectedBooks.clear();
      selectionMode = false;
    });
  }

  // ================= SUPPRESSION =================
  Future<void> _deleteSelectedBooks() async {
    if (_token == null) return;

    for (final livre in selectedBooks) {
      if (livre.livreId != null) {
        await _livreService.supprimerLivre(_token!, livre.livreId!);
      }
    }

    setState(() {
      selectedBooks.clear();
      selectionMode = false;
    });

    await _loadBooks();
  }

  @override
  Widget build(BuildContext context) {
    final shelves = <int, List<Livre>>{};
    for (final livre in books) {
      final key = livre.positionLigne ?? 1;
      shelves.putIfAbsent(key, () => []).add(livre);
    }

    final shelfKeys = shelves.keys.toList()..sort();

    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          widget.library.nom,
          style: AppTextStyles.title.copyWith(color: AppColors.textLight),
        ),
        actions: selectionMode
            ? [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.white),
            onPressed: _deleteSelectedBooks,
          ),
        ]
            : [],
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: _addLivre,
        child: const Icon(Icons.add, color: AppColors.textLight),
      ),

      body: books.isEmpty
          ? const Center(child: Text("Aucun livre détecté"))
          : ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 12),
        itemCount: shelfKeys.length,
        itemBuilder: (context, index) {
          final shelf = shelfKeys[index];
          final shelfBooks = shelves[shelf]!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 6),
                child: Text(
                  "Étagère $shelf",
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: shelfBooks.length,
                  itemBuilder: (context, i) {
                    final book = shelfBooks[i];

                    return _BookWidget(
                      book: book,
                      isSelected: selectedBooks.contains(book),

                      // ✅ APPUI LONG → MODE SÉLECTION
                      onLongPress: () {
                        setState(() {
                          selectionMode = true;
                          selectedBooks.add(book);
                        });
                      },

                      // ✅ TAP → SÉLECTION OU DÉTAILS
                      onTap: () {
                        if (selectionMode) {
                          setState(() {
                            if (selectedBooks.contains(book)) {
                              selectedBooks.remove(book);
                              if (selectedBooks.isEmpty) {
                                selectionMode = false;
                              }
                            } else {
                              selectedBooks.add(book);
                            }
                          });
                        } else {
                          _showBookDetails(book);
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showBookDetails(Livre book) {
    if (_token == null) return;

    showDialog(
      context: context,
      builder: (_) => BookDetailsDialog(
        livre: book,
        token: _token!,
        onBookUpdated: () async {
          await _loadBooks();
        },
      ),
    );
  }

  // ================= ADD BOOK =================
  void _addLivre() {
    String titre = "";
    String auteur = "";
    String datePub = "";
    int positionLigne = 1;
    int positionColonne = 1;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("Ajouter un livre"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                decoration: const InputDecoration(labelText: "Titre *"),
                onChanged: (v) => titre = v,
              ),
              TextField(
                decoration: const InputDecoration(labelText: "Auteur"),
                onChanged: (v) => auteur = v,
              ),
              TextField(
                decoration: const InputDecoration(labelText: "Année"),
                onChanged: (v) => datePub = v,
              ),
              TextField(
                decoration: const InputDecoration(labelText: "Étagère"),
                onChanged: (v) =>
                positionLigne = int.tryParse(v) ?? 1,
              ),
              TextField(
                decoration: const InputDecoration(labelText: "Colonne"),
                onChanged: (v) =>
                positionColonne = int.tryParse(v) ?? 1,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titre.isEmpty || _token == null) return;

              final livre = Livre(
                biblioId: widget.library.biblioId,
                titre: titre,
                auteur: auteur.isEmpty ? null : auteur,
                datePub: datePub.isEmpty ? null : datePub,
                positionLigne: positionLigne,
                positionColonne: positionColonne,
              );

              await _livreService.ajouterLivre(_token!, livre);
              if (!mounted) return;
              Navigator.pop(context);
              await _loadBooks();
            },
            child: const Text("Ajouter"),
          ),
        ],
      ),
    );
  }
}

// ================= BOOK WIDGET =================
class _BookWidget extends StatelessWidget {
  final Livre book;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final bool isSelected;

  const _BookWidget({
    required this.book,
    required this.onTap,
    required this.onLongPress,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        width: 30,
        margin: const EdgeInsets.only(right: 2),
        decoration: BoxDecoration(
          border: isSelected
              ? Border.all(color: Colors.teal, width: 2)
              : null,
        ),
        child: BookCoverWidget(livre: book),
      ),
    );
  }
}
