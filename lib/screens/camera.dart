import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image/image.dart' as img;
import '../models/Livre.dart';
import '../theme/app_theme.dart';
import '../services/camera_service.dart';
import 'listeLivres.dart';
import '../models/bibliotheque.dart';

enum CameraAspect { ratio169, ratio11 }

// 🔹 Dimensions globales du cadre de scan
const double kScanFrameWidth = 280.0;
const double kScanFrameHeight = 200.0;

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

  bool _isRecording = false;
  bool _isVideoMode = true;
  FlashMode _flashMode = FlashMode.off;

  CameraAspect _currentAspect = CameraAspect.ratio169;

  int selectedRow = 1;
  int selectedColumn = 1;

  List<Livre> scannedBooks = [];

  double _zoomLevel = 1.0;
  double _maxZoom = 1.0;
  File? _lastThumbnail;

  late AnimationController _popController;
  late Animation<double> _popAnimation;
  bool _showPop = false;

  String? _token;
  String? _biblioId;
  SharedPreferences? _prefs;

  @override
  void initState() {
    super.initState();
    _biblioId = widget.biblioId;
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
    await _controller.setFlashMode(FlashMode.off);
    setState(() => _isInitialized = true);
  }

  @override
  void dispose() {
    if (_controller.value.isInitialized) {
      _controller.dispose();
    }
    _popController.dispose();
    super.dispose();
  }

  Future<void> _capture() async {
    try {
      final XFile image = await _controller.takePicture();

      // 🔹 Cropper l'image selon le cadre de scan
      final croppedImage = await _cropImageToScanArea(image.path);

      setState(() {
        _lastThumbnail = croppedImage;
      });

      final token = _token;
      final biblioId = widget.biblioId != null ? int.tryParse(widget.biblioId!) ?? 0 : 0;

      if (token != null && biblioId > 0) {
        final (uploadRes, detectRes) = await _camService.sendImageAndDetect(
          imagePath: croppedImage.path,
          biblioId: biblioId,
          positionLigne: selectedRow,
          positionColonne: selectedColumn,
          bearerToken: token,
        );

        print("✅ Upload: $uploadRes");
        print("🔎 Detect: $detectRes");

        final annotatedUrl = detectRes?["annotated_image"];
        final originalUrl = detectRes?["original_image"];
        print("🖼️ Annotated: $annotatedUrl");
        print("🖼️ Original: $originalUrl");
      } else {
        print("⚠ Token ou biblioId invalide !");
      }

      _triggerPopMessage();
    } catch (e) {
      print("⚠️ Erreur lors de la capture ou de l'envoi : $e");
    }
  }

  // 🔹 Fonction pour cropper l'image selon la zone de scan
  Future<File> _cropImageToScanArea(String imagePath) async {
    final imageFile = File(imagePath);
    final imageBytes = await imageFile.readAsBytes();
    final originalImage = img.decodeImage(imageBytes)!;

    // Dimensions de l'écran
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Position du cadre (centré)
    final scanLeft = (screenWidth - kScanFrameWidth) / 2;
    final scanTop = (screenHeight - kScanFrameHeight) / 2;

    // Ratio entre l'image et l'écran
    final scaleX = originalImage.width / screenWidth;
    final scaleY = originalImage.height / screenHeight;

    // Coordonnées de crop dans l'image originale
    final cropX = (scanLeft * scaleX).toInt();
    final cropY = (scanTop * scaleY).toInt();
    final cropWidth = (kScanFrameWidth * scaleX).toInt();
    final cropHeight = (kScanFrameHeight * scaleY).toInt();

    // Cropper l'image
    final croppedImage = img.copyCrop(
      originalImage,
      x: cropX,
      y: cropY,
      width: cropWidth,
      height: cropHeight,
    );

    // Sauvegarder l'image croppée
    final croppedPath = imagePath.replaceAll('.jpg', '_cropped.jpg');
    final croppedFile = File(croppedPath);
    await croppedFile.writeAsBytes(img.encodeJpg(croppedImage));

    return croppedFile;
  }

  void _triggerPopMessage() async {
    setState(() => _showPop = true);
    _popController.forward(from: 0);
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _showPop = false);
  }

  void _switchCamera() {
    final lensDirection = _controller.description.lensDirection;
    final newCamera = _cameras.firstWhere(
          (cam) => cam.lensDirection != lensDirection,
      orElse: () => _cameras.first,
    );
    _initCamera(newCamera);
  }

  void _toggleMode() => setState(() => _isVideoMode = !_isVideoMode);

  void _toggleFlash() async {
    if (_isVideoMode) {
      _flashMode =
      _flashMode == FlashMode.torch ? FlashMode.off : FlashMode.torch;
    } else {
      if (_flashMode == FlashMode.auto) {
        _flashMode = FlashMode.always;
      } else if (_flashMode == FlashMode.always) {
        _flashMode = FlashMode.off;
      } else {
        _flashMode = FlashMode.auto;
      }
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

  Widget _buildCameraPreview() {
    if (!_controller.value.isInitialized) return const SizedBox();
    final preview = _currentAspect == CameraAspect.ratio11
        ? Center(
      child: AspectRatio(
        aspectRatio: 1,
        child: CameraPreview(_controller),
      ),
    )
        : SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: _controller.value.previewSize!.height,
          height: _controller.value.previewSize!.width,
          child: CameraPreview(_controller),
        ),
      ),
    );

    return GestureDetector(
      onScaleUpdate: (details) async {
        final zoom = (_zoomLevel * details.scale).clamp(1.0, _maxZoom);
        setState(() => _zoomLevel = zoom);
        await _controller.setZoomLevel(zoom);
      },
      child: preview,
    );
  }

  // 🔹 Widget pour le cadre de scan
  Widget _buildScanOverlay() {
    return Center(
      child: Container(
        width: kScanFrameWidth,
        height: kScanFrameHeight,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white, width: 3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            // Coins du cadre (style QR scanner)
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
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          border: Border(
            top: alignment == Alignment.topLeft || alignment == Alignment.topRight
                ? const BorderSide(color: Colors.greenAccent, width: 4)
                : BorderSide.none,
            left: alignment == Alignment.topLeft || alignment == Alignment.bottomLeft
                ? const BorderSide(color: Colors.greenAccent, width: 4)
                : BorderSide.none,
            right: alignment == Alignment.topRight || alignment == Alignment.bottomRight
                ? const BorderSide(color: Colors.greenAccent, width: 4)
                : BorderSide.none,
            bottom: alignment == Alignment.bottomLeft || alignment == Alignment.bottomRight
                ? const BorderSide(color: Colors.greenAccent, width: 4)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          widget.libraryName ?? "Scanner les livres",
          style: AppTextStyles.title.copyWith(color: AppColors.textLight),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.book, color: Colors.white),
            onPressed: () {
              if (_biblioId != null) {
                final library = Bibliotheque(
                  biblioId: int.tryParse(_biblioId!) ?? 0,
                  nom: widget.libraryName ?? '',
                  nbLignes: widget.rows,
                  nbColonnes: widget.columns,
                  userId: null,
                );
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ListeLivres(library: library)),
                );
              }
            },
          )
        ],
      ),
      body: Stack(
        children: [
          _buildCameraPreview(),

          // 🔹 Overlay sombre avec trou transparent
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.5),
              BlendMode.srcOut,
            ),
            child: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    backgroundBlendMode: BlendMode.dstOut,
                  ),
                ),
                Center(
                  child: Container(
                    width: kScanFrameWidth,
                    height: kScanFrameHeight,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 🔹 Cadre de scan
          _buildScanOverlay(),

          // 🔹 Texte d'instruction
          Positioned(
            top: MediaQuery.of(context).size.height * 0.25,
            left: 0,
            right: 0,
            child: const Center(
              child: Text(
                "Placez le livre dans le cadre",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  shadows: [
                    Shadow(
                      color: Colors.black,
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
            ),
          ),

          Positioned(
            top: 40,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text("Étagère : ",
                          style: TextStyle(color: Colors.white)),
                      DropdownButton<int>(
                        dropdownColor: Colors.black87,
                        value: selectedRow,
                        items: List.generate(
                          widget.rows,
                              (i) => DropdownMenuItem(
                            value: i + 1,
                            child: Text(
                              "${i + 1}",
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                        onChanged: (val) {
                          if (val != null) setState(() => selectedRow = val);
                        },
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Text("Colonne : ",
                          style: TextStyle(color: Colors.white)),
                      DropdownButton<int>(
                        dropdownColor: Colors.black87,
                        value: selectedColumn,
                        items: List.generate(
                          widget.columns,
                              (i) => DropdownMenuItem(
                            value: i + 1,
                            child: Text(
                              "${i + 1}",
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                        onChanged: (val) {
                          if (val != null) setState(() => selectedColumn = val);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          if (_showPop)
            Center(
              child: ScaleTransition(
                scale: _popAnimation,
                child: Container(
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: Colors.black87.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.book, color: Colors.white, size: 40),
                      SizedBox(height: 8),
                      Text(
                        "Livre détecté !",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

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
                  onTap: _capture,
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
                  icon: const Icon(Icons.cameraswitch,
                      color: Colors.white, size: 32),
                  onPressed: _switchCamera,
                ),
              ],
            ),
          ),

          if (_lastThumbnail != null)
            Positioned(
              bottom: 160,
              right: 20,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  _lastThumbnail!,
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                ),
              ),
            ),
        ],
      ),
    );
  }
}