import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../models/Livre.dart';
import '../models/Bibliotheque.dart';
import '../theme/app_theme.dart';
import '../database/database_helper.dart';
import 'listeLivres.dart';

enum CameraAspect { ratio169, ratio11 }

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

class _CameraState extends State<Camera> with SingleTickerProviderStateMixin {
  late CameraController _controller;
  late List<CameraDescription> _cameras;
  bool _isInitialized = false;
  bool _isRecording = false;
  bool _isPhotoMode = true;
  FlashMode _flashMode = FlashMode.off;
  CameraAspect _currentAspect = CameraAspect.ratio169;
  bool _isCapturing = false;
  Timer? _timer;
  int _recordDuration = 0;

  late AnimationController _popController;
  late Animation<double> _popAnimation;
  bool _showPop = false;

  // 📚 Liste des livres connus
  final List<Livre> livresConnus = [
    Livre(biblioId: 1, titre: "Alcools", auteur: "Guillaume Apollinaire", positionLigne: 0, positionColonne: 0),
    Livre(biblioId: 1, titre: "Le Mariage de Figaro", auteur: "Beaumarchais", positionLigne: 0, positionColonne: 0),
    Livre(biblioId: 1, titre: "La Peau de chagrin", auteur: "Honoré de Balzac", positionLigne: 0, positionColonne: 0),
    Livre(biblioId: 1, titre: "Le Meilleur des Mondes", auteur: "Aldous Huxley", positionLigne: 0, positionColonne: 0),
    Livre(biblioId: 1, titre: "Un cœur simple", auteur: "Gustave Flaubert", positionLigne: 0, positionColonne: 0),
  ];

  @override
  void initState() {
    super.initState();
    _initCamera();

    _popController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _popAnimation = CurvedAnimation(
      parent: _popController,
      curve: Curves.easeOutBack,
    );
  }

  Future<void> _initCamera([CameraDescription? camera]) async {
    _cameras = await availableCameras();
    final selectedCamera = camera ?? _cameras.first;

    _controller = CameraController(
      selectedCamera,
      ResolutionPreset.high,
      enableAudio: true,
    );

    await _controller.initialize();
    await _controller.setFlashMode(FlashMode.off);
    setState(() => _isInitialized = true);
  }

  void _switchCamera() {
    final lensDirection = _controller.description.lensDirection;
    final newCamera = _cameras.firstWhere(
          (cam) => cam.lensDirection != lensDirection,
      orElse: () => _cameras.first,
    );
    _initCamera(newCamera);
  }

  void _toggleFlash() async {
    if (_flashMode == FlashMode.off) {
      _flashMode = FlashMode.auto;
    } else if (_flashMode == FlashMode.auto) {
      _flashMode = FlashMode.always;
    } else {
      _flashMode = FlashMode.off;
    }
    await _controller.setFlashMode(_flashMode);
    setState(() {});
  }

  void _toggleAspect() {
    setState(() {
      _currentAspect = _currentAspect == CameraAspect.ratio169
          ? CameraAspect.ratio11
          : CameraAspect.ratio169;
    });
  }

  void _toggleMode() {
    setState(() {
      _isPhotoMode = !_isPhotoMode;
    });
  }

  void _triggerPopMessage(String message) async {
    setState(() => _showPop = true);
    _popController.forward(from: 0);
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _showPop = false);
  }

  /// 📸 Capture photo
  Future<void> _capturePhoto() async {
    if (_isCapturing) return;
    _isCapturing = true;

    _triggerPopMessage("Livres détectés !");
    await Future.delayed(const Duration(seconds: 1));

    await _enregistrerLivresEtAfficher();

    _isCapturing = false;
  }

  /// 🎥 Capture vidéo avec timer et navigation fiable
  Future<void> _captureVideo() async {
    if (_isRecording) {
      final file = await _controller.stopVideoRecording();
      setState(() => _isRecording = false);
      _timer?.cancel();
      _recordDuration = 0;
      _triggerPopMessage("Vidéo enregistrée !");
      debugPrint("🎬 Vidéo sauvegardée : ${file.path}");

      // ✅ Navigation différée pour éviter le blocage du contrôleur caméra
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) await _enregistrerLivresEtAfficher();
    } else {
      await _controller.startVideoRecording();
      setState(() {
        _isRecording = true;
        _recordDuration = 0;
      });
      _startTimer();
    }
  }

  /// ⏱️ Timer vidéo
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_isRecording) {
        setState(() => _recordDuration++);
      } else {
        t.cancel();
      }
    });
  }

  /// Enregistre les livres et ouvre la liste
  Future<void> _enregistrerLivresEtAfficher() async {
    final db = DatabaseHelper.instance;
    for (var livre in livresConnus) {
      final existants = await db.getLivresByBibliotheque(livre.biblioId);
      final existe = existants.any((l) => l.titre == livre.titre);
      if (!existe) await db.insertLivre(livre);
    }

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => ListeLivres(
          library: Bibliotheque(
            userId: 1,
            nom: widget.libraryName ?? "Ma Bibliothèque",
            nbLignes: widget.rows,
            nbColonnes: widget.columns,
          ),
          scannedBooks: livresConnus,
        ),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer?.cancel();
    _popController.dispose();
    super.dispose();
  }

  String _formatDuration(int seconds) {
    final min = (seconds ~/ 60).toString().padLeft(2, '0');
    final sec = (seconds % 60).toString().padLeft(2, '0');
    return "$min:$sec";
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    // 🔧 Correction du ratio caméra : utilisation directe du widget FittedBox
    final preview = Center(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _currentAspect == CameraAspect.ratio11
              ? MediaQuery.of(context).size.width
              : MediaQuery.of(context).size.width,
          height: _currentAspect == CameraAspect.ratio11
              ? MediaQuery.of(context).size.width
              : MediaQuery.of(context).size.height,
          child: CameraPreview(_controller),
        ),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(child: preview),

          /// 🔘 Haut : Flash + ratio
          Positioned(
            top: 50,
            right: 20,
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    _flashMode == FlashMode.off
                        ? Icons.flash_off
                        : _flashMode == FlashMode.auto
                        ? Icons.flash_auto
                        : Icons.flash_on,
                    color: Colors.white,
                  ),
                  onPressed: _toggleFlash,
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.black54,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _toggleAspect,
                  child: Text(_currentAspect == CameraAspect.ratio169 ? "16:9" : "1:1"),
                ),
              ],
            ),
          ),

          /// 🔴 Timer pendant enregistrement
          if (_isRecording)
            Positioned(
              top: 60,
              left: 20,
              child: Row(
                children: [
                  const Icon(Icons.fiber_manual_record, color: Colors.red, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    _formatDuration(_recordDuration),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

          /// 🔘 Bas : boutons capture
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: Icon(
                    _isPhotoMode ? Icons.videocam : Icons.photo_camera,
                    color: Colors.white,
                    size: 30,
                  ),
                  onPressed: _toggleMode,
                ),
                GestureDetector(
                  onTap: _isPhotoMode ? _capturePhoto : _captureVideo,
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
                IconButton(
                  icon: const Icon(Icons.cameraswitch, color: Colors.white, size: 30),
                  onPressed: _switchCamera,
                ),
              ],
            ),
          ),

          /// ✨ Pop feedback
          if (_showPop)
            Center(
              child: ScaleTransition(
                scale: _popAnimation,
                child: Container(
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.book, color: Colors.white, size: 40),
                      SizedBox(height: 8),
                      Text(
                        "Livres enregistrés !",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
