import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../services/bridge_service.dart';

/// Home screen with WebView that loads local HTML asset.
class HomeScreenWebView extends StatefulWidget {
  const HomeScreenWebView({super.key});

  @override
  State<HomeScreenWebView> createState() => _HomeScreenWebViewState();
}

class _HomeScreenWebViewState extends State<HomeScreenWebView> {
  late final WebViewController _controller;
  final BridgeService _bridgeService = BridgeService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  Future<void> _initWebView() async {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF667eea))
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
          onWebResourceError: (WebResourceError error) {
            debugPrint('WebView error: ${error.description}');
          },
        ),
      )
      ..addJavaScriptChannel(
        'FlutterBridge',
        onMessageReceived: (JavaScriptMessage message) async {
          final action = message.message;
          debugPrint('Received message from JS: $action');
          
          // Handle the message and get result from Flutter screen
          final result = await _bridgeService.handleMessage(action);
          
          // Result is already sent back to WebView in handleMessage
          debugPrint('Result sent back to WebView');
        },
      );

    // Load the local HTML asset
    await _controller.loadFlutterAsset('assets/web/index.html');
    
    // Register the controller with BridgeService
    _bridgeService.registerController(_controller, context);
    
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: null, // No app bar for fullscreen
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF667eea),
              ),
            ),
        ],
      ),
    );
  }
}