import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/home_screen_webview.dart';
import 'screens/gps_screen.dart';
import 'screens/camera_qr_screen.dart';
import 'screens/camera_screen.dart';
import 'screens/device_id_screen.dart';
import 'screens/network_status_screen.dart';
import 'screens/gesit_solution_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/map_destination_screen.dart';
import 'models/chat_user.dart';

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
        '/map_destination': (context) => const MapDestinationScreen(),
        '/camera': (context) => const CameraScreen(),
        '/device_id': (context) => const DeviceIdScreen(),
        '/network_status': (context) => const NetworkStatusScreen(),
        '/gesit_solution': (context) => const GesitSolutionScreen(),
        '/chat': (context) => ChatScreen(
          contact: ModalRoute.of(context)!.settings.arguments as ChatUser? ??
              const ChatUser(
                id: 'support',
                name: 'Gesit Support',
                isOnline: true,
              ),
        ),
        '/camera_qr': (context) => const CameraQRScreen(),
      },
    );
  }
}
