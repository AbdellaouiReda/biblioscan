import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/livre.dart';
import '../models/bibliotheque.dart';
import '../theme/app_theme.dart';
import '../services/livre_services.dart';
import '../services/bib_services.dart';

class BookDetailsDialog extends StatefulWidget {
  final Livre livre;
  final String token;
  final VoidCallback onBookUpdated;

  const BookDetailsDialog({
    super.key,
    required this.livre,
    required this.token,
    required this.onBookUpdated,
  });

  @override
  State<BookDetailsDialog> createState() => _BookDetailsDialogState();
}

class _BookDetailsDialogState extends State<BookDetailsDialog> {
  final BibliothequeService _bibService = BibliothequeService();
  List<Bibliotheque> _bibliotheques = [];
  int? _selectedBiblioId;
  bool _isLoadingBibliotheques = true;

  @override
  void initState() {
    super.initState();
    _initBibliotheques();
  }

  Future<void> _initBibliotheques() async {
    try {
      final libs = await _bibService.listerBibliotheques(widget.token);
      print("📚 Bibliothèques chargées : ${libs.length}");
      print("📖 Livre biblioId : ${widget.livre.biblioId}");
      for (var bib in libs) {
        print("  - ${bib.biblioId}: ${bib.nom}");
      }

      setState(() {
        _bibliotheques = libs;
        _selectedBiblioId = widget.livre.biblioId;
        _isLoadingBibliotheques = false;
      });
    } catch (e) {
      print("❌ Erreur lors du chargement des bibliothèques : $e");
      setState(() {
        _isLoadingBibliotheques = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(widget.livre.titre, style: AppTextStyles.title),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.livre.auteur != null && widget.livre.auteur!.isNotEmpty)
                _buildDetailRow("Auteur:", widget.livre.auteur!),
              if (widget.livre.datePub != null && widget.livre.datePub!.isNotEmpty)
                _buildDetailRow("Date de publication:", widget.livre.datePub!),
              const Divider(height: 20, color: AppColors.primary),
              const Text(
                "Positionnement",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.primary),
              ),
              _buildDetailRow("Bibliothèque: ", "${widget.livre.bibNom}"),
              _buildDetailRow(
                "Position:",
                "Ligne ${widget.livre.positionLigne}, Colonne ${widget.livre.positionColonne}",
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            style: AppButtonStyles.text,
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Fermer"),
          ),
          ElevatedButton(
            style: AppButtonStyles.elevated,
            onPressed: _isLoadingBibliotheques
                ? null
                : () => _showEditDialog(context),
            child: const Text("Modifier"),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label ',
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppColors.textDark),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontSize: 14, color: AppColors.textDark)),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    final titleCtrl = TextEditingController(text: widget.livre.titre);
    final authorCtrl = TextEditingController(text: widget.livre.auteur ?? "");
    final yearCtrl = TextEditingController(text: widget.livre.datePub ?? "");
    final shelfCtrl =
    TextEditingController(text: widget.livre.positionLigne.toString());
    final colCtrl =
    TextEditingController(text: widget.livre.positionColonne.toString());

    // Variable locale pour le dialogue
    int? localSelectedBiblioId = _selectedBiblioId;

    print("🔧 Ouverture dialogue édition");
    print("   Biblio sélectionnée : $localSelectedBiblioId");
    print("   Nombre de bibliothèques : ${_bibliotheques.length}");

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: AlertDialog(
            backgroundColor: AppColors.background,
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: const Text("Modifier les informations",
                style: AppTextStyles.title),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(labelText: "Titre *")),
                  const SizedBox(height: 8),
                  TextField(
                      controller: authorCtrl,
                      decoration: const InputDecoration(labelText: "Auteur")),
                  const SizedBox(height: 8),
                  TextField(
                      controller: yearCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: "Année de publication")),
                  const SizedBox(height: 16),

                  // Dropdown de bibliothèque
                  const Text(
                    "Bibliothèque:",
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.textDark),
                  ),
                  const SizedBox(height: 8),

                  if (_bibliotheques.isEmpty)
                    const Text(
                      "Aucune bibliothèque disponible",
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.primary),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButton<int>(
                        isExpanded: true,
                        underline: const SizedBox(),
                        value: localSelectedBiblioId,
                        hint: const Text("Sélectionner une bibliothèque"),
                        items: _bibliotheques.map((bib) {
                          return DropdownMenuItem<int>(
                            value: bib.biblioId,
                            child: Text(bib.nom),
                          );
                        }).toList(),
                        onChanged: (val) {
                          print("📝 Changement bibliothèque : $val");
                          setDialogState(() {
                            localSelectedBiblioId = val;
                          });
                        },
                      ),
                    ),

                  const SizedBox(height: 16),
                  TextField(
                      controller: shelfCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "Étagère")),
                  const SizedBox(height: 8),
                  TextField(
                      controller: colCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "Colonne")),
                ],
              ),
            ),
            actions: [
              TextButton(
                style: AppButtonStyles.text,
                onPressed: () => Navigator.pop(context),
                child: const Text("Annuler"),
              ),
              ElevatedButton(
                style: AppButtonStyles.elevated,
                onPressed: () async {
                  if (titleCtrl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text("❌ Le titre est obligatoire.")),
                    );
                    return;
                  }

                  if (localSelectedBiblioId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text("❌ Veuillez sélectionner une bibliothèque.")),
                    );
                    return;
                  }

                  final updated = Livre(
                    livreId: widget.livre.livreId,
                    biblioId: localSelectedBiblioId!,
                    titre: titleCtrl.text.trim(),
                    auteur: authorCtrl.text.trim().isEmpty
                        ? null
                        : authorCtrl.text.trim(),
                    datePub: yearCtrl.text.trim().isEmpty
                        ? null
                        : yearCtrl.text.trim(),
                    positionLigne: int.tryParse(shelfCtrl.text.trim()) ??
                        widget.livre.positionLigne,
                    positionColonne: int.tryParse(colCtrl.text.trim()) ??
                        widget.livre.positionColonne,
                  );

                  print("💾 Sauvegarde livre avec biblioId : ${updated.biblioId}");

                  final livreService = LivreService();
                  final ok = await livreService.modifierLivre(widget.token, updated);

                  if (ok) {
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    Navigator.pop(context); // Fermer aussi le dialogue de détails
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text("✅ Livre modifié avec succès")));
                    widget.onBookUpdated();
                  } else {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text("❌ Échec de la modification.")));
                  }
                },
                child: const Text("Sauvegarder"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}