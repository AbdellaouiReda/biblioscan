import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../api_service.dart';

class BookDetailsDialog extends StatelessWidget {
  final SearchResultItem result;

  const BookDetailsDialog({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: AlertDialog(
        backgroundColor: AppColors.background.withOpacity(0.95),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          result.book.title,
          style: AppTextStyles.title.copyWith(fontSize: 20),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow(context, "Auteur :", result.book.author),
              _buildDetailRow(
                context,
                "Date d'édition :",
                result.book.publicationDate ?? "N/A",
              ),
              _buildDetailRow(context, "ISBN :", result.book.isbn),
              const Divider(height: 24, color: AppColors.primary),

              Text(
                "📍 Positionnement",
                style: AppTextStyles.title.copyWith(
                  fontSize: 16,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 6),

              _buildDetailRow(
                context,
                "Meuble :",
                "${result.bookshelfName} (${result.bookshelfLocation})",
              ),
              _buildDetailRow(context, "Étagère :", result.shelfName),
              _buildDetailRow(
                context,
                "Colonne :",
                result.columnName ?? "N/A",
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
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String? value) {
    final displayValue = (value == null || value.isEmpty) ? "N/A" : value;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: RichText(
        text: TextSpan(
          style: AppTextStyles.subtitle.copyWith(
            fontSize: 14,
            color: AppColors.textDark,
          ),
          children: [
            TextSpan(
              text: "$label ",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            TextSpan(text: displayValue),
          ],
        ),
      ),
    );
  }
}
