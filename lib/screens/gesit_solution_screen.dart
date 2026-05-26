import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as image;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart' as webview_flutter_android;
import 'package:path_provider/path_provider.dart';

import 'camera_qr_screen.dart';

/// Screen that opens https://app.gesitsolution.com in a WebView.
class GesitSolutionScreen extends StatefulWidget {
  const GesitSolutionScreen({super.key});

  @override
  State<GesitSolutionScreen> createState() => _GesitSolutionScreenState();
}

class _GesitSolutionScreenState extends State<GesitSolutionScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  String _currentUrl = '';
  String _currentPath = '';
  String _currentQuery = '';

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  Future<List<String>> _androidFilePicker(webview_flutter_android.FileSelectorParams params) async {
    if (params.acceptTypes.any((type) => type == 'image/*')) {
      if (!mounted) return [];

      final result = await Navigator.push<String>(
        context,
        MaterialPageRoute(builder: (context) => const CameraQRScreen()),
      );

      if (!mounted || result == null) {
        return [];
      }

      final data = jsonDecode(result) as Map<String, dynamic>;
      final imagePath = data['imagePath'] as String?;

      if (imagePath == null || imagePath.isEmpty) {
        return [];
      }

      final imageData = await File(imagePath).readAsBytes();
      final decodedImage = image.decodeImage(imageData);
      if (decodedImage == null) {
        return [];
      }
      final scaledImage = image.copyResize(decodedImage, width: 500);
      final jpg = image.encodeJpg(scaledImage, quality: 90);

      final filePath = (await getTemporaryDirectory()).uri.resolve(
            './image_${DateTime.now().microsecondsSinceEpoch}.jpg',
          );
      final file = await File.fromUri(filePath).create(recursive: true);
      await file.writeAsBytes(jpg, flush: true);

      return [file.uri.toString()];
    }

    return [];
  }

  Future<void> _initWebView() async {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onUrlChange: (UrlChange url) async {
            _currentUrl = url.url ?? '';
            final current = Uri.parse(_currentUrl);
            _currentPath = current.path;
            _currentQuery = current.queryParameters['category'] ?? '';
            if (_currentPath.startsWith('/customer/form') && _currentQuery == '3') {
              // Navigate to camera and wait for result
              await Navigator.pushNamed(context, '/camera_qr');
              // When camera screen closes (either by capture or back button),
              // go back one step in the WebView
              if (mounted) {
                await _controller.goBack();
              }
              return;
            }
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('WebView error: ${error.description}');
          },
        ),
      )
      ..addJavaScriptChannel(
        'FlutterChannel',
        onMessageReceived: (JavaScriptMessage message) async {
          debugPrint('FlutterChannel message: ${message.message}');
          if (message.message == 'requestGPS') {
            final result = await Navigator.pushNamed(context, '/map_destination');
            if (result != null && mounted) {
              await _controller.runJavaScript(
                "window.flutterGpsCallback && window.flutterGpsCallback($result)",
              );
            }
          }
        },
      )
      ..loadRequest(Uri.parse('https://app.gesitsolution.com'));

    if (Platform.isAndroid) {
      final controller = (_controller.platform as webview_flutter_android.AndroidWebViewController);
      controller.setOnShowFileSelector(_androidFilePicker);
    }
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null,
      body: Padding(
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
        child: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(color: Color(0xFF667eea)),
              ),
          ],
        ),
      ),
    );
  }
}
