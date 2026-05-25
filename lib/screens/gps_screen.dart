import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

/// GPS screen that requests location permission and displays GPS data.
class GpsScreen extends StatefulWidget {
  const GpsScreen({super.key});

  @override
  State<GpsScreen> createState() => _GpsScreenState();
}

class _GpsScreenState extends State<GpsScreen> {
  bool _isLoading = true;
  bool _hasPermission = false;
  Position? _position;
  String? _errorMessage;
  bool _allowPop = false;

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
  }

  Future<void> _requestLocationPermission() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Check if location service is enabled
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _isLoading = false;
        _hasPermission = false;
        _errorMessage = 'Location services are disabled. Please enable them in settings.';
      });
      return;
    }

    // Request permission
    var status = await Permission.location.request();
    
    if (!mounted) return;
    
    if (status.isGranted) {
      setState(() {
        _hasPermission = true;
      });
      await _getLocation();
    } else if (status.isPermanentlyDenied) {
      setState(() {
        _isLoading = false;
        _hasPermission = false;
        _errorMessage = 'Location permission permanently denied. Please enable in app settings.';
      });
    } else {
      setState(() {
        _isLoading = false;
        _hasPermission = false;
        _errorMessage = 'Location permission denied.';
      });
    }
  }

  Future<void> _getLocation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _position = null;
    });

    try {
      // Use getPositionStream().first to force a fresh GPS fix
      // instead of returning a cached location.
      final position = await Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 0,
        ),
      ).first.timeout(const Duration(seconds: 15));

      if (mounted) {
        setState(() {
          _position = position;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to get location: $e';
        });
      }
    }
  }

  void _submitData() {
    if (_position == null) return;

    final data = {
      'latitude': _position!.latitude,
      'longitude': _position!.longitude,
      'altitude': _position!.altitude,
      'speed': _position!.speed,
      'accuracy': _position!.accuracy,
      'timestamp': _position!.timestamp.toIso8601String(),
    };

    _allowPop = true;
    Navigator.pop(context, jsonEncode(data));
  }

  void _returnError() {
    if (_errorMessage == null) return;

    final data = {'error': _errorMessage};
    _allowPop = true;
    Navigator.pop(context, jsonEncode(data));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _allowPop,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) return;
        if (_errorMessage != null) {
          _returnError();
        } else {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('GPS'),
          backgroundColor: const Color(0xFF4CAF50),
          foregroundColor: Colors.white,
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Color(0xFF4CAF50)),
            SizedBox(height: 16),
            Text('Getting location...'),
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
              const Icon(Icons.location_off, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _requestLocationPermission,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _returnError,
                child: const Text('Back'),
              ),
            ],
          ),
        ),
      );
    }

    if (_position == null) {
      return const Center(child: Text('No location data available'));
    }

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildDataCard('Latitude', _position!.latitude.toString()),
              _buildDataCard('Longitude', _position!.longitude.toString()),
              _buildDataCard('Altitude', '${_position!.altitude.toStringAsFixed(2)} m'),
              _buildDataCard('Speed', '${_position!.speed.toStringAsFixed(2)} m/s'),
              _buildDataCard('Accuracy', '${_position!.accuracy.toStringAsFixed(2)} m'),
              _buildDataCard('Timestamp', _position!.timestamp.toString()),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _getLocation,
                    icon: const Icon(Icons.refresh),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                    ),
                    label: const Text('Refresh', style: TextStyle(fontSize: 18)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _submitData,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
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

  Widget _buildDataCard(String label, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: Text(value, style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}