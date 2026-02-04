import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MapSection extends StatefulWidget {
  const MapSection({super.key});

  @override
  State<MapSection> createState() => _MapSectionState();
}

class _MapSectionState extends State<MapSection> {
  final MapController _mapController = MapController();
  final supabase = Supabase.instance.client;

  LatLng? currentLocation;
  final double _zoom = 13;

  Timer? _friendsTimer;

  String? avatarUrl;
  String? username;
  List<Map<String, dynamic>> friendsLocations = [];

  String? _selectedUserId;

  String get myId => supabase.auth.currentUser!.id;

  static const mapboxToken =
      'pk.eyJ1IjoiZmx1dHRlci1sb2ciLCJhIjoiY21reTlldGphMDNqdTNkcjBub3E1Ym5hdCJ9.lJOm6O5jAdmnLlyvLZ7afg';

  String get tileUrl =>
      'https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/256/{z}/{x}/{y}?access_token=$mapboxToken';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await Permission.location.request();
    await _loadProfile();
    await _refreshLocation();
    _startFriendsPolling();
  }

  // -------- PROFILE --------
  Future<void> _loadProfile() async {
    final me = await supabase
        .from('User')
        .select('avatar_url, username')
        .eq('user_id', myId)
        .maybeSingle();

    setState(() {
      avatarUrl = me?['avatar_url'];
      username = me?['username'];
    });
  }

  // -------- LOCATION --------
  Future<void> _refreshLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) return;

    LocationPermission p = await Geolocator.checkPermission();
    if (p == LocationPermission.denied) {
      p = await Geolocator.requestPermission();
    }
    if (p == LocationPermission.denied || p == LocationPermission.deniedForever)
      return;

    final pos = await Geolocator.getCurrentPosition();
    await _update(pos, moveMap: true);
  }

  Future<void> _update(Position p, {bool moveMap = false}) async {
    final ll = LatLng(p.latitude, p.longitude);
    setState(() => currentLocation = ll);

    if (moveMap) {
      _mapController.move(ll, _zoom);
    }

    await supabase.from('user_location').upsert({
      'user_id': myId,
      'latitude': p.latitude,
      'longitude': p.longitude,
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'user_id');
  }

  // -------- FRIENDS --------
  void _startFriendsPolling() {
    _fetchFriends();
    _friendsTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _fetchFriends(),
    );
  }

  Future<void> _fetchFriends() async {
    try {
      final a = await supabase
          .from('friendship')
          .select('receiver_id')
          .eq('sender_id', myId)
          .eq('status', 'accepted');

      final b = await supabase
          .from('friendship')
          .select('sender_id')
          .eq('receiver_id', myId)
          .eq('status', 'accepted');

      final ids = <String>{
        ...a.map((e) => e['receiver_id'] as String),
        ...b.map((e) => e['sender_id'] as String),
      };

      if (ids.isEmpty) {
        setState(() => friendsLocations = []);
        return;
      }

      final locations = await supabase
          .from('user_location')
          .select('user_id, latitude, longitude')
          .inFilter('user_id', ids.toList());

      final users = await supabase
          .from('User')
          .select('user_id, avatar_url, username')
          .inFilter('user_id', ids.toList());

      final userMap = {
        for (final u in users)
          u['user_id']: {'avatar': u['avatar_url'], 'username': u['username']},
      };

      final merged = locations.map((e) {
        final u = userMap[e['user_id']];
        return {...e, 'avatar': u?['avatar'], 'username': u?['username']};
      }).toList();

      setState(() => friendsLocations = merged);
    } catch (e) {
      debugPrint('Friends fetch error: $e');
    }
  }

  // -------- UI HELPERS --------
  ImageProvider? _avatarProvider(String? url) {
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('http')) return NetworkImage(url);
    return AssetImage(url);
  }

  Widget _nameBubble(String name) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        name,
        style: const TextStyle(color: Colors.white, fontSize: 12),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  // -------- MAP --------
  Widget _mapWidget() {
    final center = currentLocation ?? const LatLng(37.7749, -122.4194);

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: _zoom,
        onTap: (_, __) => setState(() => _selectedUserId = null),
      ),
      children: [
        TileLayer(urlTemplate: tileUrl, userAgentPackageName: 'geo.app'),
        MarkerLayer(
          markers: [
            if (currentLocation != null)
              Marker(
                point: currentLocation!,
                width: 140,
                height: 70,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedUserId = _selectedUserId == myId ? null : myId;
                    });
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_selectedUserId == myId)
                        _nameBubble(username ?? 'You'),
                      CircleAvatar(
                        radius: 20,
                        backgroundImage: _avatarProvider(avatarUrl),
                        child: avatarUrl == null
                            ? const Icon(Icons.person)
                            : null,
                      ),
                    ],
                  ),
                ),
              ),

            ...friendsLocations.map((e) {
              final lat = e['latitude'];
              final lng = e['longitude'];
              if (lat == null || lng == null) return null;

              return Marker(
                point: LatLng(lat, lng),
                width: 140,
                height: 60,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedUserId = _selectedUserId == e['user_id']
                          ? null
                          : e['user_id'];
                    });
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_selectedUserId == e['user_id'])
                        _nameBubble(e['username'] ?? 'Friend'),
                      CircleAvatar(
                        radius: 14,
                        backgroundImage: _avatarProvider(e['avatar']),
                        child: e['avatar'] == null
                            ? const Icon(Icons.person, size: 16)
                            : null,
                      ),
                    ],
                  ),
                ),
              );
            }).whereType<Marker>(),
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    _friendsTimer?.cancel();
    super.dispose();
  }

  // -------- BUILD --------
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _mapWidget(),
        Positioned(
          top: 16,
          left: 16,
          right: 60,
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Row(
              children: [
                Icon(Icons.search),
                SizedBox(width: 8),
                Text('Search'),
              ],
            ),
          ),
        ),
        Positioned(
          top: 16,
          right: 16,
          child: FloatingActionButton(
            mini: true,
            onPressed: _refreshLocation,
            child: const Icon(Icons.my_location),
          ),
        ),
      ],
    );
  }
}
