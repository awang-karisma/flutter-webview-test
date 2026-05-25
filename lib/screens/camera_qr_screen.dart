import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../widgets/qr_scanner_overlay.dart';

/// Camera screen with QR-style scanning animation overlay.
/// Shows a viewfinder with animated scanning line and corner brackets.
/// When capture is clicked, image data is returned to the caller.
class CameraQRScreen extends StatefulWidget {
  const CameraQRScreen({super.key});

  @override
  State<CameraQRScreen> createState() => _CameraQRScreenState();
}

class _CameraQRScreenState extends State<CameraQRScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isLoading = true;
  bool _hasPermission = false;
  String? _errorMessage;
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    _requestCameraPermission();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _requestCameraPermission() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    var status = await Permission.camera.request();

    if (!mounted) return;

    if (status.isGranted) {
      setState(() {
        _hasPermission = true;
      });
      await _initializeCamera();
    } else if (status.isPermanentlyDenied) {
      setState(() {
        _isLoading = false;
        _hasPermission = false;
        _errorMessage = 'Camera permission permanently denied. Please enable in app settings.';
      });
    } else {
      setState(() {
        _isLoading = false;
        _hasPermission = false;
        _errorMessage = 'Camera permission denied.';
      });
    }
  }

  Future<void> _initializeCamera() async {
    if (!mounted) return;
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _errorMessage = 'No cameras available on this device.';
        });
        return;
      }

      // Find the back camera
      final backCamera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras!.first,
      );

      _controller = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _controller!.initialize();

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to initialize camera: $e';
      });
    }
  }

  Future<void> _captureAndReturn() async {
    if (_controller == null || !_controller!.value.isInitialized || _isCapturing) {
      return;
    }

    if (!mounted) return;
    setState(() {
      _isCapturing = true;
    });

    try {
      // Haptic feedback on capture
      HapticFeedback.mediumImpact();

      // Take the picture
      final image = await _controller!.takePicture();

      // Read image bytes
      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);

      // Get file info
      final file = File(image.path);
      final fileSize = await file.length();

      // Save to temporary directory with timestamp
      final tempDir = await getTemporaryDirectory();
      final fileName = 'captured_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedPath = '${tempDir.path}/$fileName';

      // Copy the image to temp directory
      await file.copy(savedPath);

      // Build comprehensive data response
      final data = {
        'imagePath': savedPath,
        'imageBase64': 'data:image/jpeg;base64,$base64Image',
        'timestamp': DateTime.now().toIso8601String(),
        'fileSize': fileSize,
        'success': true,
      };

      if (mounted) {
        Navigator.pop(context, jsonEncode(data));
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to capture: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Scan'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF00E5FF)),
            SizedBox(height: 16),
            Text(
              'Initializing camera...',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.camera_alt_outlined,
                size: 64,
                color: Colors.white54,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _requestCameraPermission,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00E5FF),
                  foregroundColor: Colors.black,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_controller == null || !_controller!.value.isInitialized) {
      return const Center(
        child: Text(
          'Camera not initialized',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    // Main camera view with QR scanner overlay
    return Stack(
      children: [
        // Camera preview (fullscreen)
        SizedBox.expand(
          child: CameraPreview(_controller!),
        ),

        // QR Scanner overlay with animations
        const QRScannerOverlay(
          viewfinderSize: 280,
          scanLineColor: Color(0x802196F3),
          bracketColor: Color(0xFF00E5FF),
        ),

        // Instruction text
        Positioned(
          left: 0,
          right: 0,
          bottom: 140,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: const Text(
              'Align within frame',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),

        // Capture button
        Positioned(
          left: 0,
          right: 0,
          bottom: 40,
          child: Center(
            child: _buildCaptureButton(),
          ),
        ),

        // Loading indicator while capturing
        if (_isCapturing)
          Container(
            color: Colors.black54,
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF00E5FF)),
                  SizedBox(height: 16),
                  Text(
                    'Processing...',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCaptureButton() {
    return GestureDetector(
      onTap: _isCapturing ? null : _captureAndReturn,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFF00E5FF),
            width: 4,
          ),
        ),
        child: Center(
          child: Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF00E5FF),
            ),
            child: _isCapturing
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(
                      color: Colors.black,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(
                    Icons.camera_alt,
                    color: Colors.black,
                    size: 28,
                  ),
          ),
        ),
      ),
    );
  }
}
