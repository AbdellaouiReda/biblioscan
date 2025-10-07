import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:video_thumbnail/video_thumbnail.dart' as vt;
import 'package:path_provider/path_provider.dart';
import '../models/Livre.dart';
import 'ListeLivres.dart';

enum CameraAspect { ratio169, ratio11 }

class Camera extends StatefulWidget {
  final int rows;
  final int columns;

  const Camera({super.key, required this.rows, required this.columns});

  @override
  State<Camera> createState() => _CameraState();
}

class _CameraState extends State<Camera> {
  late CameraController _controller;
  late List<CameraDescription> _cameras;
  bool _isInitialized = false;

  bool _isRecording = false;
  bool _isVideoMode = true;
  FlashMode _flashMode = FlashMode.off;

  CameraAspect _currentAspect = CameraAspect.ratio169;

  int currentRow = 0;
  int currentColumn = 0;
  List<Livre> scannedBooks = [];

  double _zoomLevel = 1.0;
  double _maxZoom = 1.0;

  File? _lastThumbnail;

  @override
  void initState() {
    super.initState();
    _initCamera();
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
    _maxZoom = await _controller.getMaxZoomLevel();
    await _controller.setFlashMode(FlashMode.off);
    setState(() => _isInitialized = true);
  }

  @override
  void dispose() {
    if (_controller.value.isInitialized) {
      _controller.setFlashMode(FlashMode.off);
      _controller.dispose();
    }
    super.dispose();
  }

  Future<void> _capture() async {
    if (_isVideoMode) {
      if (_isRecording) {
        // 🛑 Arrêt enregistrement vidéo
        final video = await _controller.stopVideoRecording();
        setState(() => _isRecording = false);
        await _controller.setFlashMode(FlashMode.off);

        // 🖼️ Génération miniature vidéo
        final thumbPath = await _generateVideoThumbnail(video.path);

        scannedBooks.add(
          Livre(
            biblioId: 1,
            titre: "Nom du Livre",
            positionLigne: currentRow,
            positionColonne: currentColumn,
            videoPath: video.path,
            couvertureUrl: thumbPath,
          ),
        );

        setState(() => _lastThumbnail = File(thumbPath));
        _moveToNextColumnOrRow();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("🎥 Vidéo enregistrée !")),
        );
      } else {
        // ▶️ Démarrage enregistrement
        await _controller.setFlashMode(FlashMode.torch);
        await _controller.startVideoRecording();
        setState(() => _isRecording = true);
      }
    } else {
      // 📸 Capture photo
      await _controller.setFlashMode(_flashMode);
      final picture = await _controller.takePicture();

      scannedBooks.add(
        Livre(
          biblioId: 1,
          titre: "Nom du Livre",
          positionLigne: currentRow,
          positionColonne: currentColumn,
          imagePath: picture.path,
          couvertureUrl: picture.path,
        ),
      );

      setState(() => _lastThumbnail = File(picture.path));
      _moveToNextColumnOrRow();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("📸 Photo ajoutée !")),
      );
    }
  }

  Future<String> _generateVideoThumbnail(String videoPath) async {
    final tempDir = await getTemporaryDirectory();
    final thumb = await vt.VideoThumbnail.thumbnailFile(
      video: videoPath,
      thumbnailPath: tempDir.path,
      imageFormat: vt.ImageFormat.JPEG,
      maxWidth: 200,
      quality: 80,
    );
    return thumb!;
  }



  void _moveToNextColumnOrRow() {
    if (currentColumn < widget.columns - 1) {
      setState(() => currentColumn++);
    } else if (currentRow < widget.rows - 1) {
      setState(() {
        currentColumn = 0;
        currentRow++;
      });
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ListeLivres(scannedBooks: scannedBooks),
        ),
      );
    }
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
    Widget preview = _currentAspect == CameraAspect.ratio11
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

    // 🔍 Zoom moderne avec pinch
    return GestureDetector(
      onScaleUpdate: (details) async {
        double zoom = (_zoomLevel * details.scale).clamp(1.0, _maxZoom);
        setState(() => _zoomLevel = zoom);
        await _controller.setZoomLevel(zoom);
      },
      child: preview,
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
      body: Stack(
        children: [
          _buildCameraPreview(),

          // 🔝 Infos étagère / colonne
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

          // 🔦 Flash + ratio
          Positioned(
            top: 40,
            right: 20,
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    _flashMode == FlashMode.auto
                        ? Icons.flash_auto
                        : _flashMode == FlashMode.always
                        ? Icons.flash_on
                        : _flashMode == FlashMode.torch
                        ? Icons.highlight
                        : Icons.flash_off,
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
                  child: Text(
                    _currentAspect == CameraAspect.ratio169 ? "16:9" : "1:1",
                  ),
                ),
              ],
            ),
          ),

          // 🎬 Boutons bas
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

          // 🖼️ Miniature
          if (_lastThumbnail != null)
            Positioned(
              bottom: 160,
              right: 20,
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ListeLivres(scannedBooks: scannedBooks),
                  ),
                ),
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
            ),
        ],
      ),
    );
  }
}
