import 'package:flutter/material.dart';
import '../../screens/listeLivres.dart';
import '../../models/bibliotheque.dart';
import '../onboarding/tuto_wrapper.dart';

class ListeLivresTuto extends StatelessWidget {
  final Bibliotheque library;

  const ListeLivresTuto({super.key, required this.library});

  @override
  Widget build(BuildContext context) {
    return TutoWrapper(
      tutoKey: 'liste_detaillee',
      title: "Gestion de l'étagère",
      description: "• Faites défiler horizontalement pour voir les livres.\n• Appuyez sur une couverture pour modifier ou supprimer.\n• Utilisez le '+' pour un ajout manuel.",
      child: ListeLivres(library: library),
    );
  }
}