import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

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
      (c) => c.lensDirection == CameraLensDirection.front,
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: 220,
        color: Colors.black,
        child: _controller == null || !_controller!.value.isInitialized
            ? const Center(child: CircularProgressIndicator())
            : Stack(
                fit: StackFit.expand,
                children: [
                  // 🪞 MIRROR (ONLY APPLY ON MOBILE)
                  kIsWeb
                      ? CameraPreview(_controller!)
                      : Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.rotationY(3.1415926535),
                          child: CameraPreview(_controller!),
                        ),

                  // 🧊 GLASS EFFECT
                  kIsWeb
                      // 🌐 FAKE GLASS (WEB SAFE)
                      ? Container(
                          color: Colors.white.withOpacity(0.25),
                        )
                      // 📱 REAL BLUR (MOBILE ONLY)
                      : BackdropFilter(
                          filter: ImageFilter.blur(
                            sigmaX: 12,
                            sigmaY: 12,
                          ),
                          child: Container(
                            color: Colors.white.withOpacity(0.15),
                          ),
                        ),
                ],
              ),
      ),
    );
  }
}
