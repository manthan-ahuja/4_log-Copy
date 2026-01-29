import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  LatLng? currentLocation;
  bool isLoadingLocation = true;
  double _zoom = 13.0;

  // Mapbox API key
  static const String mapboxAccessToken =
      'pk.eyJ1IjoiZmx1dHRlci1sb2ciLCJhIjoiY21peXNucHF4MGp2aDNoczY0b2hvcjRhMCJ9.fZ-6OD0ZqO4twwvBLOdSgA';

  // Mapbox tile URL template for your custom style
  // Original style URL: mapbox://styles/flutter-log/cmkrqwd1p001f01r69enga5ly
  // HTTP tiles URL used by flutter_map:
  // https://api.mapbox.com/styles/v1/flutter-log/cmkrqwd1p001f01r69enga5ly/tiles/256/{z}/{x}/{y}?access_token=YOUR_TOKEN
  String get mapboxTileUrl =>
      'https://api.mapbox.com/styles/v1/flutter-log/cmkrqwd1p001f01r69enga5ly/tiles/256/{z}/{x}/{y}?access_token=$mapboxAccessToken';

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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Location services are disabled. Please enable them.',
              ),
            ),
          );
        }
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
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permissions are denied')),
            );
          }
          setState(() {
            isLoadingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permissions are permanently denied'),
            ),
          );
        }
        setState(() {
          isLoadingLocation = false;
        });
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
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
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error getting location: $e')));
      }
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

    return Scaffold(
      body: Stack(
        children: [
          // Map - Show immediately, don't wait for location
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: initialLocation,
              initialZoom: _zoom,
              minZoom: 3.0,
              maxZoom: 18.0,
              onTap: (tapPosition, point) {
                // Handle map tap if needed
              },
            ),
            children: [
              // Mapbox tile layer
              TileLayer(
                urlTemplate: mapboxTileUrl,
                userAgentPackageName: 'com.example.geolocation_camera',
                maxZoom: 18,
                tileProvider: NetworkTileProvider(),
                errorTileCallback: (tile, error, stackTrace) {
                  debugPrint(
                    'Tile error: $error for tile: ${tile.coordinates}',
                  );
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

          // Zoom controls
          Positioned(
            right: 16,
            top: 100,
            child: Column(
              children: [
                // Zoom in button
                FloatingActionButton(
                  mini: true,
                  heroTag: "zoomIn",
                  onPressed: _zoomIn,
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.add, color: Colors.black),
                ),
                const SizedBox(height: 8),
                // Zoom out button
                FloatingActionButton(
                  mini: true,
                  heroTag: "zoomOut",
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
            bottom: 100,
            child: FloatingActionButton(
              heroTag: "currentLocation",
              onPressed: _goToCurrentLocation,
              backgroundColor: Colors.white,
              child: const Icon(Icons.my_location, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }
}
