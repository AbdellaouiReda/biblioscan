import 'package:flutter/material.dart';
import '../../screens/book_search_screen.dart';
import '../onboarding/tuto_wrapper.dart';

class BookSearchTuto extends StatelessWidget {
  const BookSearchTuto({super.key});

  @override
  Widget build(BuildContext context) {
    return const TutoWrapper(
      tutoKey: 'global_search',
      title: "Recherche Globale",
      description: "Tapez un titre ou un auteur pour retrouver un livre instantanément dans n'importe laquelle de vos bibliothèques.",
      child: BookSearchScreen(), // L'écran original
    );
  }
}