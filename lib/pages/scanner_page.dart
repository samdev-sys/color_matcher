import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/gemini_service.dart';
import '../services/history_service.dart';
import '../theme.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> with WidgetsBindingObserver {
  CameraController? _controller;
  bool _isCameraInitialized = false;
  bool _isCameraBeingInitialized = false;
  List<dynamic> _pantoneDb = [];
  final ValueNotifier<Color?> _detectedColorNotifier = ValueNotifier(null);
  final ValueNotifier<String?> _detectedColorNameNotifier = ValueNotifier(null);
  bool _isAnalyzing = false;

  bool _isExposureLocked = false;
  bool _isFocusLocked = false;
  Offset? _lockedFocusPoint;

  bool _isCalibrated = false;
  double _calibrationR = 1.0;
  double _calibrationG = 1.0;
  double _calibrationB = 1.0;
  bool _isCalibrating = false;

  bool _wasExposureLockedBeforeNavigate = false;
  bool _wasFocusLockedBeforeNavigate = false;
  bool _wasCalibratedBeforeNavigate = false;
  double _savedCalibrationR = 1.0;
  double _savedCalibrationG = 1.0;
  double _savedCalibrationB = 1.0;

  final GeminiService _geminiService = GeminiService();
  final HistoryService _historyService = HistoryService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
    _loadPantoneDb();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.stopImageStream();
    _controller?.dispose();
    _detectedColorNotifier.dispose();
    _detectedColorNameNotifier.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint('App lifecycle state: $state');

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _pauseCamera();
    } else if (state == AppLifecycleState.resumed) {
      _resumeCamera();
    }
  }

  Future<void> _pauseCamera() async {
    if (_controller != null && _controller!.value.isInitialized) {
      debugPrint('Pausing camera stream');
      try {
        await _controller!.stopImageStream();
      } catch (e) {
        debugPrint('Error stopping stream: $e');
      }
    }
  }

  Future<void> _resumeCamera() async {
    if (_controller != null &&
        _controller!.value.isInitialized &&
        !_isAnalyzing) {
      debugPrint('Resuming camera stream');
      try {
        _controller!.startImageStream(_processCameraImage);
      } catch (e) {
        debugPrint('Error resuming stream: $e');
      }
    }
  }

  Future<void> _initializeCamera() async {
    if (_isCameraBeingInitialized) return;

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
      _isCameraBeingInitialized = true;
      await _controller!.initialize();
      if (!mounted) return;

      if (_wasExposureLockedBeforeNavigate) {
        try {
          await _controller!.setExposureMode(ExposureMode.locked);
          _isExposureLocked = true;
        } catch (_) {}
      } else {
        try {
          await _controller!.setExposureMode(ExposureMode.auto);
        } catch (_) {}
      }

      if (_wasFocusLockedBeforeNavigate) {
        try {
          await _controller!.setFocusMode(FocusMode.locked);
          _isFocusLocked = true;
        } catch (_) {}
      } else {
        try {
          await _controller!.setFocusMode(FocusMode.auto);
        } catch (_) {}
      }

      if (_wasCalibratedBeforeNavigate) {
        _calibrationR = _savedCalibrationR;
        _calibrationG = _savedCalibrationG;
        _calibrationB = _savedCalibrationB;
        _isCalibrated = true;
      }

      setState(() {
        _isCameraInitialized = true;
        _isCameraBeingInitialized = false;
      });

      _controller!.startImageStream(_processCameraImage);
    } catch (e) {
      debugPrint("Camera initialize error: $e");
      _isCameraBeingInitialized = false;
    }
  }

  Future<void> _releaseCamera() async {
    debugPrint('Releasing camera resources');

    _wasExposureLockedBeforeNavigate = _isExposureLocked;
    _wasFocusLockedBeforeNavigate = _isFocusLocked;
    _wasCalibratedBeforeNavigate = _isCalibrated;
    _savedCalibrationR = _calibrationR;
    _savedCalibrationG = _calibrationG;
    _savedCalibrationB = _calibrationB;

    if (_controller != null && _controller!.value.isInitialized) {
      try {
        await _controller!.stopImageStream();
      } catch (e) {
        debugPrint('Error stopping stream: $e');
      }
    }

    _controller?.dispose();
    _controller = null;

    setState(() {
      _isCameraInitialized = false;
    });
  }

  void _showCalibrationToast() {
    if (!_isCalibrated && !_isCalibrating) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '💡 Consejo: Usa el botón de calibración apuntando a una hoja blanca para mejorar la precisión del color',
          ),
          duration: Duration(seconds: 4),
          backgroundColor: Color(0xFF6A1B9A),
        ),
      );
    }
  }

  Future<void> _calibrate() async {
    if (_isCalibrating) return;
    _showCalibrationDialog();
  }

  void _showCalibrationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.wb_sunny, color: AppColors.primary),
            SizedBox(width: 12),
            Text('Calibración de Color', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white24),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pasos para calibrar:',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    '1️⃣ Apunta la cámara a una hoja de papel blanco puro',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '2️⃣ Asegúrate de que la hoja esté bien iluminada',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '3️⃣ Presiona "Calibrar" para establecer la referencia',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Esto compensará la iluminación ambiental y mejorará la precisión del color.',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _performCalibration();
            },
            icon: const Icon(Icons.check),
            label: const Text('Calibrar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _performCalibration() async {
    setState(() {
      _isCalibrating = true;
    });

    _showToast('Capturando referencia blanca...');

    await Future.delayed(const Duration(milliseconds: 500));

    final capturedColor = _detectedColorNotifier.value;

    if (capturedColor == null) {
      _showToast('Error: No se detectó ningún color. Intenta de nuevo.');
      setState(() {
        _isCalibrating = false;
      });
      return;
    }

    final int r = (capturedColor.r * 255).round().clamp(0, 255);
    final int g = (capturedColor.g * 255).round().clamp(0, 255);
    final int b = (capturedColor.b * 255).round().clamp(0, 255);

    if (r < 50 || g < 50 || b < 50) {
      _showToast(
          '⚠️ La superficie no parece blanca. Usa una hoja blanca pura.');
      setState(() {
        _isCalibrating = false;
      });
      return;
    }

    setState(() {
      _calibrationR = 255.0 / r;
      _calibrationG = 255.0 / g;
      _calibrationB = 255.0 / b;
      _isCalibrated = true;
      _isCalibrating = false;
    });

    _showToast(
      '✅ Calibración completada!\n'
      'Referencia: R=$r G=$g B=$b\n'
      'Los colores ahora están normalizados.',
      duration: 3,
    );
  }

  void _resetCalibration() {
    setState(() {
      _isCalibrated = false;
      _calibrationR = 1.0;
      _calibrationG = 1.0;
      _calibrationB = 1.0;
    });
    _showToast('🔄 Calibración reiniciada', duration: 2);
  }

  void _showToast(String message, {int duration = 3}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        duration: Duration(seconds: duration),
        backgroundColor: message.contains('✅')
            ? Colors.green.shade700
            : message.contains('⚠️')
                ? Colors.orange.shade700
                : AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _setFocusPoint(Offset point) async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      final size = MediaQuery.of(context).size;
      final double x = point.dx / size.width;
      final double y = point.dy / size.height;

      final focusPoint = Offset(x.clamp(0.0, 1.0), y.clamp(0.0, 1.0));

      try {
        await _controller!.setFocusPoint(focusPoint);
        await _controller!.setFocusMode(FocusMode.locked);
        _isFocusLocked = true;
        debugPrint('Focus locked at: $focusPoint');
      } catch (e) {
        debugPrint('Focus lock not supported: $e');
      }

      try {
        await _controller!.setExposurePoint(focusPoint);
        await _controller!.setExposureMode(ExposureMode.locked);
        _isExposureLocked = true;
        debugPrint('Exposure locked at: $focusPoint');
      } catch (e) {
        debugPrint('Exposure lock not supported: $e');
      }

      setState(() {
        _lockedFocusPoint = point;
      });
    } catch (e) {
      debugPrint('Error setting focus/exposure point: $e');
    }
  }

  Future<void> _unlockFocusExposure() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      try {
        await _controller!.setFocusMode(FocusMode.auto);
        debugPrint('Focus unlocked - using auto');
      } catch (_) {}

      try {
        await _controller!.setExposureMode(ExposureMode.auto);
        debugPrint('Exposure unlocked - using auto');
      } catch (_) {}

      setState(() {
        _isFocusLocked = false;
        _isExposureLocked = false;
        _lockedFocusPoint = null;
      });
    } catch (e) {
      debugPrint('Error unlocking focus/exposure: $e');
    }
  }

  void _processCameraImage(CameraImage image) {
    if (_isAnalyzing) return;
    _isAnalyzing = true;

    try {
      final color = _getCenterPixelColor(image);
      if (color != null) {
        Color calibratedColor = color;

        if (_isCalibrated) {
          final int r = (color.r * _calibrationR).round().clamp(0, 255);
          final int g = (color.g * _calibrationG).round().clamp(0, 255);
          final int b = (color.b * _calibrationB).round().clamp(0, 255);
          calibratedColor = Color.fromARGB(255, r, g, b);
        }

        _detectedColorNotifier.value = calibratedColor;

        final int r8 = (calibratedColor.r * 255).round().clamp(0, 255);
        final int g8 = (calibratedColor.g * 255).round().clamp(0, 255);
        final int b8 = (calibratedColor.b * 255).round().clamp(0, 255);
        final hex =
            '#${r8.toRadixString(16).padLeft(2, '0')}${g8.toRadixString(16).padLeft(2, '0')}${b8.toRadixString(16).padLeft(2, '0')}';
        final closestMatch = _findClosestPantone(hex);
        _detectedColorNameNotifier.value =
            closestMatch['pantone'] as String? ?? 'Unknown';
      }
    } catch (e) {
      debugPrint("Error processing image: $e");
    } finally {
      _isAnalyzing = false;
    }
  }

  Color _getCenterPixelColor(CameraImage image) {
    final int centerX = image.width ~/ 2;
    final int centerY = image.height ~/ 2;

    if (image.format.group == ImageFormatGroup.yuv420) {
      final int yPlaneIndex = centerY * image.planes[0].bytesPerRow + centerX;
      final int y = image.planes[0].bytes[yPlaneIndex];

      final int uvPixelStride = image.planes[1].bytesPerPixel!;
      final int uvRowStride = image.planes[1].bytesPerRow;
      final int uvIndex = (centerY / 2).floor() * uvRowStride +
          (centerX / 2).floor() * uvPixelStride;

      final int u = image.planes[1].bytes[uvIndex];
      final int v = image.planes[2].bytes[uvIndex];

      int r = (y + 1.402 * (v - 128)).round();
      int g = (y - 0.344136 * (u - 128) - 0.714136 * (v - 128)).round();
      int b = (y + 1.772 * (u - 128)).round();

      return Color.fromARGB(
          255, r.clamp(0, 255), g.clamp(0, 255), b.clamp(0, 255));
    } else if (image.format.group == ImageFormatGroup.bgra8888) {
      final int index = centerY * image.planes[0].bytesPerRow + centerX * 4;
      final plane = image.planes[0].bytes;
      return Color.fromARGB(
          255, plane[index + 2], plane[index + 1], plane[index]);
    }
    return Color.fromARGB(255, 0, 0, 0);
  }

  Future<void> _loadPantoneDb() async {
    try {
      final String response =
          await rootBundle.loadString('assets/pantoneDb.json');
      _pantoneDb = json.decode(response);
    } catch (e) {
      debugPrint("Error loading pantone database: $e");
      _pantoneDb = [];
    }
  }

  Future<void> _handleCapture() async {
    if (_detectedColorNotifier.value == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Point camera at a colored surface first')),
      );
      return;
    }

    Color colorToSend = _detectedColorNotifier.value!;

    final int r8 = (colorToSend.r * 255).round().clamp(0, 255);
    final int g8 = (colorToSend.g * 255).round().clamp(0, 255);
    final int b8 = (colorToSend.b * 255).round().clamp(0, 255);
    final hex =
        '#${r8.toRadixString(16).padLeft(2, '0').toUpperCase()}${g8.toRadixString(16).padLeft(2, '0').toUpperCase()}${b8.toRadixString(16).padLeft(2, '0').toUpperCase()}';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final analysis = await _geminiService.getColorAnalysis(hex);

      if (analysis != null) {
        await _historyService.addColorToHistory(analysis);

        if (mounted) {
          Navigator.pop(context);
          await _releaseCamera();
          if (mounted) {
            context.push('/color/${hex.replaceAll('#', '')}').then((_) {
              debugPrint('Returned from color detail page');
              if (mounted) {
                _initializeCamera();
              }
            });
          }
        }
      } else {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to analyze color'),
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'), duration: const Duration(seconds: 4)),
        );
      }
    }
  }

  dynamic _findClosestPantone(String hex) {
    if (_pantoneDb.isEmpty) {
      return {"pantone": "Custom Color", "hex": hex};
    }

    Color inputColor =
        Color(int.parse(hex.substring(1, 7), radix: 16) + 0xFF000000);
    dynamic closestMatch = _pantoneDb.first;
    double minDistance = double.maxFinite;

    for (var pantone in _pantoneDb) {
      Color pantoneColor = Color(
          int.parse((pantone['hex'] as String).substring(1, 7), radix: 16) +
              0xFF000000);
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
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: AppColors.primary),
              const SizedBox(height: 16),
              Text(
                _isCameraBeingInitialized
                    ? 'Inicializando cámara...'
                    : 'Cámara no disponible',
                style: const TextStyle(color: Colors.white54),
              ),
            ],
          ),
        ),
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isCalibrated && !_isCalibrating) {
        _showCalibrationToast();
      }
    });

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapDown: (details) {
          if (!_isExposureLocked && !_isFocusLocked) {
            _setFocusPoint(details.localPosition);
          }
        },
        child: Stack(
          children: [
            Center(child: CameraPreview(_controller!)),
            if (_lockedFocusPoint != null) _buildLockIndicator(),
            if (_isCalibrated) _buildCalibrationIndicator(),
            _buildScanningUI(),
            _buildTopBar(),
            _buildLockButton(),
            _buildCalibrateButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildCalibrationIndicator() {
    return Positioned(
      top: 100,
      left: 20,
      right: 20,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.green.withAlpha(200),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wb_sunny, color: Colors.white, size: 16),
              SizedBox(width: 8),
              Text(
                'Calibrado ✓',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLockIndicator() {
    return Positioned(
      left: _lockedFocusPoint!.dx - 30,
      top: _lockedFocusPoint!.dy - 30,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.primary.withAlpha(200),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withAlpha(75),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Center(
          child: Icon(
            Icons.lock,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 50,
      left: 20,
      right: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _CircleButton(icon: Icons.close, onPressed: () => context.pop()),
          if (_isExposureLocked || _isFocusLocked)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(200),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock, color: Colors.white, size: 14),
                  SizedBox(width: 4),
                  Text(
                    'Bloqueado',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCalibrateButton() {
    return Positioned(
      bottom: 80,
      left: 20,
      right: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: _isCalibrated ? _resetCalibration : _calibrate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: _isCalibrated
                    ? Colors.green.withAlpha(200)
                    : Colors.white.withAlpha(50),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: _isCalibrated ? Colors.green : Colors.white54,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isCalibrated ? Icons.refresh : Icons.wb_sunny,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isCalibrated ? 'Reiniciar' : 'Calibrar',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLockButton() {
    return Positioned(
      bottom: 150,
      left: 20,
      right: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () {
              if (_isExposureLocked || _isFocusLocked) {
                _unlockFocusExposure();
              } else {
                _setFocusPoint(Offset(
                  MediaQuery.of(context).size.width / 2,
                  MediaQuery.of(context).size.height / 2,
                ));
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: (_isExposureLocked || _isFocusLocked)
                    ? AppColors.primary
                    : Colors.white.withAlpha(50),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: (_isExposureLocked || _isFocusLocked)
                      ? AppColors.primary
                      : Colors.white54,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    (_isExposureLocked || _isFocusLocked)
                        ? Icons.lock
                        : Icons.lock_open,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    (_isExposureLocked || _isFocusLocked)
                        ? 'Desbloquear'
                        : 'Bloquear Exposición',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
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
        const SizedBox(height: 120),
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
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                );
              },
            ),
            const SizedBox(height: 8),
            Text(
              _isExposureLocked || _isFocusLocked
                  ? 'Exposición fija'
                  : 'Toca para bloquear',
              style: TextStyle(
                color: Colors.white.withAlpha(150),
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 220),
        GestureDetector(
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
        const SizedBox(height: 30),
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
          color: Colors.black.withAlpha(100),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white12),
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}
