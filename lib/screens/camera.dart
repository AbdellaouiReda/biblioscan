import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image/image.dart' as img;
import '../models/livre.dart';
import '../theme/app_theme.dart';
import '../services/camera_service.dart';
import 'listeLivres.dart';
import '../models/bibliotheque.dart';

enum CameraAspect { ratio169, ratio11 }

// Dimensions du cadre de scan
const double kScanFrameWidth = 300.0;
const double kScanFrameHeight = 280.0;

class Camera extends StatefulWidget {
  final int rows;
  final int columns;
  final String? libraryName;
  final String? biblioId;

  const Camera({
    super.key,
    required this.rows,
    required this.columns,
    this.libraryName,
    this.biblioId,
  });

  @override
  State<Camera> createState() => _CameraState();
}

class _CameraState extends State<Camera> with SingleTickerProviderStateMixin {
  final _camService = UploadService();
  late CameraController _controller;
  late List<CameraDescription> _cameras;
  bool _isInitialized = false;

  bool _isVideoMode = false;
  int selectedRow = 1;
  int selectedColumn = 1;

  double _zoomLevel = 1.0;
  double _maxZoom = 1.0;
  File? _lastThumbnail;

  late AnimationController _popController;
  late Animation<double> _popAnimation;
  bool _showPop = false;

  String? _token;
  SharedPreferences? _prefs;

  @override
  void initState() {
    super.initState();
    _initCamera();

    _popController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    _popAnimation = CurvedAnimation(
      parent: _popController,
      curve: Curves.easeOutBack,
    );
  }

  Future<void> _initCamera([CameraDescription? camera]) async {
    _prefs = await SharedPreferences.getInstance();
    _token = _prefs!.getString('token');

    _cameras = await availableCameras();
    final selectedCamera = camera ?? _cameras.first;
    _controller = CameraController(
      selectedCamera,
      ResolutionPreset.high,
      enableAudio: false,
    );
    await _controller.initialize();
    _maxZoom = await _controller.getMaxZoomLevel();
    setState(() => _isInitialized = true);
  }

  @override
  void dispose() {
    _controller.dispose();
    _popController.dispose();
    super.dispose();
  }

  Future<void> _capture() async {
    try {
      final XFile image = await _controller.takePicture();
      final croppedImage = await _cropImageToScanArea(image.path);

      setState(() => _lastThumbnail = croppedImage);

      final token = _token;
      final bId = widget.biblioId != null ? int.tryParse(widget.biblioId!) ?? 0 : 0;

      if (token != null && bId > 0) {
        await _camService.sendImageAndDetect(
          imagePath: croppedImage.path,
          biblioId: bId,
          positionLigne: selectedRow,
          positionColonne: selectedColumn,
          bearerToken: token,
        );
      }
      _triggerPopMessage();
    } catch (e) {
      debugPrint("⚠️ Erreur capture : $e");
    }
  }

  Future<File> _cropImageToScanArea(String imagePath) async {
    final imageFile = File(imagePath);
    final imageBytes = await imageFile.readAsBytes();
    final originalImage = img.decodeImage(imageBytes)!;

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final scaleX = originalImage.width / screenWidth;
    final scaleY = originalImage.height / screenHeight;

    final cropWidth = (kScanFrameWidth * scaleX).toInt();
    final cropHeight = (kScanFrameHeight * scaleY).toInt();
    final cropX = ((screenWidth - kScanFrameWidth) / 2 * scaleX).toInt();
    final cropY = ((screenHeight - kScanFrameHeight) / 2 * scaleY).toInt();

    final croppedImage = img.copyCrop(
      originalImage,
      x: cropX,
      y: cropY,
      width: cropWidth,
      height: cropHeight,
    );

    final rotatedImage = img.copyRotate(croppedImage, angle: 90);
    final croppedPath = imagePath.replaceAll('.jpg', '_cropped.jpg');
    final croppedFile = File(croppedPath);
    await croppedFile.writeAsBytes(img.encodeJpg(rotatedImage));

    return croppedFile;
  }

  void _triggerPopMessage() async {
    setState(() => _showPop = true);
    _popController.forward(from: 0);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _showPop = false);
  }

  void _switchCamera() {
    final lensDirection = _controller.description.lensDirection;
    final newCamera = _cameras.firstWhere(
          (cam) => cam.lensDirection != lensDirection,
      orElse: () => _cameras.first,
    );
    _initCamera(newCamera);
  }

  Widget _buildCameraPreview() {
    if (!_controller.value.isInitialized) return const SizedBox();
    return Center(child: CameraPreview(_controller));
  }

  // --- LE FIX : L'OVERLAY AVEC UN VRAI TROU ---
  Widget _buildOverlay() {
    return SizedBox.expand(
      child: CustomPaint(
        painter: HolePainter(
          width: kScanFrameWidth,
          height: kScanFrameHeight,
        ),
      ),
    );
  }

  Widget _buildScanFrame() {
    return Center(
      child: Container(
        width: kScanFrameWidth,
        height: kScanFrameHeight,
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            _buildCorner(Alignment.topLeft),
            _buildCorner(Alignment.topRight),
            _buildCorner(Alignment.bottomLeft),
            _buildCorner(Alignment.bottomRight),
          ],
        ),
      ),
    );
  }

  Widget _buildCorner(Alignment alignment) {
    return Align(
      alignment: alignment,
      child: Container(
        width: 25,
        height: 25,
        decoration: BoxDecoration(
          border: Border(
            top: (alignment == Alignment.topLeft || alignment == Alignment.topRight)
                ? const BorderSide(color: Colors.greenAccent, width: 4)
                : BorderSide.none,
            bottom: (alignment == Alignment.bottomLeft || alignment == Alignment.bottomRight)
                ? const BorderSide(color: Colors.greenAccent, width: 4)
                : BorderSide.none,
            left: (alignment == Alignment.topLeft || alignment == Alignment.bottomLeft)
                ? const BorderSide(color: Colors.greenAccent, width: 4)
                : BorderSide.none,
            right: (alignment == Alignment.topRight || alignment == Alignment.bottomRight)
                ? const BorderSide(color: Colors.greenAccent, width: 4)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(widget.libraryName ?? "Scanner", style: const TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt, color: Colors.white),
            onPressed: () {
              if (widget.biblioId != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ListeLivres(
                      library: Bibliotheque(
                        biblioId: int.tryParse(widget.biblioId!) ?? 0,
                        userId: 0,
                        nom: widget.libraryName ?? '',
                        nbLignes: widget.rows,
                        nbColonnes: widget.columns,
                      ),
                    ),
                  ),
                );
              }
            },
          )
        ],
      ),
      body: Stack(
        children: [
          _buildCameraPreview(), // La caméra au fond
          _buildOverlay(),       // L'ombre qui entoure le cadre
          _buildScanFrame(),     // Le cadre et les coins verts

          // Instructions
          Positioned(
            top: MediaQuery.of(context).size.height * 0.18,
            left: 0, right: 0,
            child: const Center(
              child: Text(
                "Alignez le dos du livre ici",
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          // Sélecteurs
          Positioned(
            top: 20, left: 20, right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
              decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(15)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildDropdown("Étagère", selectedRow, widget.rows, (v) => setState(() => selectedRow = v!)),
                  _buildDropdown("Colonne", selectedColumn, widget.columns, (v) => setState(() => selectedColumn = v!)),
                ],
              ),
            ),
          ),

          // Pop-up succès
          if (_showPop)
            Center(
              child: ScaleTransition(
                scale: _popAnimation,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: Colors.greenAccent.withOpacity(0.9), borderRadius: BorderRadius.circular(30)),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: Colors.black),
                      SizedBox(width: 10),
                      Text("Scan réussi !", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                    ],
                  ),
                ),
              ),
            ),

          // Bouton Capture
          Positioned(
            bottom: 40, left: 0, right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                const SizedBox(width: 48),
                GestureDetector(
                  onTap: _capture,
                  child: Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 5),
                    ),
                    child: Center(child: Container(width: 60, height: 60, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle))),
                  ),
                ),
                IconButton(icon: const Icon(Icons.cameraswitch, color: Colors.white, size: 32), onPressed: _switchCamera),
              ],
            ),
          ),

          if (_lastThumbnail != null)
            Positioned(
              bottom: 120, right: 30,
              child: Container(
                decoration: BoxDecoration(border: Border.all(color: Colors.white, width: 2), borderRadius: BorderRadius.circular(8)),
                child: ClipRRect(borderRadius: BorderRadius.circular(6), child: Image.file(_lastThumbnail!, width: 60, height: 60, fit: BoxFit.cover)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, int value, int max, ValueChanged<int?> onChanged) {
    return Row(
      children: [
        Text("$label: ", style: const TextStyle(color: Colors.white, fontSize: 13)),
        DropdownButton<int>(
          value: value,
          dropdownColor: Colors.black87,
          underline: const SizedBox(),
          items: List.generate(max, (i) => DropdownMenuItem(value: i + 1, child: Text("${i + 1}", style: const TextStyle(color: Colors.white)))),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

// --- LE PAINTER QUI PERCE LE TROU ---
class HolePainter extends CustomPainter {
  final double width;
  final double height;

  HolePainter({required this.width, required this.height});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withOpacity(0.65);

    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: width,
      height: height,
    );

    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height)),
        Path()..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(12))),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}