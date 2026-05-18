import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Network status screen that displays network connectivity information.
class NetworkStatusScreen extends StatefulWidget {
  const NetworkStatusScreen({super.key});

  @override
  State<NetworkStatusScreen> createState() => _NetworkStatusScreenState();
}

class _NetworkStatusScreenState extends State<NetworkStatusScreen> {
  bool _isLoading = true;
  Map<String, String> _networkData = {};
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _getNetworkStatus();
  }

  Future<void> _getNetworkStatus() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final connectivity = Connectivity();
      
      // Check connectivity
      final results = await connectivity.checkConnectivity();
      final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
      
      String connectionType;
      switch (result) {
        case ConnectivityResult.wifi:
          connectionType = 'WiFi';
          break;
        case ConnectivityResult.mobile:
          connectionType = 'Mobile (Cellular)';
          break;
        case ConnectivityResult.ethernet:
          connectionType = 'Ethernet';
          break;
        case ConnectivityResult.bluetooth:
          connectionType = 'Bluetooth';
          break;
        case ConnectivityResult.vpn:
          connectionType = 'VPN';
          break;
        case ConnectivityResult.none:
          connectionType = 'No Connection';
          break;
        default:
          connectionType = 'Unknown';
      }

      final networkData = <String, String>{
        'connectionType': connectionType,
      };

      if (!mounted) return;
      setState(() {
        _networkData = networkData;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to get network status: $e';
      });
    }
  }

  void _submitData() {
    Navigator.pop(context, jsonEncode(_networkData));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Network Status'),
        backgroundColor: const Color(0xFF9C27B0),
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
            CircularProgressIndicator(color: Color(0xFF9C27B0)),
            SizedBox(height: 16),
            Text('Checking network status...'),
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
              const Icon(Icons.wifi_off, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _getNetworkStatus,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9C27B0),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _networkData.length,
            itemBuilder: (context, index) {
              final key = _networkData.keys.elementAt(index);
              final value = _networkData[key]!;
              return _buildDataCard(key, value);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _submitData,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9C27B0),
                foregroundColor: Colors.white,
              ),
              child: const Text('Submit', style: TextStyle(fontSize: 18)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDataCard(String label, String value) {
    // Format the label for display
    String displayLabel = label;
    if (label == 'wifiName') {
      displayLabel = 'WiFi Name (SSID)';
    } else if (label == 'wifiBSSID') {
      displayLabel = 'WiFi BSSID';
    } else if (label == 'connectionType') {
      displayLabel = 'Connection Type';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(
          displayLabel,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(value, style: const TextStyle(fontSize: 14)),
        leading: Icon(
          _getIconForLabel(label),
          color: const Color(0xFF9C27B0),
        ),
      ),
    );
  }

  IconData _getIconForLabel(String label) {
    switch (label) {
      case 'connectionType':
        return Icons.wifi;
      case 'wifiName':
        return Icons.wifi_find;
      case 'wifiBSSID':
        return Icons.router;
      default:
        return Icons.info;
    }
  }
}