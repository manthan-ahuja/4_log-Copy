import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../screens/camera_screen.dart';

class CardSection extends StatelessWidget {
  const CardSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CameraScreen(),
                  ),
                );
              },
              child: const _LiveCameraGlassCard(),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 1,
            child: _buildCard(),
          ),
        ],
      ),
    );
  }

  Widget _buildCard() {
    return Container(
      height: 220,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        image: const DecorationImage(
          image: AssetImage('assets/images/camroll.jpeg'),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color.fromARGB(135, 6, 65, 74),
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          const Positioned(
            bottom: 16,
            left: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CAM',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFF5E2),
                  ),
                ),
                Text(
                  'ROLL',
                  style: TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFF5E2),
                  ),
                ),
                Text(
                  'memories are held',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFF5E2),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 🔥 LIVE CAMERA + MIRROR + GLASS EFFECT
class _LiveCameraGlassCard extends StatefulWidget {
  const _LiveCameraGlassCard();

  @override
  State<_LiveCameraGlassCard> createState() => _LiveCameraGlassCardState();
}

class _LiveCameraGlassCardState extends State<_LiveCameraGlassCard> {
  CameraController? _controller;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();

    final frontCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
    );

    _controller = CameraController(
      frontCamera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await _controller!.initialize();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: Colors.black,
      ),
      child: _controller == null || !_controller!.value.isInitialized
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              fit: StackFit.expand,
              children: [
                // 🪞 MIRROR CAMERA PREVIEW
                Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()..scale(-1.0, 1.0),
                  child: CameraPreview(_controller!),
                ),

                // 🧊 GLASS / FROSTED BLUR
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    color: Colors.white.withOpacity(0.15),
                  ),
                ),
              ],
            ),
    );
  }
}
