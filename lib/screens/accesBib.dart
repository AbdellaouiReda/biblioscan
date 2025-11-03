import 'package:flutter/material.dart';
import '../models/Bibliotheque.dart';
import '../theme/app_theme.dart';
import 'listeLivres.dart';
import 'camera.dart';
import 'book_search_screen.dart'; // ✅ Intégration de la nouvelle interface

class AccesBib extends StatefulWidget {
  const AccesBib({super.key});

  @override
  State<AccesBib> createState() => _AccesBibState();
}

class _AccesBibState extends State<AccesBib> {
  List<Bibliotheque> bibliotheques = [];
  bool _selectionMode = false;
  Set<int> _selectedIndexes = {};
  bool _isSearching = false;
  String _searchQuery = "";

  // 🔧 Ajouter une bibliothèque
  void _addLibrary() {
    String name = "";
    int rows = 1;
    int columns = 1;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.background,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text("Nouvelle bibliothèque", style: AppTextStyles.title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: "Nom"),
                onChanged: (val) => name = val,
              ),
              const SizedBox(height: 8),
              TextField(
                decoration: const InputDecoration(labelText: "Nombre d'étagères"),
                keyboardType: TextInputType.number,
                onChanged: (val) => rows = int.tryParse(val) ?? 1,
              ),
              const SizedBox(height: 8),
              TextField(
                decoration: const InputDecoration(labelText: "Nombre de colonnes"),
                keyboardType: TextInputType.number,
                onChanged: (val) => columns = int.tryParse(val) ?? 1,
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
                if (name.isNotEmpty) {
                  setState(() {
                    bibliotheques.add(
                      Bibliotheque(
                        userId: 1,
                        nom: name,
                        nbLignes: rows,
                        nbColonnes: columns,
                      ),
                    );
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("✅ Bibliothèque ajoutée : $name")),
                  );
                }
              },
              child: const Text("Créer"),
            ),
          ],
        );
      },
    );
  }

  // 📖 Ouvrir une bibliothèque
  void _openLibrary(Bibliotheque biblio) {
    if (_selectionMode) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.list, color: AppColors.primary),
                  title: const Text("Voir / Modifier les livres", style: AppTextStyles.subtitle),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ListeLivres(
                          library: biblio,
                          scannedBooks: const [],
                        ),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: AppColors.primary),
                  title: const Text("Scanner avec la caméra", style: AppTextStyles.subtitle),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => Camera(
                          rows: biblio.nbLignes,
                          columns: biblio.nbColonnes,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 🗑️ Suppression multiple
  void _deleteSelected() {
    setState(() {
      bibliotheques = [
        for (int i = 0; i < bibliotheques.length; i++)
          if (!_selectedIndexes.contains(i)) bibliotheques[i]
      ];
      _selectedIndexes.clear();
      _selectionMode = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("🗑️ Bibliothèque(s) supprimée(s)")),
    );
  }

  // 🚪 Déconnexion
  void _logout() {
    Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("👋 Déconnecté avec succès")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredLibraries = bibliotheques
        .where((b) => b.nom.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _selectionMode
              ? "${_selectedIndexes.length} sélectionné(s)"
              : "BiblioScan",
          style: const TextStyle(color: AppColors.textDark),
        ),
        backgroundColor: AppColors.primary,
        actions: [
          if (_selectionMode)
            IconButton(
              icon: const Icon(Icons.delete, color: AppColors.textLight),
              onPressed: _deleteSelected,
            )
          else ...[
            IconButton(
              icon: const Icon(Icons.search, color: AppColors.textLight),
              onPressed: () => setState(() => _isSearching = !_isSearching),
            ),
            // ✅ Nouvelle recherche intégrée
            IconButton(
              icon: const Icon(Icons.person_search, color: AppColors.textLight),
              tooltip: "Rechercher un livre en ligne",
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const BookSearchScreen(),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.logout, color: AppColors.textLight),
              tooltip: "Déconnexion",
              onPressed: _logout,
            ),
          ],
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
                    hintText: "Rechercher une bibliothèque...",
                    prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                    filled: true,
                    fillColor: AppColors.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ),
            Expanded(
              child: filteredLibraries.isEmpty
                  ? const Center(
                child: Text(
                  "Aucune bibliothèque trouvée",
                  style: AppTextStyles.subtitle,
                ),
              )
                  : GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.1,
                ),
                itemCount: filteredLibraries.length,
                itemBuilder: (context, i) {
                  final biblio = filteredLibraries[i];
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
                        _openLibrary(biblio);
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
                          const Icon(Icons.library_books,
                              color: AppColors.primary, size: 40),
                          const SizedBox(height: 8),
                          Text(
                            biblio.nom,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.title.copyWith(fontSize: 18),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${biblio.nbLignes} étagères • ${biblio.nbColonnes} colonnes",
                            style: AppTextStyles.subtitle,
                            textAlign: TextAlign.center,
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
        onPressed: _addLibrary,
        child: const Icon(Icons.add, color: AppColors.textLight),
      )
          : null,
    );
  }
}
