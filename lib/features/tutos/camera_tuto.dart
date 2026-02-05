import 'package:flutter/material.dart';
import '../../screens/camera.dart';
import '../onboarding/tuto_wrapper.dart';

class CameraTuto extends StatelessWidget {
  final int rows;
  final int columns;
  final String? libraryName;
  final String? biblioId;

  const CameraTuto({
    super.key,
    required this.rows,
    required this.columns,
    this.libraryName,
    this.biblioId,
  });

  @override
  Widget build(BuildContext context) {
    return TutoWrapper(
      tutoKey: 'camera_scan',
      title: "Scanner un livre",
      description: "Cadrez la tranche ou le code-barres dans le rectangle pour l'ajouter à votre bibliothèque.",
      child: Camera(
        rows: rows,
        columns: columns,
        libraryName: libraryName,
        biblioId: biblioId,
      ),
    );
  }
}