import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Singleton service that acts as a message hub between JavaScript (WebView) and Flutter.
///
/// Usage:
/// 1. Call [registerController] from HomeScreen after WebView initialization
/// 2. JavaScriptChannel receives messages and calls [handleMessage]
/// 3. [handleMessage] opens the appropriate Flutter screen via Navigator
/// 4. When the screen returns data, [sendResult] sends it back to the WebView via evaluateJavascript
class BridgeService {
  static final BridgeService _instance = BridgeService._internal();
  factory BridgeService() => _instance;
  BridgeService._internal();

  WebViewController? _controller;
  BuildContext? _context;

  /// Register the WebViewController after the WebView is initialized.
  void registerController(WebViewController controller, BuildContext context) {
    _controller = controller;
    _context = context;
  }

  /// Handle incoming messages from JavaScript.
  /// Returns a Future<String?> with the result from the Flutter screen.
  Future<String?> handleMessage(String action) async {
    if (_context == null) {
      return jsonEncode({'error': 'Context not available'});
    }

    String? result;

    switch (action) {
      case 'gesit_solution':
        // Use pushReplacement to avoid having two WebViewControllers alive
        // simultaneously on the navigation stack. Each WebViewController registers
        // singleton Pigeon message handlers. When a second WebView replaces the
        // first's handler, stale messages from the native side cause:
        //   "Null check operator used on a null value" at args[0]!
        // Replacing the route ensures HomeScreenWebView is disposed (clearing
        // its Pigeon handlers) before GesitSolutionScreen registers its own.
        result = await _navigateAndReplace('/$action');
        break;
      case 'camera_qr':
      case 'chat':
      case 'map_destination':
        result = await _navigateAndWait('/$action');
        break;
      default:
        return jsonEncode({'error': 'Unknown action: $action'});
    }

    // Send result back to WebView
    if (result != null && _controller != null) {
      final escapedResult = _escapeJsonForJs(result);
      await _controller!.runJavaScript('receiveFromFlutter($escapedResult)');
    }

    return result;
  }

  /// Navigate to a route and wait for the result.
  Future<String?> _navigateAndWait(String route) async {
    if (_context == null) return null;
    
    final result = await Navigator.pushNamed(
      _context!,
      route,
    );
    
    // Cast the result to String?
    return jsonEncode(result) as String?;
  }

  /// Navigate to a route by replacing the current route and wait for the result.
  /// This is used for routes that create their own WebViewController (like
  /// GesitSolutionScreen) to avoid having two WebViewControllers alive
  /// simultaneously, which causes Pigeon channel handler conflicts.
  Future<String?> _navigateAndReplace(String route) async {
    if (_context == null) return null;

    // Clear the controller reference — the current WebView is being replaced
    // and its controller will be disposed. The new screen manages its own
    // WebViewController internally.
    _controller = null;

    final result = await Navigator.pushReplacementNamed(
      _context!,
      route,
    );

    return jsonEncode(result) as String?;
  }

  /// Escape a JSON string for use in JavaScript.
  String _escapeJsonForJs(String jsonStr) {
    // Replace backslash first, then quotes, then newlines/tabs
    return "'${jsonStr.replaceAll('\\', '\\\\').replaceAll("'", "\\'").replaceAll('\n', '\\n').replaceAll('\t', '\\t')}'";
  }

  /// Send a result directly to the WebView (alternative method).
  Future<void> sendResult(Map<String, dynamic> data) async {
    if (_controller == null) return;
    
    final jsonStr = jsonEncode(data);
    final escapedResult = _escapeJsonForJs(jsonStr);
    await _controller!.runJavaScript('receiveFromFlutter($escapedResult)');
  }
}