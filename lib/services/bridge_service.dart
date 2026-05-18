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
      case 'gps':
        result = await _navigateAndWait('/gps');
        break;
      case 'camera':
        result = await _navigateAndWait('/camera');
        break;
      case 'device_id':
        result = await _navigateAndWait('/device_id');
        break;
      case 'network_status':
        result = await _navigateAndWait('/network_status');
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
    return result as String?;
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