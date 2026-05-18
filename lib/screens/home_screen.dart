import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'home_screen_web.dart';
import 'home_screen_webview.dart';

/// Main home screen that shows WebView on Android/Windows, native Flutter buttons on Web.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Use WebView on Android/Windows, native Flutter UI on Web
    if (kIsWeb) {
      return const HomeScreenWeb();
    } else if (Platform.isAndroid || Platform.isWindows) {
      return const HomeScreenWebView();
    } else {
      // Fallback for other platforms
      return const HomeScreenWeb();
    }
  }
}