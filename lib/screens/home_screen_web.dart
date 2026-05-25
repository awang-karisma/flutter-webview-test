import 'package:flutter/material.dart';
import '../models/chat_user.dart';

/// Web fallback home screen with native Flutter buttons (for Web platform).
/// This is used when running on Flutter Web where WebView is not available.
class HomeScreenWeb extends StatelessWidget {
  const HomeScreenWeb({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WebView Bridge Demo'),
        backgroundColor: const Color(0xFF667eea),
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                const SizedBox(height: 20),
                const Text(
                  'WebView Bridge Demo',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 40),
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 15,
                    mainAxisSpacing: 15,
                    children: [
                      _buildButton(
                        context,
                        icon: Icons.location_on,
                        label: 'GPS',
                        color: const Color(0xFF4CAF50),
                        onTap: () => Navigator.pushNamed(context, '/gps'),
                      ),
                      _buildButton(
                        context,
                        icon: Icons.camera_alt,
                        label: 'Camera',
                        color: const Color(0xFF2196F3),
                        onTap: () => Navigator.pushNamed(context, '/camera'),
                      ),
                      _buildButton(
                        context,
                        icon: Icons.phone_android,
                        label: 'Device ID',
                        color: const Color(0xFFFF9800),
                        onTap: () => Navigator.pushNamed(context, '/device_id'),
                      ),
                      _buildButton(
                        context,
                        icon: Icons.wifi,
                        label: 'Network',
                        color: const Color(0xFF9C27B0),
                        onTap: () => Navigator.pushNamed(context, '/network_status'),
                      ),
                      _buildButton(
                        context,
                        icon: Icons.chat,
                        label: 'Chat',
                        color: const Color(0xFF00BCD4),
                        onTap: () => Navigator.pushNamed(
                          context,
                          '/chat',
                          arguments: const ChatUser(
                            id: 'support',
                            name: 'Gesit Support',
                            isOnline: true,
                          ),
                        ),
                      ),
                      _buildButton(
                        context,
                        icon: Icons.map,
                        label: 'Map Destination',
                        color: const Color(0xFFE91E63),
                        onTap: () async {
                          final result = await Navigator.pushNamed(context, '/map_destination');
                          if (result != null && context.mounted) {
                            final data = result as Map<String, dynamic>;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Destination: ${data['latitude']}, ${data['longitude']}\n'
                                  'Using device location: ${data['useDeviceLocation']}',
                                ),
                                duration: const Duration(seconds: 3),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Colors.white),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
