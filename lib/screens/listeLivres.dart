import 'dart:io';
import 'package:flutter/material.dart';
import '../models/Bibliotheque.dart';
import '../models/Livre.dart';
import '../theme/app_theme.dart';
import '../database/database_helper.dart';

class ListeLivres extends StatefulWidget {
  final Bibliotheque library;
  final List<Livre> scannedBooks;

  const ListeLivres({
    super.key,
    required this.library,
    required this.scannedBooks,
  });

  @override
  State<ListeLivres> createState() => _ListeLivresState();
}

class _ListeLivresState extends State<ListeLivres> {
  List<Livre> livres = [];
  bool _selectionMode = false;
  Set<int> _selectedIndexes = {};
  bool _selectAll = false;

  @override
  void initState() {
    super.initState();
    _loadLivres();
  }

  ///    Charge les livres depuis la base
  Future<void> _loadLivres() async {
    final db = DatabaseHelper.instance;
    final all = await db.getLivresByBibliotheque(widget.library.biblioId ?? 1);
    setState(() => livres = all);
  }

  ///  Supprimer les livres sélectionnés
  Future<void> _deleteSelected() async {
    if (_selectedIndexes.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Supprimer la sélection ?"),
        content: Text(
          "Voulez-vous supprimer ${_selectedIndexes.length} livre(s) sélectionné(s) ?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            style: AppButtonStyles.elevated,
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Supprimer"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final db = DatabaseHelper.instance;
    for (final i in _selectedIndexes) {
      final livre = livres[i];
      if (livre.livreId != null) {
        await db.deleteLivre(livre.livreId!);
      }
    }

    setState(() {
      livres = [
        for (int i = 0; i < livres.length; i++)
          if (!_selectedIndexes.contains(i)) livres[i],
      ];
      _selectedIndexes.clear();
      _selectionMode = false;
      _selectAll = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("🗑️ Livres supprimés avec succès"),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  /// ️ Modifier un livre
  void _editLivre(Livre livre) {
    final titreCtrl = TextEditingController(text: livre.titre);
    final auteurCtrl = TextEditingController(text: livre.auteur ?? '');
    final ligneCtrl =
    TextEditingController(text: livre.positionLigne.toString());
    final colonneCtrl =
    TextEditingController(text: livre.positionColonne.toString());

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Modifier le livre"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titreCtrl,
              decoration: const InputDecoration(labelText: "Titre"),
            ),
            TextField(
              controller: auteurCtrl,
              decoration: const InputDecoration(labelText: "Auteur"),
            ),
            TextField(
              controller: ligneCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Étagère"),
            ),
            TextField(
              controller: colonneCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Colonne"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            style: AppButtonStyles.elevated,
            onPressed: () async {
              livre.titre = titreCtrl.text.trim();
              livre.auteur = auteurCtrl.text.trim();
              livre.positionLigne =
                  int.tryParse(ligneCtrl.text) ?? livre.positionLigne;
              livre.positionColonne =
                  int.tryParse(colonneCtrl.text) ?? livre.positionColonne;
              await DatabaseHelper.instance.updateLivre(livre);
              Navigator.pop(context);
              _loadLivres();

              //  Confirmation visuelle
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("✅ ${livre.titre} modifié avec succès"),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text("Enregistrer"),
          ),
        ],
      ),
    );
  }

  /// Sélectionner / désélectionner tous les livres
  void _toggleSelectAll() {
    setState(() {
      if (_selectAll) {
        _selectedIndexes.clear();
        _selectAll = false;
      } else {
        _selectedIndexes = Set<int>.from(List.generate(livres.length, (i) => i));
        _selectAll = true;
      }
    });
  }

  /// Voir les détails d’un livre
  void _showLivreDetails(Livre livre) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(livre.titre),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Auteur : ${livre.auteur ?? 'Inconnu'}"),
            Text("Étagère : ${livre.positionLigne + 1}"),
            Text("Colonne : ${livre.positionColonne + 1}"),
            if (livre.imagePath != null && File(livre.imagePath!).existsSync())
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Image.file(
                  File(livre.imagePath!),
                  height: 150,
                  fit: BoxFit.cover,
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Fermer"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          _selectionMode
              ? "${_selectedIndexes.length} sélectionné(s)"
              : widget.library.nom,
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          if (_selectionMode) ...[
            IconButton(
              icon: Icon(
                _selectAll ? Icons.deselect_outlined : Icons.select_all_outlined,
                color: Colors.white,
              ),
              onPressed: _toggleSelectAll,
              tooltip: _selectAll ? "Tout désélectionner" : "Tout sélectionner",
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.white),
              onPressed: _deleteSelected,
            ),
          ],
        ],
      ),
      body: livres.isEmpty
          ? const Center(
        child: Text(
          "Aucun livre enregistré",
          style: AppTextStyles.subtitle,
        ),
      )
          : ListView.builder(
        itemCount: livres.length,
        padding: const EdgeInsets.all(10),
        itemBuilder: (context, i) {
          final livre = livres[i];
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
                    if (_selectedIndexes.isEmpty) {
                      _selectionMode = false;
                      _selectAll = false;
                    }
                  } else {
                    _selectedIndexes.add(i);
                    _selectAll = _selectedIndexes.length == livres.length;
                  }
                });
              } else {
                _showLivreDetails(livre);
              }
            },
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withOpacity(0.15)
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : Colors.grey[300]!,
                  width: 1.5,
                ),
              ),
              child: ListTile(
                leading: const Icon(Icons.book, color: AppColors.primary),
                title: Text(livre.titre, style: AppTextStyles.title),
                subtitle: Text(
                  "${livre.auteur ?? "Auteur inconnu"} • "
                      "Étagère ${livre.positionLigne + 1}, "
                      "Colonne ${livre.positionColonne + 1}",
                  style: AppTextStyles.subtitle,
                ),
                trailing: !_selectionMode
                    ? PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'modifier') _editLivre(livre);
                    if (value == 'supprimer') {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text("Supprimer ce livre ?"),
                          content: Text(
                              "Voulez-vous supprimer '${livre.titre}' ?"),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.pop(context, false),
                              child: const Text("Annuler"),
                            ),
                            ElevatedButton(
                              style: AppButtonStyles.elevated,
                              onPressed: () =>
                                  Navigator.pop(context, true),
                              child: const Text("Supprimer"),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        await DatabaseHelper.instance
                            .deleteLivre(livre.livreId ?? 0);
                        setState(() => livres.removeAt(i));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                "🗑️ ${livre.titre} supprimé"),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      }
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                        value: 'modifier', child: Text("Modifier")),
                    PopupMenuItem(
                        value: 'supprimer', child: Text("Supprimer")),
                  ],
                )
                    : null,
              ),
            ),
          );
        },
      ),
    );
  }
}
