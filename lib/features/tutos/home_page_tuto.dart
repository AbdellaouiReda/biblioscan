import 'package:flutter/material.dart';
import '../../screens/home_page.dart';
import '../onboarding/tuto_wrapper.dart';

class HomePageTuto extends StatelessWidget {
  const HomePageTuto({super.key});
  @override
  Widget build(BuildContext context) => const TutoWrapper(
    tutoKey: 'home',
    title: "Bienvenue !",
    description: "Connectez-vous pour synchroniser vos livres.",
    child: HomePage(),
  );
}