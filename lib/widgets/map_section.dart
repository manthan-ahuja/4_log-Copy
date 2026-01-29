import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class MapSection extends StatefulWidget {
  const MapSection({super.key});

  @override
  State<MapSection> createState() => _MapSectionState();
}

class _MapSectionState extends State<MapSection> {
  final MapController _mapController = MapController();
  LatLng? currentLocation;
  bool isLoadingLocation = true;
  double _zoom = 13.0;

  // Mapbox API key
  static const String mapboxAccessToken =
      'pk.eyJ1IjoiZmx1dHRlci1sb2ciLCJhIjoiY21reTlldGphMDNqdTNkcjBub3E1Ym5hdCJ9.lJOm6O5jAdmnLlyvLZ7afg';

  // Mapbox tile URL template
  // Testing with default style first - if this works, we'll switch back to custom style
  // Custom style: 'https://api.mapbox.com/styles/v1/flutter-log/cmkrqwd1p001f01r69enga5ly/tiles/{z}/{x}/{y}?access_token=$mapboxAccessToken'
  String get mapboxTileUrl =>
      'https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/{z}/{x}/{y}?access_token=$mapboxAccessToken';

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
    _getCurrentLocation();
  }

  Future<void> _requestLocationPermission() async {
    final status = await Permission.location.request();
    if (status.isDenied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Location permission is required to show your current location',
            ),
          ),
        );
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          isLoadingLocation = false;
        });
        return;
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            isLoadingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          isLoadingLocation = false;
        });
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      setState(() {
        currentLocation = LatLng(position.latitude, position.longitude);
        isLoadingLocation = false;
      });

      // Move camera to current location
      if (currentLocation != null) {
        _mapController.move(currentLocation!, _zoom);
      }
    } catch (e) {
      setState(() {
        isLoadingLocation = false;
        // Default location if we can't get current location
        currentLocation = const LatLng(37.7749, -122.4194); // San Francisco
      });
    }
  }

  void _zoomIn() {
    setState(() {
      _zoom = (_zoom + 1).clamp(3.0, 18.0);
    });
    if (currentLocation != null) {
      _mapController.move(currentLocation!, _zoom);
    } else {
      _mapController.move(_mapController.camera.center, _zoom);
    }
  }

  void _zoomOut() {
    setState(() {
      _zoom = (_zoom - 1).clamp(3.0, 18.0);
    });
    if (currentLocation != null) {
      _mapController.move(currentLocation!, _zoom);
    } else {
      _mapController.move(_mapController.camera.center, _zoom);
    }
  }

  void _goToCurrentLocation() async {
    await _getCurrentLocation();
    if (currentLocation != null) {
      _mapController.move(currentLocation!, _zoom);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Default location if we haven't loaded yet
    final initialLocation = currentLocation ?? const LatLng(37.7749, -122.4194);

    return Stack(
      children: [
        // Map - Show immediately, don't wait for location
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: initialLocation,
            initialZoom: _zoom,
            minZoom: 3.0,
            maxZoom: 18.0,
          ),
          children: [
            // Mapbox tile layer
            TileLayer(
              urlTemplate: mapboxTileUrl,
              userAgentPackageName: 'com.example.geolocation_camera',
              maxZoom: 18,
              tileProvider: NetworkTileProvider(),
              errorTileCallback: (tile, error, stackTrace) {
                debugPrint('Tile error: $error for tile: ${tile.coordinates}');
                debugPrint('Stack trace: $stackTrace');
              },
            ),
            // Current location marker
            if (currentLocation != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: currentLocation!,
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.red,
                      size: 40,
                    ),
                  ),
                ],
              ),
          ],
        ),

        // Loading indicator overlay (only show if loading location)
        if (isLoadingLocation)
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
          ),

        // Search bar overlay
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: const [
                Icon(Icons.search),
                SizedBox(width: 8),
                Text('Search'),
              ],
            ),
          ),
        ),

        // Zoom controls
        Positioned(
          right: 16,
          top: 80,
          child: Column(
            children: [
              // Zoom in button
              FloatingActionButton(
                mini: true,
                heroTag: "zoomInMapSection",
                onPressed: _zoomIn,
                backgroundColor: Colors.white,
                child: const Icon(Icons.add, color: Colors.black),
              ),
              const SizedBox(height: 8),
              // Zoom out button
              FloatingActionButton(
                mini: true,
                heroTag: "zoomOutMapSection",
                onPressed: _zoomOut,
                backgroundColor: Colors.white,
                child: const Icon(Icons.remove, color: Colors.black),
              ),
            ],
          ),
        ),

        // Current location button
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton(
            mini: true,
            heroTag: "currentLocationMapSection",
            onPressed: _goToCurrentLocation,
            backgroundColor: Colors.white,
            child: const Icon(Icons.my_location, color: Colors.black),
          ),
        ),
      ],
    );
  }
}
