import 'dart:ui'; // Important pour ImageFilter
import 'package:flutter/material.dart';
import '../models/livre.dart'; // Import du modèle Livre
import '../theme/app_theme.dart'; // Import du thème
import '../services/livre_services.dart'; // Import du service

class BookDetailsDialog extends StatelessWidget {
  final Livre livre;
  final String token;
  final VoidCallback onBookUpdated; // Callback pour rafraîchir la liste

  const BookDetailsDialog({
    super.key,
    required this.livre,
    required this.token,
    required this.onBookUpdated,
  });

  @override
  Widget build(BuildContext context) {
    // Le BackdropFilter applique un filtre (ici, un flou) à tout ce qui se trouve derrière lui.
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: AlertDialog(
        backgroundColor: AppColors.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: Text(
          livre.titre,
          style: AppTextStyles.title,
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔥 Affiche l'auteur s'il existe
              if (livre.auteur != null && livre.auteur!.isNotEmpty)
                _buildDetailRow("Auteur:", livre.auteur!),

              // 🔥 Affiche la date de publication si elle existe
              if (livre.datePub != null && livre.datePub!.isNotEmpty)
                _buildDetailRow(
                  "Date de publication:",
                  livre.datePub!,
                ),

              // 🔥 Affiche l'URL de couverture si elle existe
              if (livre.couvertureUrl != null && livre.couvertureUrl!.isNotEmpty)
                _buildDetailRow("Couverture:", livre.couvertureUrl!),

              const Divider(height: 20, color: AppColors.primary),
              const Text(
                "Positionnement",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: AppColors.primary,
                ),
              ),

              // 🔥 Utilise les positions ligne/colonne
              _buildDetailRow(
                "Position:",
                "Ligne ${livre.positionLigne}, Colonne ${livre.positionColonne}",
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
            onPressed: () {
              Navigator.of(context).pop();
              _showEditDialog(context);
            },
            child: const Text("Modifier"),
          ),
        ],
      ),
    );
  }

  // Widget utilitaire pour afficher une ligne de détail
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
              color: AppColors.textDark,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🔥 Dialog de modification
  void _showEditDialog(BuildContext context) {
    final titleCtrl = TextEditingController(text: livre.titre);
    final authorCtrl = TextEditingController(text: livre.auteur ?? "");
    final yearCtrl = TextEditingController(text: livre.datePub ?? "");
    final shelfCtrl = TextEditingController(text: livre.positionLigne.toString());
    final colCtrl = TextEditingController(text: livre.positionColonne.toString());

    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          backgroundColor: AppColors.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text("Modifier les informations", style: AppTextStyles.title),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: "Titre *"),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: authorCtrl,
                  decoration: const InputDecoration(labelText: "Auteur"),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: yearCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Année de publication"),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: shelfCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Étagère"),
                ),
                const SizedBox(height: 8),
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
              style: AppButtonStyles.text,
              onPressed: () => Navigator.pop(context),
              child: const Text("Annuler"),
            ),
            ElevatedButton(
              style: AppButtonStyles.elevated,
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("❌ Le titre est obligatoire.")),
                  );
                  return;
                }

                final updated = Livre(
                  livreId: livre.livreId,
                  biblioId: livre.biblioId,
                  titre: titleCtrl.text.trim(),
                  auteur: authorCtrl.text.trim().isEmpty ? null : authorCtrl.text.trim(),
                  datePub: yearCtrl.text.trim().isEmpty ? null : yearCtrl.text.trim(),
                  positionLigne: int.tryParse(shelfCtrl.text.trim()) ?? livre.positionLigne,
                  positionColonne: int.tryParse(colCtrl.text.trim()) ?? livre.positionColonne,
                );

                final livreService = LivreService();
                final ok = await livreService.modifierLivre(token, updated);

                if (ok) {
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("✅ Livre modifié avec succès")),
                  );
                  onBookUpdated(); // Rafraîchir la liste
                } else {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("❌ Échec de la modification.")),
                  );
                }
              },
              child: const Text("Sauvegarder"),
            ),
          ],
        ),
      ),
    );
  }
}