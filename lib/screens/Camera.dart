import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:video_thumbnail/video_thumbnail.dart' as vt;
import 'package:path_provider/path_provider.dart';
import '../models/Book.dart';
import 'ListeLivres.dart';

enum CameraAspect { ratio169, ratio11 }

class Camera extends StatefulWidget {
  final int rows;
  final int columns;

  const Camera({super.key, required this.rows, required this.columns});

  @override
  State<Camera> createState() => _CameraState();
}

class _CameraState extends State<Camera> with TickerProviderStateMixin {
  late CameraController _controller;
  late List<CameraDescription> _cameras;
  bool _isInitialized = false;

  bool _isRecording = false;
  bool _isVideoMode = true;
  FlashMode _flashMode = FlashMode.off;

  CameraAspect _currentAspect = CameraAspect.ratio169;

  int currentRow = 0;
  int currentColumn = 0;
  List<Book> scannedBooks = [];

  double _zoomLevel = 1.0;
  double _maxZoom = 1.0;
  double _baseZoom = 1.0;

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
        final video = await _controller.stopVideoRecording();
        setState(() => _isRecording = false);
        await _controller.setFlashMode(FlashMode.off);

        final thumbPath = await _generateVideoThumbnail(video.path);

        scannedBooks.add(Book(title: "Nom du Livre", videoPath: video.path));

        setState(() => _lastThumbnail = File(thumbPath));
        _moveToNextColumnOrRow();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("🎥 Vidéo enregistrée !")),
        );
      } else {
        await _controller.setFlashMode(FlashMode.torch);
        await _controller.startVideoRecording();
        setState(() => _isRecording = true);
      }
    } else {
      await _controller.setFlashMode(_flashMode);
      final picture = await _controller.takePicture();

      scannedBooks.add(Book(title: "Nom du Livre", imagePath: picture.path));

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
      maxWidth: 250,
      quality: 85,
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

    // ✅ Zoom moderne + animation fluide
    return GestureDetector(
      onScaleStart: (details) => _baseZoom = _zoomLevel,
      onScaleUpdate: (details) async {
        double newZoom = (_baseZoom * details.scale).clamp(1.0, _maxZoom);
        if ((newZoom - _zoomLevel).abs() > 0.02) {
          _zoomLevel = newZoom;
          await _controller.setZoomLevel(_zoomLevel);
          setState(() {});
        }
      },
      child: AnimatedScale(
        scale: 1.0,
        duration: const Duration(milliseconds: 200),
        child: preview,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Stack(
        children: [
          _buildCameraPreview(),

          // 📍 Informations rangée/colonne
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
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),

          // ⚙️ Bas de l’écran
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

          // 🖼 Miniature capture
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
                child: AnimatedOpacity(
                  opacity: 1,
                  duration: const Duration(milliseconds: 300),
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
            ),
        ],
      ),
    );
  }
}
