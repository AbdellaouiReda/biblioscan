import 'package:flutter/material.dart';
import '../api_service.dart';
import '../theme/app_theme.dart';
import 'book_details_dialog.dart';

class BookSearchScreen extends StatefulWidget {
  const BookSearchScreen({super.key});

  @override
  State<BookSearchScreen> createState() => _BookSearchScreenState();
}

class _BookSearchScreenState extends State<BookSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<SearchResultItem> _results = [];
  bool _isLoading = false;
  bool _searchPerformed = false;

  Future<void> _performSearch() async {
    if (_searchController.text.isEmpty) return;
    setState(() {
      _isLoading = true;
      _searchPerformed = true;
    });
    try {
      final results = await ApiService.searchBooksGlobally(
        _searchController.text,
      );
      setState(() {
        _results = results;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de recherche: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showDetails(SearchResultItem result) {
    showDialog(
      context: context,
      builder: (context) => BookDetailsDialog(result: result),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Recherche de livre")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Titre du livre, auteur...',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _performSearch,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onSubmitted: (_) => _performSearch(),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildResultsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    if (!_searchPerformed) {
      return const Center(
        child: Text("Commencez une recherche pour voir les résultats."),
      );
    }
    if (_results.isEmpty) {
      return const Center(child: Text("Aucun livre trouvé."));
    }
    return ListView.builder(
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final result = _results[index];
        // MODIFICATION: On utilise un Container avec le style de carte
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(16.0),
          decoration: AppCardStyles.base, // ✨ Style de carte appliqué ici
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                result.book.title,
                // MODIFICATION: On utilise le style de texte du thème
                style: AppTextStyles.title.copyWith(fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                "Position: ${result.bookshelfName} (${result.bookshelfLocation})",
                // MODIFICATION: On utilise le style de texte du thème
                style: AppTextStyles.subtitle,
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () => _showDetails(result),
                  // Le style est appliqué automatiquement par le thème global
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
