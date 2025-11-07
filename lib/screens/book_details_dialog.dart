import 'dart:ui'; // Important pour ImageFilter
import 'package:flutter/material.dart';
import '../models/livre.dart'; // Import du modèle Livre

class BookDetailsDialog extends StatelessWidget {
  final Livre livre;

  const BookDetailsDialog({super.key, required this.livre});

  @override
  Widget build(BuildContext context) {
    // Le BackdropFilter applique un filtre (ici, un flou) à tout ce qui se trouve derrière lui.
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: AlertDialog(
        title: Text(livre.titre),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔥 Affiche l'auteur s'il existe
              if (livre.auteur != null && livre.auteur!.isNotEmpty)
                _buildDetailRow(context, "Auteur:", livre.auteur!),

              // 🔥 Affiche la date de publication si elle existe
              if (livre.datePub != null && livre.datePub!.isNotEmpty)
                _buildDetailRow(
                  context,
                  "Date de publication:",
                  livre.datePub!,
                ),

              // 🔥 Affiche l'URL de couverture si elle existe
              if (livre.couvertureUrl != null && livre.couvertureUrl!.isNotEmpty)
                _buildDetailRow(context, "Couverture:", livre.couvertureUrl!),

              const Divider(height: 20),
              const Text(
                "Positionnement",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),

              // 🔥 Utilise les positions ligne/colonne
              _buildDetailRow(
                context,
                "Position:",
                "Ligne ${livre.positionLigne}, Colonne ${livre.positionColonne}",
              ),

              // 🔥 Affiche si c'est une correction manuelle
              if (livre.correctionManuelle)
                const Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 16, color: Colors.orange),
                      SizedBox(width: 4),
                      Text(
                        "Correction manuelle",
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Fermer"),
          ),
        ],
      ),
    );
  }

  // Widget utilitaire pour afficher une ligne de détail
  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: RichText(
        text: TextSpan(
          style: DefaultTextStyle.of(context).style,
          children: [
            TextSpan(
              text: '$label ',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}