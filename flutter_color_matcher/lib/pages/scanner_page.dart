import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/models.dart';
import '../theme.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  CameraController? _controller;
  bool _isCameraInitialized = false;
  List<dynamic> _pantoneDb = [];
  final ValueNotifier<Color?> _detectedColorNotifier = ValueNotifier(null);
  final ValueNotifier<String?> _detectedColorNameNotifier = ValueNotifier(null);
  bool _isAnalyzing = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _loadPantoneDb();
  }

  @override
  void dispose() {
    _controller?.stopImageStream();
    _controller?.dispose();
    _detectedColorNotifier.dispose();
    _detectedColorNameNotifier.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    final status = await Permission.camera.request();
    if (!mounted) return;
    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Camera permission is required')),
      );
      return;
    }

    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    _controller = CameraController(
      cameras.first,
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await _controller!.initialize();
      if (!mounted) return;
      setState(() {
        _isCameraInitialized = true;
      });
      _controller!.startImageStream(_processCameraImage);
    } catch (e) {
      debugPrint("Camera initialize error: $e");
    }
  }

  void _processCameraImage(CameraImage image) {
    if (_isAnalyzing) return;
    _isAnalyzing = true;

    try {
      final color = _getCenterPixelColor(image);
      if (color != null) {
        _detectedColorNotifier.value = color;

        final hex = '#${color.value.toRadixString(16).substring(2)}';
        final closestMatch = _findClosestPantone(hex);
        _detectedColorNameNotifier.value = closestMatch['pantone'] as String? ?? 'Unknown';
      }
    } catch (e) {
      debugPrint("Error processing image: $e");
    } finally {
      _isAnalyzing = false;
    }
  }

  Color? _getCenterPixelColor(CameraImage image) {
    final int centerX = image.width ~/ 2;
    final int centerY = image.height ~/ 2;

    if (image.format.group == ImageFormatGroup.yuv420) {
      final int yPlaneIndex = centerY * image.planes[0].bytesPerRow + centerX;
      final int y = image.planes[0].bytes[yPlaneIndex];

      final int uvPixelStride = image.planes[1].bytesPerPixel!;
      final int uvRowStride = image.planes[1].bytesPerRow;
      final int uvIndex = (centerY / 2).floor() * uvRowStride + (centerX / 2).floor() * uvPixelStride;
      
      final int u = image.planes[1].bytes[uvIndex];
      final int v = image.planes[2].bytes[uvIndex];

      int r = (y + 1.402 * (v - 128)).round();
      int g = (y - 0.344136 * (u - 128) - 0.714136 * (v - 128)).round();
      int b = (y + 1.772 * (u - 128)).round();

      return Color.fromARGB(255, r.clamp(0, 255), g.clamp(0, 255), b.clamp(0, 255));
    } else if (image.format.group == ImageFormatGroup.bgra8888) {
      final int index = centerY * image.planes[0].bytesPerRow + centerX * 4;
      final plane = image.planes[0].bytes;
      return Color.fromARGB(plane[index + 3], plane[index + 2], plane[index + 1], plane[index]);
    }
    return null; // Fallback for unsupported formats
  }

  Future<void> _loadPantoneDb() async {
    try {
      final String response = await rootBundle.loadString('assets/pantoneDb.json');
      _pantoneDb = json.decode(response);
    } catch (e) {
      debugPrint("Error loading pantone database: $e");
      _pantoneDb = [];
    }
  }

  void _handleCapture() {
    if (_detectedColorNotifier.value == null) return;

    final hex = '#${_detectedColorNotifier.value!.value.toRadixString(16).substring(2)}';
    final closestMatch = _findClosestPantone(hex);

    final String colorHex = (closestMatch['hex'] as String? ?? hex).replaceAll('#', '');
    context.push('/color/$colorHex');
  }

  dynamic _findClosestPantone(String hex) {
    if (_pantoneDb.isEmpty) {
      return {"pantone": "Custom Color", "hex": hex};
    }

    Color inputColor = Color(int.parse(hex.substring(1, 7), radix: 16) + 0xFF000000);
    dynamic closestMatch = _pantoneDb.first;
    double minDistance = double.maxFinite;

    for (var pantone in _pantoneDb) {
      Color pantoneColor = Color(int.parse((pantone['hex'] as String).substring(1, 7), radix: 16) + 0xFF000000);
      double distance = _colorDistance(inputColor, pantoneColor);
      if (distance < minDistance) {
        minDistance = distance;
        closestMatch = pantone;
      }
    }
    return closestMatch;
  }

  double _colorDistance(Color c1, Color c2) {
    return (c1.red - c2.red).abs() +
        (c1.green - c2.green).abs() +
        (c1.blue - c2.blue).abs().toDouble();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized || _controller == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(child: CameraPreview(_controller!)),
          _buildScanningUI(),
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _CircleButton(icon: Icons.close, onPressed: () => context.pop()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanningUI() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const SizedBox(),
        Column(
          children: [
            ValueListenableBuilder<Color?>(
              valueListenable: _detectedColorNotifier,
              builder: (context, color, child) {
                return Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color ?? Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            ValueListenableBuilder<String?>(
              valueListenable: _detectedColorNameNotifier,
              builder: (context, name, child) {
                return Text(
                  name ?? 'Scanning...',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                );
              },
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 60.0),
          child: GestureDetector(
            onTap: _handleCapture,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: AppColors.primary, width: 5),
              ),
              child: const Center(
                child: Icon(Icons.search, color: AppColors.primary, size: 40),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  const _CircleButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.4),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white12),
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}
