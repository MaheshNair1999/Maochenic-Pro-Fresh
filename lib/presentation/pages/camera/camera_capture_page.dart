import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Mode determines the UI chrome around the camera viewfinder.
enum CameraCaptureMode {
  registration, // Show registration-document overlay
  part,         // Show part scanning overlay
}

/// Full-screen camera page.
/// Returns the captured file path via [Navigator.pop], or null if cancelled.
class CameraCapturePage extends StatefulWidget {
  final CameraCaptureMode mode;
  final String title;

  const CameraCapturePage({
    super.key,
    this.mode = CameraCaptureMode.part,
    this.title = 'Take Photo',
  });

  @override
  State<CameraCapturePage> createState() => _CameraCapturePageState();
}

class _CameraCapturePageState extends State<CameraCapturePage>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isInitialised = false;
  bool _isCapturing = false;
  bool _flashOn = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  Future<void> _initCamera() async {
    // Request camera permission
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      setState(() => _error = 'Camera permission denied. Please enable it in Settings.');
      return;
    }

    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() => _error = 'No cameras found on this device.');
        return;
      }

      // Prefer back camera
      final back = _cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first,
      );

      _controller = CameraController(
        back,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();
      if (mounted) setState(() => _isInitialised = true);
    } catch (e) {
      if (mounted) setState(() => _error = 'Failed to start camera: $e');
    }
  }

  Future<void> _toggleFlash() async {
    if (_controller == null || !_isInitialised) return;
    setState(() => _flashOn = !_flashOn);
    await _controller!.setFlashMode(_flashOn ? FlashMode.torch : FlashMode.off);
  }

  Future<void> _capture() async {
    if (_controller == null || !_isInitialised || _isCapturing) return;

    setState(() => _isCapturing = true);

    try {
      final dir = await getApplicationDocumentsDirectory();
      final fileName = 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = path.join(dir.path, 'photos', fileName);

      // Ensure directory exists
      await Directory(path.dirname(filePath)).create(recursive: true);

      final xFile = await _controller!.takePicture();
      await File(xFile.path).copy(filePath);

      if (mounted) Navigator.of(context).pop(filePath);
    } catch (e) {
      setState(() => _isCapturing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Capture failed: $e')),
        );
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      _controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // ── Camera preview ─────────────────────────────────────────────
            if (_isInitialised && _error == null)
              Positioned.fill(
                child: CameraPreview(_controller!),
              ),

            // ── Error overlay ──────────────────────────────────────────────
            if (_error != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.no_photography, color: Colors.white54, size: 64),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: const TextStyle(color: Colors.white70),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _initCamera,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),

            // ── Loading overlay ────────────────────────────────────────────
            if (!_isInitialised && _error == null)
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),

            // ── Top bar ────────────────────────────────────────────────────
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black87, Colors.transparent],
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(null),
                    ),
                    Expanded(
                      child: Text(
                        widget.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _flashOn ? Icons.flash_on : Icons.flash_off,
                        color: _flashOn ? Colors.amber : Colors.white,
                      ),
                      onPressed: _toggleFlash,
                    ),
                  ],
                ),
              ),
            ),

            // ── Scanning overlay ───────────────────────────────────────────
            if (_isInitialised && _error == null)
              Positioned.fill(
                child: _ScanOverlay(mode: widget.mode),
              ),

            // ── Bottom controls ────────────────────────────────────────────
            if (_isInitialised && _error == null)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black87, Colors.transparent],
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Capture button
                      GestureDetector(
                        onTap: _capture,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isCapturing
                                ? Colors.white60
                                : Colors.white,
                            border: Border.all(
                              color: Colors.white54,
                              width: 4,
                            ),
                          ),
                          child: _isCapturing
                              ? const Padding(
                                  padding: EdgeInsets.all(20),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.black,
                                  ),
                                )
                              : const Icon(Icons.camera_alt,
                                  size: 32, color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Visual guide overlay drawn over the camera preview.
class _ScanOverlay extends StatelessWidget {
  final CameraCaptureMode mode;
  const _ScanOverlay({required this.mode});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDoc = mode == CameraCaptureMode.registration;

    // Guide box dimensions
    final boxWidth = size.width * 0.92;
    final boxHeight = isDoc ? size.height * 0.42 : size.height * 0.58;

    return Stack(
      children: [
        // Semi-transparent mask
        CustomPaint(
          size: Size(size.width, size.height),
          painter: _MaskPainter(
            cutoutWidth: boxWidth,
            cutoutHeight: boxHeight,
          ),
        ),
        // Guide frame corners
        Center(
          child: SizedBox(
            width: boxWidth,
            height: boxHeight,
            child: Stack(
              children: [
                _corner(top: 0, left: 0, rotate: 0),
                _corner(top: 0, right: 0, rotate: 90),
                _corner(bottom: 0, right: 0, rotate: 180),
                _corner(bottom: 0, left: 0, rotate: 270),
              ],
            ),
          ),
        ),
        // Hint text
        Positioned(
          bottom: 120,
          left: 0,
          right: 0,
          child: Text(
            isDoc
                ? 'Align registration document within the frame'
                : 'Position the part clearly in frame',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ).animate(onPlay: (c) => c.repeat(reverse: true))
              .fadeIn(duration: 800.ms)
              .then(delay: 800.ms)
              .fadeOut(duration: 800.ms),
        ),
      ],
    );
  }

  Widget _corner({
    double? top,
    double? left,
    double? right,
    double? bottom,
    required double rotate,
  }) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: Transform.rotate(
        angle: rotate * 3.14159 / 180,
        child: const _CornerMarker(),
      ),
    );
  }
}

class _CornerMarker extends StatelessWidget {
  const _CornerMarker();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: CustomPaint(painter: _CornerPainter()),
    );
  }
}

class _CornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset.zero, Offset(size.width, 0), paint);
    canvas.drawLine(Offset.zero, Offset(0, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MaskPainter extends CustomPainter {
  final double cutoutWidth;
  final double cutoutHeight;

  _MaskPainter({required this.cutoutWidth, required this.cutoutHeight});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black54;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final left = cx - cutoutWidth / 2;
    final top = cy - cutoutHeight / 2;

    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(left, top, cutoutWidth, cutoutHeight),
          const Radius.circular(8),
        ),
      )
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _MaskPainter oldDelegate) =>
      oldDelegate.cutoutWidth != cutoutWidth ||
      oldDelegate.cutoutHeight != cutoutHeight;
}
