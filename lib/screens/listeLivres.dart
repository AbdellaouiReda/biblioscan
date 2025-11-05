import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/livre.dart';
import '../models/bibliotheque.dart'; // ⚠ casse alignée avec AccesBib
import '../theme/app_theme.dart';

// Services réseau
import '../services/bib_services.dart';
import '../services/livre_services.dart';

class ListeLivres extends StatefulWidget {
  final Bibliotheque library; // ✅ non-nullable
  final List<Livre>? scannedBooks;

  const ListeLivres({super.key, required this.library, this.scannedBooks});

  @override
  State<ListeLivres> createState() => _ListeLivresState();
}

class _ListeLivresState extends State<ListeLivres> {
  late List<Livre> books;
  bool _selectionMode = false;
  final Set<int> _selectedIndexes = {};

  SharedPreferences? _prefs;
  String? _token;

  final _bibService = BibliothequeService();
  final _livreService = LivreService();

  @override
  void initState() {
    super.initState();
    books = [];
    _initAndLoad();
  }

  Future<void> _initAndLoad() async {
    _prefs = await SharedPreferences.getInstance();
    _token = _prefs!.getString('token');
    await _loadBooks();
  }

  Future<void> _loadBooks() async {
    final biblioId = widget.library.biblioId;
    if (_token == null || biblioId == null) {
      if (!mounted) return;
      setState(() => books = []);
      return;
    }

    // 1) Si des livres viennent du scan, on les ajoute côté API
    if (widget.scannedBooks != null && widget.scannedBooks!.isNotEmpty) {
      for (var livre in widget.scannedBooks!) {
        // s'assurer que le livre a bien le biblioId courant
        livre.biblioId = biblioId;
        await _livreService.ajouterLivre(_token!, livre);
      }
    }

    // 2) Charger depuis l’API tous les livres de la bibliothèque
    final apiBooks = await _bibService.voirBibliotheque(_token!, biblioId);

    if (!mounted) return;
    setState(() {
      books = apiBooks;
    });
  }

  /// 🧾 Détails d’un livre
  void _showBookDetails(Livre book) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(book.titre, style: AppTextStyles.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailLine("Auteur", book.auteur ?? "Inconnu"),
            _detailLine("Année", book.datePub?.year.toString() ?? "N/A"),
            _detailLine("Étagère", (book.positionLigne + 1).toString()),
            _detailLine("Colonne", (book.positionColonne + 1).toString()),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
                Navigator.pop(context);
                _editBook(book);
              } else if (value == 'delete') {
                Navigator.pop(context);
                _deleteBook(book);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('Modifier')),
              PopupMenuItem(value: 'delete', child: Text('Supprimer')),
            ],
            child: const Icon(Icons.more_vert, color: AppColors.primary),
          ),
          TextButton(
            child: const Text("Fermer"),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _detailLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text("$label : ",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  /// ✏ Modifier un livre
  void _editBook(Livre book) {
    final titleCtrl = TextEditingController(text: book.titre);
    final authorCtrl = TextEditingController(text: book.auteur ?? "");
    final yearCtrl = TextEditingController(text: book.datePub?.year.toString() ?? "");
    final shelfCtrl = TextEditingController(text: (book.positionLigne + 1).toString());
    final colCtrl = TextEditingController(text: (book.positionColonne + 1).toString());

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Modifier les informations"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: "Titre"),
              ),
              TextField(
                controller: authorCtrl,
                decoration: const InputDecoration(labelText: "Auteur"),
              ),
              TextField(
                controller: yearCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Année"),
              ),
              TextField(
                controller: shelfCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Étagère"),
              ),
              TextField(
                controller: colCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Colonne"),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Annuler")),
          ElevatedButton(
            onPressed: () async {
              if (_token == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("❌ Token manquant. Veuillez vous reconnecter.")),
                );
                return;
              }

              DateTime? newDate;
              final year = int.tryParse(yearCtrl.text.trim());
              if (year != null && year > 0) {
                newDate = DateTime(year);
              } else {
                newDate = null;
              }

              final updated = Livre(
                livreId: book.livreId,
                biblioId: book.biblioId,
                titre: titleCtrl.text.trim(),
                auteur: authorCtrl.text.trim().isEmpty ? null : authorCtrl.text.trim(),
                datePub: newDate,
                positionLigne: int.tryParse(shelfCtrl.text.trim()) != null
                    ? int.parse(shelfCtrl.text.trim()) - 1
                    : book.positionLigne,
                positionColonne: int.tryParse(colCtrl.text.trim()) != null
                    ? int.parse(colCtrl.text.trim()) - 1
                    : book.positionColonne,
              );

              final ok = await _livreService.modifierLivre(_token!, updated);
              if (ok) {
                if (!mounted) return;
                setState(() {
                  final i = books.indexOf(book);
                  if (i != -1) books[i] = updated;
                });
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("✅ Livre modifié")),
                  );
                }
              } else {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("❌ Échec de la modification.")),
                  );
                }
              }
            },
            child: const Text("Sauvegarder"),
          ),
        ],
      ),
    );
  }

  /// 🗑 Supprimer un seul livre
  Future<void> _deleteBook(Livre book) async {
    if (_token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Token manquant. Veuillez vous reconnecter.")),
      );
      return;
    }

    if (book.livreId != null) {
      await _livreService.supprimerLivre(_token!, book.livreId!);
    }
    if (!mounted) return;
    setState(() => books.remove(book));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("🗑 '${book.titre}' supprimé")),
    );
  }

  Future<void> _deleteSelectedBooks() async {
    if (_token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Token manquant. Veuillez vous reconnecter.")),
      );
      return;
    }

    final toDelete = _selectedIndexes.map((i) => books[i]).toList();

    for (var livre in toDelete) {
      if (livre.livreId != null) {
        await _livreService.supprimerLivre(_token!, livre.livreId!);
      }
    }

    if (!mounted) return;
    setState(() {
      books.removeWhere((livre) => toDelete.contains(livre));
      _selectedIndexes.clear();
      _selectionMode = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("🗑 Livres supprimés")),
    );
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selectedIndexes.length == books.length) {
        _selectedIndexes.clear();
        _selectionMode = false;
      } else {
        _selectedIndexes.clear();
        _selectedIndexes.addAll(List.generate(books.length, (index) => index));
        _selectionMode = true;
      }
    });
  }

  void _toggleSelection(int index) {
    setState(() {
      if (_selectedIndexes.contains(index)) {
        _selectedIndexes.remove(index);
      } else {
        _selectedIndexes.add(index);
      }
      _selectionMode = _selectedIndexes.isNotEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          title: Text(
            widget.library.nom,
            style: AppTextStyles.title.copyWith(color: AppColors.textLight),
          ),
          actions: [
            if (_selectionMode) ...[
              IconButton(
                icon: Icon(
                  _selectedIndexes.length == books.length
                      ? Icons.deselect
                      : Icons.select_all,
                  color: Colors.white,
                ),
                tooltip: _selectedIndexes.length == books.length
                    ? 'Tout désélectionner'
                    : 'Tout sélectionner',
                onPressed: _toggleSelectAll,
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.white),
                tooltip: 'Supprimer la sélection',
                onPressed: _deleteSelectedBooks,
              ),
            ]
          ],
        ),
        body: books.isEmpty
            ? const Center(child: Text("Aucun livre détecté"))
            : GridView.builder(
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.8,
            ),
            itemCount: books.length,
            itemBuilder: (context, i) {
              final book = books[i];
              final isSelected = _selectedIndexes.contains(i);

              return GestureDetector(
                onLongPress: () => _toggleSelection(i),
                onTap: () {
                  if (_selectionMode) {
                    _toggleSelection(i);
                  } else {
                    _showBookDetails(book);
                  }
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withOpacity(0.2)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : Colors.grey.shade300,
                      width: 1.5,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.menu_book,
                            color: AppColors.primary, size: 40),
                        const SizedBox(height: 8),
                        Text(
                          book.titre,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Text(
                          book.auteur ?? "Auteur inconnu",
                          style: const TextStyle(fontSize: 12),
                        ),
                        const Spacer(),
                        Text(
                          "📍 Ét. ${book.positionLigne + 1} • Col. ${book.positionColonne + 1}",
                          style: const TextStyle(
                              fontSize: 11, fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
            ),
        );
    }
}