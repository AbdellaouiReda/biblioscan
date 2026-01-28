import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/livre.dart';
import '../models/bibliotheque.dart';
import '../theme/app_theme.dart';

import '../services/bib_services.dart';
import '../services/livre_services.dart';

class ListeLivres extends StatefulWidget {
  final Bibliotheque library;
  final List<Livre>? scannedBooks;

  const ListeLivres({super.key, required this.library, this.scannedBooks});

  @override
  State<ListeLivres> createState() => _ListeLivresState();
}

class _ListeLivresState extends State<ListeLivres> {
  List<Livre> books = [];

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
    setState(() => books = apiBooks);
  }

  // ================= UI =================

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
      ),

      /// ✅ BOUTON AJOUT — TOUJOURS ACTIF
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
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: shelfBooks.length,
                  itemBuilder: (context, i) {
                    return _BookWidget(
                      book: shelfBooks[i],
                      onTap: () => _showBookDetails(shelfBooks[i]),
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

  // ================= BOOK DETAILS =================

  void _showBookDetails(Livre book) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(book.titre, style: AppTextStyles.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailLine("Auteur", book.auteur ?? "Inconnu"),
            _detailLine("Année", book.datePub ?? "N/A"),
            _detailLine("Étagère", book.positionLigne.toString()),
            _detailLine("Colonne", book.positionColonne.toString()),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _editBook(book);
            },
            child: const Text("Modifier"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteBook(book);
            },
            child: const Text("Supprimer"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Fermer"),
          ),
        ],
      ),
    );
  }

  Widget _detailLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text("$label : $value"),
    );
  }

  // ================= CRUD =================

  Future<void> _deleteBook(Livre book) async {
    if (_token == null || book.livreId == null) return;
    await _livreService.supprimerLivre(_token!, book.livreId!);
    await _loadBooks();
  }

  void _editBook(Livre book) {
    final titleCtrl = TextEditingController(text: book.titre);
    final authorCtrl = TextEditingController(text: book.auteur ?? "");
    final yearCtrl = TextEditingController(text: book.datePub ?? "");
    final shelfCtrl =
    TextEditingController(text: book.positionLigne.toString());
    final colCtrl =
    TextEditingController(text: book.positionColonne.toString());

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Modifier le livre"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: "Titre")),
              TextField(controller: authorCtrl, decoration: const InputDecoration(labelText: "Auteur")),
              TextField(controller: yearCtrl, decoration: const InputDecoration(labelText: "Année")),
              TextField(controller: shelfCtrl, decoration: const InputDecoration(labelText: "Étagère")),
              TextField(controller: colCtrl, decoration: const InputDecoration(labelText: "Colonne")),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
          ElevatedButton(
            onPressed: () async {
              final updated = Livre(
                livreId: book.livreId,
                biblioId: book.biblioId,
                titre: titleCtrl.text.trim(),
                auteur: authorCtrl.text.trim(),
                datePub: yearCtrl.text.trim(),
                positionLigne: int.tryParse(shelfCtrl.text) ?? book.positionLigne,
                positionColonne: int.tryParse(colCtrl.text) ?? book.positionColonne,
              );
              await _livreService.modifierLivre(_token!, updated);
              if (!mounted) return;
              Navigator.pop(context);
              await _loadBooks();
            },
            child: const Text("Sauvegarder"),
          ),
        ],
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
              TextField(decoration: const InputDecoration(labelText: "Titre *"), onChanged: (v) => titre = v),
              TextField(decoration: const InputDecoration(labelText: "Auteur"), onChanged: (v) => auteur = v),
              TextField(decoration: const InputDecoration(labelText: "Année"), onChanged: (v) => datePub = v),
              TextField(decoration: const InputDecoration(labelText: "Étagère"), onChanged: (v) => positionLigne = int.tryParse(v) ?? 1),
              TextField(decoration: const InputDecoration(labelText: "Colonne"), onChanged: (v) => positionColonne = int.tryParse(v) ?? 1),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
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

  const _BookWidget({required this.book, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: book.couvertureUrl != null
              ? Image.network(
            book.couvertureUrl!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
            const Icon(Icons.menu_book, size: 50),
          )
              : const Icon(Icons.menu_book, size: 50),
        ),
      ),
    );
  }
}
