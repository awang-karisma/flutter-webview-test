import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

/// Camera screen that requests camera permission and allows taking pictures.
class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isLoading = true;
  bool _hasPermission = false;
  String? _errorMessage;
  XFile? _capturedImage;
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

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized || _isCapturing) {
      return;
    }

    if (!mounted) return;
    setState(() {
      _isCapturing = true;
    });

    try {
      final image = await _controller!.takePicture();
      if (!mounted) return;
      setState(() {
        _capturedImage = image;
        _isCapturing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isCapturing = false;
        _errorMessage = 'Failed to take picture: $e';
      });
    }
  }

  void _retake() {
    setState(() {
      _capturedImage = null;
    });
  }

  Future<void> _submitData() async {
    if (_capturedImage == null) return;

    try {
      // Read the image file and convert to base64
      final bytes = await _capturedImage!.readAsBytes();
      final base64Image = base64Encode(bytes);
      
      // Get the temporary directory to store the image path
      final tempDir = await getTemporaryDirectory();
      final fileName = 'captured_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedPath = '${tempDir.path}/$fileName';
      
      // Copy the image to temp directory
      await File(_capturedImage!.path).copy(savedPath);

      final data = {
        'imagePath': savedPath,
        'imageBase64': base64Image,
        'timestamp': DateTime.now().toIso8601String(),
      };

      if (mounted) {
        Navigator.pop(context, jsonEncode(data));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to process image: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Camera'),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
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
            CircularProgressIndicator(color: Color(0xFF2196F3)),
            SizedBox(height: 16),
            Text('Initializing camera...'),
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
              const Icon(Icons.camera_alt_outlined, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _requestCameraPermission,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2196F3),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Show captured image preview
    if (_capturedImage != null) {
      return Column(
        children: [
          Expanded(
            child: Image.file(
              File(_capturedImage!.path),
              fit: BoxFit.contain,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: OutlinedButton(
                      onPressed: _retake,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF2196F3),
                      ),
                      child: const Text('Retake', style: TextStyle(fontSize: 18)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _submitData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2196F3),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Submit', style: TextStyle(fontSize: 18)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // Show camera preview
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Center(child: Text('Camera not initialized'));
    }

    return Column(
      children: [
        Expanded(
          child: CameraPreview(_controller!),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: SizedBox(
            width: 70,
            height: 70,
            child: ElevatedButton(
              onPressed: _isCapturing ? null : _takePicture,
              style: ElevatedButton.styleFrom(
                shape: const CircleBorder(),
                backgroundColor: const Color(0xFF2196F3),
                foregroundColor: Colors.white,
                padding: EdgeInsets.zero,
              ),
              child: _isCapturing
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Icon(Icons.camera_alt, size: 30),
            ),
          ),
        ),
      ],
    );
  }
}