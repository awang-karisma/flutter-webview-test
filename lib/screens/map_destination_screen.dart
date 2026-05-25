import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
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
  bool _isLoadingLocation = false;
  bool _isLoadingAddress = false;
  String _selectedAddress = 'Memuat alamat...';
  final Set<Marker> _markers = {};
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Set default location immediately to avoid freezing
    _selectedDestination = _currentPosition;
    _updateMarker(_currentPosition, isCurrentLocation: false);
    _getAddressFromLatLng(_currentPosition);
    // Initialize location asynchronously
    Future.microtask(() => _initializeLocation());
  }

  Future<void> _initializeLocation() async {
    if (!mounted) return;

    setState(() {
      _isLoadingLocation = true;
    });

    try {
      // Check location service status first
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled');
      }

      // Check and request location permission
      final permission = await Permission.location.request();

      if (permission.isGranted) {
        // Get current position with timeout
        final position =
            await Geolocator.getCurrentPosition(
              locationSettings: LocationSettings(
                accuracy: LocationAccuracy.high,
                timeLimit: const Duration(seconds: 10),
              ),
            ).timeout(
              const Duration(seconds: 10),
              onTimeout: () {
                throw Exception('Location request timed out');
              },
            );

        if (!mounted) return;

        final currentLatLng = LatLng(position.latitude, position.longitude);

        setState(() {
          _currentPosition = currentLatLng;
          _selectedDestination = currentLatLng;
          _updateMarker(currentLatLng, isCurrentLocation: true);
        });

        // Get address for current location
        _getAddressFromLatLng(currentLatLng);

        // Move camera to current position
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(currentLatLng, 15),
        );
      }
    } catch (e) {
      // Error getting location - already have default set
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not get location: ${e.toString()}'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
  }

  Future<void> _getAddressFromLatLng(LatLng position) async {
    setState(() {
      _isLoadingAddress = true;
      _selectedAddress = 'Memuat alamat...';
    });

    try {
      final placemarks =
          await placemarkFromCoordinates(
            position.latitude,
            position.longitude,
          ).timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              throw Exception('Timeout');
            },
          );

      if (placemarks.isNotEmpty && mounted) {
        final place = placemarks.first;
        final addressParts = <String>[];

        // Build address from most specific to least specific
        if (place.name != null &&
            place.name!.isNotEmpty &&
            place.name != place.street) {
          addressParts.add(place.name!);
        }
        if (place.street != null && place.street!.isNotEmpty) {
          addressParts.add(place.street!);
        }
        if (place.subLocality != null && place.subLocality!.isNotEmpty) {
          addressParts.add(place.subLocality!);
        }
        if (place.locality != null && place.locality!.isNotEmpty) {
          addressParts.add(place.locality!);
        }
        if (place.subAdministrativeArea != null &&
            place.subAdministrativeArea!.isNotEmpty &&
            place.subAdministrativeArea != place.locality) {
          addressParts.add(place.subAdministrativeArea!);
        }
        if (place.administrativeArea != null &&
            place.administrativeArea!.isNotEmpty) {
          addressParts.add(place.administrativeArea!);
        }
        if (place.country != null && place.country!.isNotEmpty) {
          addressParts.add(place.country!);
        }
        if (place.postalCode != null && place.postalCode!.isNotEmpty) {
          addressParts.add(place.postalCode!);
        }

        final address = addressParts.isNotEmpty
            ? addressParts.join(', ')
            : 'Koordinat: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';

        setState(() {
          _selectedAddress = address;
        });
      } else {
        if (mounted) {
          setState(() {
            _selectedAddress =
                'Koordinat: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _selectedAddress =
              'Koordinat: ${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
        });

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat alamat: ${e.toString()}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingAddress = false;
        });
      }
    }
  }

  void _updateMarker(LatLng position, {required bool isCurrentLocation}) {
    _markers.clear();
    _markers.add(
      Marker(
        markerId: const MarkerId('destination'),
        position: position,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    );
  }

  void _onMapTap(LatLng position) {
    setState(() {
      _selectedDestination = position;
      _updateMarker(position, isCurrentLocation: false);
    });
    _getAddressFromLatLng(position);
  }

  Future<void> _resetToCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      // Check location service status first
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception(
          'Location services are disabled. Please enable location in settings.',
        );
      }

      final permission = await Permission.location.status;

      if (!permission.isGranted) {
        final newPermission = await Permission.location.request();
        if (!newPermission.isGranted) {
          throw Exception('Location permission is required');
        }
      }

      final position =
          await Geolocator.getCurrentPosition(
            locationSettings: LocationSettings(accuracy: LocationAccuracy.high, timeLimit: const Duration(seconds: 10)),
          ).timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Location request timed out');
            },
          );

      if (!mounted) return;

      final currentLatLng = LatLng(position.latitude, position.longitude);

      setState(() {
        _currentPosition = currentLatLng;
        _selectedDestination = currentLatLng;
        _updateMarker(currentLatLng, isCurrentLocation: true);
      });

      _getAddressFromLatLng(currentLatLng);

      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(currentLatLng, 15),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
  }

  Future<void> _searchAddress() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      _isLoadingLocation = true;
    });

    try {
      final locations = await locationFromAddress(query).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Search timeout'),
      );

      if (locations.isNotEmpty && mounted) {
        final location = locations.first;
        final searchLatLng = LatLng(location.latitude, location.longitude);

        setState(() {
          _selectedDestination = searchLatLng;
          _updateMarker(searchLatLng, isCurrentLocation: false);
        });

        _getAddressFromLatLng(searchLatLng);

        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(searchLatLng, 15),
        );

        // Hide keyboard
        FocusScope.of(context).unfocus();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Alamat tidak ditemukan: ${e.toString()}'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
  }

  void _confirmDestination() {
    if (_selectedDestination != null) {
      final data = {
        'latitude': _selectedDestination!.latitude,
        'longitude': _selectedDestination!.longitude,
        'altitude': 0.0,
        'speed': 0.0,
        'accuracy': 0.0,
        'timestamp': DateTime.now().toIso8601String(),
        'address': _selectedAddress,
      };
      Navigator.pop(context, jsonEncode(data));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pilih Lokasi'), elevation: 0),
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
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),

          // Search box at the top
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: 'Cari alamat...',
                          border: InputBorder.none,
                        ),
                        onSubmitted: (_) => _searchAddress(),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          // My location button
          Positioned(
            top: 80,
            right: 16,
            child: FloatingActionButton.small(
              heroTag: 'my_location',
              onPressed: _isLoadingLocation ? null : _resetToCurrentLocation,
              tooltip: 'Lokasi Saya',
              child: const Icon(Icons.my_location),
            ),
          ),

          // Bottom section with address and button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(25),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Alamat Terpilih:',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _isLoadingAddress
                          ? const Row(
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text('Memuat alamat...'),
                              ],
                            )
                          : Text(
                              _selectedAddress,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isLoadingAddress
                              ? null
                              : _confirmDestination,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF667eea),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Gunakan Lokasi Ini',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Loading overlay
          if (_isLoadingLocation)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _searchController.dispose();
    super.dispose();
  }
}
