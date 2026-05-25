import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class MapDestinationScreen extends StatefulWidget {
  const MapDestinationScreen({super.key});

  @override
  State<MapDestinationScreen> createState() => _MapDestinationScreenState();
}

class _MapDestinationScreenState extends State<MapDestinationScreen> {
  GoogleMapController? _mapController;
  LatLng? _selectedDestination;
  LatLng _currentPosition = const LatLng(-6.2088, 106.8456); // Default: Jakarta
  bool _isLoadingLocation = true;
  bool _useDeviceLocation = true;
  final Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      // Check and request location permission
      final permission = await Permission.location.request();
      
      if (permission.isGranted) {
        // Get current position
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        
        final currentLatLng = LatLng(position.latitude, position.longitude);
        
        setState(() {
          _currentPosition = currentLatLng;
          _selectedDestination = currentLatLng;
          _useDeviceLocation = true;
          _updateMarker(currentLatLng, isCurrentLocation: true);
        });

        // Move camera to current position
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(currentLatLng, 15),
        );
      } else {
        // Permission denied, use default location
        setState(() {
          _selectedDestination = _currentPosition;
          _updateMarker(_currentPosition, isCurrentLocation: false);
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permission denied. Using default location.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      // Error getting location
      setState(() {
        _selectedDestination = _currentPosition;
        _updateMarker(_currentPosition, isCurrentLocation: false);
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error getting location: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  void _updateMarker(LatLng position, {required bool isCurrentLocation}) {
    _markers.clear();
    _markers.add(
      Marker(
        markerId: const MarkerId('destination'),
        position: position,
        icon: BitmapDescriptor.defaultMarkerWithHue(
          isCurrentLocation ? BitmapDescriptor.hueBlue : BitmapDescriptor.hueRed,
        ),
        infoWindow: InfoWindow(
          title: isCurrentLocation ? 'Current Location' : 'Selected Destination',
          snippet: '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}',
        ),
      ),
    );
  }

  void _onMapTap(LatLng position) {
    setState(() {
      _selectedDestination = position;
      _useDeviceLocation = false;
      _updateMarker(position, isCurrentLocation: false);
    });
  }

  Future<void> _resetToCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      final permission = await Permission.location.status;
      
      if (!permission.isGranted) {
        final newPermission = await Permission.location.request();
        if (!newPermission.isGranted) {
          throw Exception('Location permission is required');
        }
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      final currentLatLng = LatLng(position.latitude, position.longitude);
      
      setState(() {
        _currentPosition = currentLatLng;
        _selectedDestination = currentLatLng;
        _useDeviceLocation = true;
        _updateMarker(currentLatLng, isCurrentLocation: true);
      });

      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(currentLatLng, 15),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error getting location: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      setState(() {
        _isLoadingLocation = false;
      });
    }
  }

  void _confirmDestination() {
    if (_selectedDestination != null) {
      Navigator.pop(context, {
        'latitude': _selectedDestination!.latitude,
        'longitude': _selectedDestination!.longitude,
        'useDeviceLocation': _useDeviceLocation,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Destination'),
        actions: [
          if (_selectedDestination != null)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _confirmDestination,
              tooltip: 'Confirm Destination',
            ),
        ],
      ),
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentPosition,
              zoom: 15,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
            },
            onTap: _onMapTap,
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: true,
            mapToolbarEnabled: false,
          ),

          // Loading indicator
          if (_isLoadingLocation)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),

          // Info card at the top
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _useDeviceLocation
                              ? Icons.my_location
                              : Icons.location_on,
                          color: _useDeviceLocation
                              ? Colors.blue
                              : Colors.red,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _useDeviceLocation
                                ? 'Using Device Location'
                                : 'Custom Location Selected',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_selectedDestination != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Lat: ${_selectedDestination!.latitude.toStringAsFixed(6)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      Text(
                        'Lng: ${_selectedDestination!.longitude.toStringAsFixed(6)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                    const SizedBox(height: 8),
                    const Text(
                      'Tap anywhere on the map to set a custom destination',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Floating action buttons
          Positioned(
            bottom: 16,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Reset to current location button
                FloatingActionButton(
                  heroTag: 'reset_location',
                  onPressed: _isLoadingLocation ? null : _resetToCurrentLocation,
                  tooltip: 'Use Current Location',
                  child: const Icon(Icons.my_location),
                ),
                const SizedBox(height: 12),
                // Confirm button
                if (_selectedDestination != null)
                  FloatingActionButton.extended(
                    heroTag: 'confirm_destination',
                    onPressed: _confirmDestination,
                    icon: const Icon(Icons.check),
                    label: const Text('Confirm'),
                    backgroundColor: Colors.green,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
