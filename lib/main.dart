import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/home_screen_webview.dart';
import 'screens/gps_screen.dart';
import 'screens/camera_screen.dart';
import 'screens/device_id_screen.dart';
import 'screens/network_status_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'WebView Bridge Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF667eea)),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
      routes: {
        '/home': (context) => const HomeScreen(),
        '/home_webview': (context) => const HomeScreenWebView(),
        '/gps': (context) => const GpsScreen(),
        '/camera': (context) => const CameraScreen(),
        '/device_id': (context) => const DeviceIdScreen(),
        '/network_status': (context) => const NetworkStatusScreen(),
      },
    );
  }
}
