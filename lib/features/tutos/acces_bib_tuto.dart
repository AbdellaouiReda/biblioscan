import 'package:flutter/material.dart';
import '../../screens/accesBib.dart'; // L'écran du collègue
import '../onboarding/tuto_wrapper.dart';

class AccesBibTuto extends StatelessWidget {
  const AccesBibTuto({super.key});

  @override
  Widget build(BuildContext context) {
    // On enveloppe l'original
    return const TutoWrapper(
      tutoKey: 'biblio',
      title: "Vos Bibliothèques",
      description: "Gérez vos espaces ici.",
      child: AccesBib(),
    );
  }
}