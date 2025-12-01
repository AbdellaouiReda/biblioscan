import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// === imports modèles/services ===
import '../models/livre.dart';
import '../services/livre_services.dart';

// Si tu utilises AppCardStyles/AppTextStyles, garde tes imports de thème ici
import '../theme/app_theme.dart';

// Import du dialogue de détails
import 'book_details_dialog.dart';

class BookSearchScreen extends StatefulWidget {
  const BookSearchScreen({super.key});

  @override
  State<BookSearchScreen> createState() => _BookSearchScreenState();
}

class _BookSearchScreenState extends State<BookSearchScreen> {
  SharedPreferences? prefs;
  String? _token;

  // Un contrôleur pour chaque paramètre
  final TextEditingController _titreController = TextEditingController();
  final TextEditingController _auteurController = TextEditingController();
  final TextEditingController _dateController = TextEditingController(); // YYYY (String/varchar)

  final _livreService = LivreService();

  List<Livre> _results = [];
  bool _isLoading = false;
  bool _searchPerformed = false;

  @override
  void initState() {
    super.initState();
    _initPrefs();
  }

  Future<void> _initPrefs() async {
    prefs = await SharedPreferences.getInstance();
    _token = prefs!.getString('token');
    setState(() {});
  }

  Future<void> _performSearch() async {
    // Au moins un champ requis
    if (_titreController.text.isEmpty &&
        _auteurController.text.isEmpty &&
        _dateController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("⚠ Veuillez remplir au moins un champ de recherche."),
        ),
      );
      return;
    }

    if (_token == null || _token!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("❌ Token manquant. Veuillez vous reconnecter."),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _searchPerformed = true;
    });

    try {
      final String? titre = _titreController.text.trim().isEmpty
          ? null
          : _titreController.text.trim();
      final String? auteur = _auteurController.text.trim().isEmpty
          ? null
          : _auteurController.text.trim();
      final String? dateStr = _dateController.text.trim().isEmpty
          ? null
          : _dateController.text.trim(); // on garde String (varchar)

      final List<Livre> livres = await _livreService.chercherLivre(
        token: _token!,
        titre: titre,
        auteur: auteur,
        datePub: dateStr, // <-- passe la date en String si présente
      );

      if (!mounted) return;
      setState(() => _results = livres);

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de recherche: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 🔥 Méthode pour afficher les détails d'un livre
  void _showDetails(Livre livre) {
    if (_token == null || _token!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("❌ Token manquant. Veuillez vous reconnecter."),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => BookDetailsDialog(
        livre: livre,
        token: _token!,
        onBookUpdated: _performSearch, // Rafraîchir les résultats après modification
      ),
    );
  }

  @override
  void dispose() {
    _titreController.dispose();
    _auteurController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text(
          "Recherche de livre",
          style: TextStyle(color: AppColors.textLight),
        ),
      ),
      body: Column(
        children: [
          // Formulaire avec 3 champs séparés
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Champ Titre
                TextField(
                  controller: _titreController,
                  decoration: InputDecoration(
                    labelText: 'Titre du livre',
                    prefixIcon: const Icon(Icons.book, color: AppColors.primary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Champ Auteur
                TextField(
                  controller: _auteurController,
                  decoration: InputDecoration(
                    labelText: 'Auteur',
                    prefixIcon: const Icon(Icons.person, color: AppColors.primary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Champ Date (YYYY) en String
                TextField(
                  controller: _dateController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Année de publication (ex: 2019)',
                    prefixIcon: const Icon(Icons.calendar_today, color: AppColors.primary),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.primary, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Bouton de recherche
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _performSearch,
                    icon: const Icon(Icons.search, color: AppColors.textLight),
                    label: const Text("Rechercher", style: TextStyle(color: AppColors.textLight)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Résultats
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _buildResultsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    if (!_searchPerformed) {
      return const Center(
        child: Text(
          "Remplissez au moins un champ pour rechercher.",
          style: AppTextStyles.subtitle,
        ),
      );
    }
    if (_results.isEmpty) {
      return const Center(
        child: Text(
          "Aucun livre trouvé.",
          style: AppTextStyles.subtitle,
        ),
      );
    }
    return ListView.builder(
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final livre = _results[index];
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(16.0),
          decoration: AppCardStyles.base,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                livre.titre,
                style: AppTextStyles.title.copyWith(fontSize: 18),
              ),
              const SizedBox(height: 8),
              if (livre.auteur != null && livre.auteur!.isNotEmpty)
                Text(
                  "Auteur: ${livre.auteur}",
                  style: AppTextStyles.subtitle,
                ),
              if (livre.datePub != null && livre.datePub!.isNotEmpty)
                Text(
                  "Date: ${livre.datePub}", // <-- String directement
                  style: AppTextStyles.subtitle,
                ),
              // positions affichées en 1-based si ton modèle stocke en 0-based
              if (livre.positionLigne != null && livre.positionColonne != null)
                Text(
                  "Position: Ligne ${livre.positionLigne!}, Colonne ${livre.positionColonne!}",
                  style: AppTextStyles.subtitle,
                )
              else
                Text(
                  "Position: Non définie",
                  style: AppTextStyles.subtitle,
                ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  style: AppButtonStyles.elevated,
                  onPressed: () => _showDetails(livre),
                  child: const Text("Plus d'informations"),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}