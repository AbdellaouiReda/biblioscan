import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/bibliotheque.dart';
import '../models/livre.dart';
import 'listeLivres.dart';

class Camera extends StatefulWidget {
  final int rows;
  final int columns;
  final String? libraryName;

  const Camera({
    super.key,
    required this.rows,
    required this.columns,
    this.libraryName,
  });

  @override
  State<Camera> createState() => _CameraState();
}

class _CameraState extends State<Camera> {
  int currentRow = 0;
  int currentColumn = 0;
  bool _isRecording = false;
  bool _isVideoMode = true;
  bool _showPop = false;

  // Simulation de livres scannés
  List<Livre> scannedBooks = [];

  void _simulateCapture() async {
    setState(() => _showPop = true);

    await Future.delayed(const Duration(seconds: 1));
    setState(() => _showPop = false);

    _moveToNext();
  }

  void _moveToNext() {
    if (currentColumn < widget.columns - 1) {
      setState(() => currentColumn++);
    } else if (currentRow < widget.rows - 1) {
      setState(() {
        currentColumn = 0;
        currentRow++;
      });
    } else {
      // Fin de la simulation → afficher ListeLivres
      scannedBooks = [
        Livre(
          biblioId: 1,
          titre: "Livre Test 1",
          auteur: "Auteur Démo",
          positionLigne: 0,
          positionColonne: 0,
        ),
        Livre(
          biblioId: 1,
          titre: "Livre Test 2",
          auteur: "Auteur Démo",
          positionLigne: 0,
          positionColonne: 1,
        ),
      ];

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ListeLivres(
            library: Bibliotheque(
              userId: 1,
              nom: widget.libraryName ?? "Biblio Test",
              nbLignes: widget.rows,
              nbColonnes: widget.columns,
            ),
            scannedBooks: scannedBooks,
          ),
        ),
      );
    }
  }

  void _toggleMode() => setState(() => _isVideoMode = !_isVideoMode);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: AppColors.primary,
          title: Text(
            widget.libraryName ?? "Caméra de Test",
            style: AppTextStyles.title.copyWith(color: AppColors.textLight),
          ),
          centerTitle: true,
        ),
        body: Stack(
            children: [
              // Zone principale simulant la caméra
              Center(
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.grey.shade900,
                  child: const Icon(
                    Icons.videocam,
                    color: Colors.white70,
                    size: 100,
                  ),
                ),
              ),

              // Texte de progression
              Positioned(
                top: 40,
                left: 20,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.black45,
                  child: Text(
                    "Étagère ${currentRow + 1}/${widget.rows} • Colonne ${currentColumn + 1}/${widget.columns}",
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),

              // Message "Livre détecté"
              if (_showPop)
                const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.book, color: Colors.white, size: 50),
                      SizedBox(height: 10),
                      Text(
                        "Livre détecté !",
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ],
                  ),
                ),

              // Boutons en bas
              Positioned(
                bottom: 50,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: Icon(
                        _isVideoMode ? Icons.photo_camera : Icons.videocam,
                        color: Colors.white,
                        size: 32,
                      ),
                      onPressed: _toggleMode,
                    ),
                    GestureDetector(
                      onTap: _simulateCapture,
                      child: Container(
                        width: 75,
                        height: 75,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _isRecording ? Colors.red : Colors.white,
                          border: Border.all(color: Colors.black, width: 2),
                        ),
                      ),
                    ),
                    const Icon(Icons.cameraswitch, color: Colors.white, size: 32),
                  ],
                ),
              ),
            ],
            ),
        );
    }
}