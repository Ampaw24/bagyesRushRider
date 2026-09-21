import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:delivery_boy/constant/app_theme.dart';

/// Live, camera-only selfie capture with on-device face guidance.
///
/// Mirrors the liveness-style capture flow used by modern identity
/// verification products (Stripe Identity, Onfido, Persona): the user never
/// picks a photo, they hold their face inside a guide circle and the shot is
/// taken automatically once framing, lighting, and head pose are all good
/// for a short, continuous hold.
class RiderSelfieCaptureScreen extends StatefulWidget {
  const RiderSelfieCaptureScreen({super.key});

  @override
  State<RiderSelfieCaptureScreen> createState() =>
      _RiderSelfieCaptureScreenState();
}

enum _Stage { initializing, permissionDenied, error, live, capturing, done }

class _GuideCheck {
  final bool ok;
  final String message;
  const _GuideCheck(this.ok, this.message);
}

const _holdDuration = Duration(milliseconds: 900);
const _fallbackDelay = Duration(seconds: 9);
const _minFaceAreaRatio = 0.14;
const _maxFaceAreaRatio = 0.55;
const _maxCenterOffset = 0.20;
const _maxHeadAngle = 16.0;
const _minBrightness = 55.0;
const _maxBrightness = 215.0;

class _RiderSelfieCaptureScreenState extends State<RiderSelfieCaptureScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  FaceDetector? _faceDetector;
  _Stage _stage = _Stage.initializing;
  String _statusMessage = 'Finding your camera…';
  double _holdProgress = 0;
  DateTime? _goodSince;
  bool _busy = false;
  bool _showManualFallback = false;
  Timer? _fallbackTimer;
  String? _errorMessage;
  bool _permissionPermanentlyDenied = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _setUp();
  }

  /// Requests camera access up front so the plugin's platform channel is
  /// never touched without permission — skipping this causes native crashes
  /// on some devices instead of a clean denial.
  Future<bool> _ensureCameraPermission() async {
    var status = await Permission.camera.status;
    if (!status.isGranted) {
      status = await Permission.camera.request();
    }
    if (!mounted) return false;
    if (status.isGranted) return true;

    setState(() {
      _stage = _Stage.permissionDenied;
      _permissionPermanentlyDenied = status.isPermanentlyDenied;
    });
    return false;
  }

  Future<void> _setUp() async {
    try {
      if (!await _ensureCameraPermission()) return;

      final cameras = await availableCameras();
      final front = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        front,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup:
            Platform.isAndroid ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888,
      );
      await controller.initialize();
      if (!mounted) return;

      _faceDetector ??= FaceDetector(
        options: FaceDetectorOptions(
          performanceMode: FaceDetectorMode.accurate,
          enableTracking: false,
        ),
      );

      setState(() {
        _controller = controller;
        _stage = _Stage.live;
        _statusMessage = 'Position your face in the circle';
      });

      _fallbackTimer = Timer(_fallbackDelay, () {
        if (mounted && _stage == _Stage.live) {
          setState(() => _showManualFallback = true);
        }
      });

      await controller.startImageStream(_onFrame);
    } on CameraException catch (e) {
      if (!mounted) return;
      setState(() {
        _stage = e.code == 'CameraAccessDenied' ||
                e.code == 'CameraAccessDeniedWithoutPrompt' ||
                e.code == 'CameraAccessRestricted'
            ? _Stage.permissionDenied
            : _Stage.error;
        _errorMessage = e.description ?? e.code;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _stage = _Stage.error;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _onFrame(CameraImage image) async {
    if (_busy || _stage != _Stage.live || _controller == null) return;
    _busy = true;
    try {
      final inputImage = _toInputImage(image);
      if (inputImage == null) return;

      final faces = await _faceDetector!.processImage(inputImage);
      final brightness = _estimateBrightness(image);
      final check = _evaluate(faces, image, brightness);

      if (!mounted) return;

      if (check.ok) {
        _goodSince ??= DateTime.now();
        final elapsed = DateTime.now().difference(_goodSince!);
        final progress =
            (elapsed.inMilliseconds / _holdDuration.inMilliseconds).clamp(0.0, 1.0);
        setState(() {
          _statusMessage = progress >= 1 ? 'Perfect — hold still…' : 'Hold still…';
          _holdProgress = progress;
        });
        if (elapsed >= _holdDuration) {
          await _autoCapture();
        }
      } else {
        _goodSince = null;
        setState(() {
          _statusMessage = check.message;
          _holdProgress = 0;
        });
      }
    } catch (_) {
      // Skip a bad frame silently — the next one will retry.
    } finally {
      _busy = false;
    }
  }

  _GuideCheck _evaluate(List<Face> faces, CameraImage image, double brightness) {
    if (faces.isEmpty) {
      return const _GuideCheck(false, 'Position your face in the circle');
    }
    if (faces.length > 1) {
      return const _GuideCheck(false, 'Only one person should be in frame');
    }
    if (brightness < _minBrightness) {
      return const _GuideCheck(false, 'Too dark — move to better lighting');
    }
    if (brightness > _maxBrightness) {
      return const _GuideCheck(false, 'Too bright — soften the light');
    }

    final face = faces.first;
    final imgArea = image.width * image.height;
    final faceArea = face.boundingBox.width * face.boundingBox.height;
    final areaRatio = imgArea == 0 ? 0 : faceArea / imgArea;

    if (areaRatio < _minFaceAreaRatio) {
      return const _GuideCheck(false, 'Move closer');
    }
    if (areaRatio > _maxFaceAreaRatio) {
      return const _GuideCheck(false, 'Move back a little');
    }

    final faceCenter = face.boundingBox.center;
    final imgCenter = Offset(image.width / 2, image.height / 2);
    final dx = (faceCenter.dx - imgCenter.dx) / image.width;
    final dy = (faceCenter.dy - imgCenter.dy) / image.height;
    final offset = math.sqrt(dx * dx + dy * dy);
    if (offset > _maxCenterOffset) {
      return const _GuideCheck(false, 'Center your face in the circle');
    }

    final yaw = face.headEulerAngleY ?? 0;
    final roll = face.headEulerAngleZ ?? 0;
    if (yaw.abs() > _maxHeadAngle || roll.abs() > _maxHeadAngle) {
      return const _GuideCheck(false, 'Look straight at the camera');
    }

    return const _GuideCheck(true, 'Hold still…');
  }

  Future<void> _autoCapture() async {
    if (_stage != _Stage.live || _controller == null) return;
    setState(() => _stage = _Stage.capturing);
    HapticFeedback.mediumImpact();
    try {
      await _controller!.stopImageStream();
      final file = await _controller!.takePicture();
      if (!mounted) return;
      setState(() => _stage = _Stage.done);
      await Future.delayed(const Duration(milliseconds: 550));
      if (!mounted) return;
      Navigator.of(context).pop(File(file.path));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _stage = _Stage.error;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _manualCapture() async {
    if (_controller == null || _stage != _Stage.live) return;
    setState(() => _stage = _Stage.capturing);
    HapticFeedback.mediumImpact();
    try {
      if (_controller!.value.isStreamingImages) {
        await _controller!.stopImageStream();
      }
      final file = await _controller!.takePicture();
      if (!mounted) return;
      setState(() => _stage = _Stage.done);
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      Navigator.of(context).pop(File(file.path));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _stage = _Stage.error;
        _errorMessage = e.toString();
      });
    }
  }

  InputImage? _toInputImage(CameraImage image) {
    final camera = _controller?.description;
    if (camera == null) return null;

    final rotation = Platform.isIOS
        ? InputImageRotationValue.fromRawValue(camera.sensorOrientation)
        : _androidRotation(camera);
    if (rotation == null) return null;

    final format = InputImageFormatValue.fromRawValue(image.format.raw);
    if (format == null || image.planes.length != 1) return null;

    final plane = image.planes.first;
    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  static const _deviceOrientationDegrees = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  InputImageRotation? _androidRotation(CameraDescription camera) {
    final deviceOrientation = _controller!.value.deviceOrientation;
    final base = _deviceOrientationDegrees[deviceOrientation];
    if (base == null) return null;
    final degrees = camera.lensDirection == CameraLensDirection.front
        ? (camera.sensorOrientation + base) % 360
        : (camera.sensorOrientation - base + 360) % 360;
    return InputImageRotationValue.fromRawValue(degrees);
  }

  /// Rough average luma (0–255) sampled across the frame, cheap enough to
  /// run on every processed frame.
  double _estimateBrightness(CameraImage image) {
    final plane = image.planes.first;
    final bytes = plane.bytes;
    if (bytes.isEmpty) return 128;

    var sum = 0;
    var count = 0;

    if (Platform.isAndroid) {
      // NV21: the first width*height bytes are the Y (luma) plane.
      final lumaLength = math.min(bytes.length, image.width * image.height);
      const stride = 97; // prime stride avoids sampling artifacts
      for (var i = 0; i < lumaLength; i += stride) {
        sum += bytes[i];
        count++;
      }
    } else {
      // BGRA8888: 4 bytes per pixel, sample every Nth pixel.
      const pixelStride = 4;
      const pixelSkip = 23;
      for (var i = 0; i + 2 < bytes.length; i += pixelStride * pixelSkip) {
        final b = bytes[i];
        final g = bytes[i + 1];
        final r = bytes[i + 2];
        sum += (0.299 * r + 0.587 * g + 0.114 * b).round();
        count++;
      }
    }

    return count == 0 ? 128 : sum / count;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      if (controller != null && controller.value.isInitialized) {
        _fallbackTimer?.cancel();
        controller.dispose();
        _controller = null;
      }
    } else if (state == AppLifecycleState.resumed) {
      // Covers both "camera was torn down while backgrounded" and "user
      // just granted the permission from the app settings screen".
      if (_stage == _Stage.live || _stage == _Stage.permissionDenied) {
        _setUp();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _fallbackTimer?.cancel();
    _faceDetector?.close();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _stage != _Stage.capturing,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            if (_controller != null && _controller!.value.isInitialized)
              _buildCameraLayer()
            else
              const ColoredBox(color: Colors.black),
            if (_stage == _Stage.live || _stage == _Stage.capturing)
              _buildGuideOverlay(context),
            _buildTopBar(context),
            if (_stage == _Stage.live || _stage == _Stage.capturing)
              _buildStatusPanel(context),
            if (_stage == _Stage.initializing) _buildCenteredSpinner(),
            if (_stage == _Stage.permissionDenied) _buildPermissionDenied(context),
            if (_stage == _Stage.error) _buildErrorState(context),
            if (_stage == _Stage.done) _buildSuccessOverlay(context),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraLayer() {
    // The CameraX preview stream already mirrors the front lens itself
    // (matching the native Android camera app), so we render it as-is —
    // adding our own horizontal flip here double-mirrors it back to the
    // raw, "backwards" feed instead of a natural mirror.
    final portraitAspect = 1 / _controller!.value.aspectRatio;
    return ClipRect(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: portraitAspect,
          height: 1,
          child: CameraPreview(_controller!),
        ),
      ),
    );
  }

  Widget _buildGuideOverlay(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final diameter = math.min(size.width, size.height) * 0.82;
    final center = Offset(size.width / 2, size.height * 0.42);
    final ringColor = _holdProgress > 0 ? AppColors.success : Colors.white;

    return IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,
        painter: _FaceGuidePainter(
          center: center,
          radius: diameter / 2,
          progress: _holdProgress,
          ringColor: ringColor,
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: MediaQuery.sizeOf(context).width * 0.04,
          vertical: MediaQuery.sizeOf(context).height * 0.012,
        ),
        child: Row(
          children: [
            _RoundIconButton(
              icon: HugeIcons.strokeRoundedCancel01,
              onTap: () => Navigator.of(context).maybePop(),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusPanel(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final h = MediaQuery.sizeOf(context).height;
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(w * 0.08, 0, w * 0.08, h * 0.04),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Verify it\'s you',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: (w * 0.05).clamp(18.0, 22.0),
                ),
              ),
              SizedBox(height: h * 0.01),
              Text(
                _statusMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Roboto',
                  color: Colors.white.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w500,
                  fontSize: (w * 0.037).clamp(13.0, 15.0),
                ),
              ),
              if (_showManualFallback) ...[
                SizedBox(height: h * 0.02),
                TextButton(
                  onPressed: _manualCapture,
                  child: Text(
                    'Trouble with auto-capture? Tap to take the photo',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      color: AppColors.primaryLight,
                      fontWeight: FontWeight.w600,
                      fontSize: (w * 0.032).clamp(11.5, 13.0),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCenteredSpinner() {
    return const Center(
      child: CircularProgressIndicator(color: Colors.white),
    );
  }

  Widget _buildPermissionDenied(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: w * 0.08),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(HugeIcons.strokeRoundedCameraOff01,
                color: Colors.white, size: w * 0.12),
            SizedBox(height: w * 0.04),
            Text(
              'Camera access is needed to verify your identity',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Roboto',
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: (w * 0.04).clamp(14.0, 17.0),
              ),
            ),
            SizedBox(height: w * 0.02),
            Text(
              _permissionPermanentlyDenied
                  ? 'Camera permission was denied. Enable it for BagyesRIDER in your device settings to continue.'
                  : 'BagyesRIDER needs camera access to verify your identity with a live selfie.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Roboto',
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: (w * 0.033).clamp(12.0, 13.5),
              ),
            ),
            SizedBox(height: w * 0.06),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: const Text('Go back',
                      style: TextStyle(fontFamily: 'Roboto', color: Colors.white)),
                ),
                SizedBox(width: w * 0.04),
                TextButton(
                  onPressed: _permissionPermanentlyDenied
                      ? openAppSettings
                      : () {
                          setState(() => _stage = _Stage.initializing);
                          _setUp();
                        },
                  child: Text(
                    _permissionPermanentlyDenied ? 'Open Settings' : 'Grant permission',
                    style: TextStyle(
                        fontFamily: 'Roboto', color: AppColors.primaryLight),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: w * 0.08),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(HugeIcons.strokeRoundedAlert01,
                color: AppColors.error, size: w * 0.12),
            SizedBox(height: w * 0.04),
            Text(
              'Something went wrong starting the camera',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Roboto',
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: (w * 0.04).clamp(14.0, 17.0),
              ),
            ),
            if (_errorMessage != null) ...[
              SizedBox(height: w * 0.02),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Roboto',
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: (w * 0.03).clamp(11.0, 12.5),
                ),
              ),
            ],
            SizedBox(height: w * 0.06),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: const Text('Go back',
                      style: TextStyle(fontFamily: 'Roboto', color: Colors.white)),
                ),
                SizedBox(width: w * 0.04),
                TextButton(
                  onPressed: () {
                    setState(() => _stage = _Stage.initializing);
                    _setUp();
                  },
                  child: Text('Retry',
                      style: TextStyle(
                          fontFamily: 'Roboto', color: AppColors.primaryLight)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessOverlay(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return Center(
      child: Container(
        width: w * 0.2,
        height: w * 0.2,
        decoration: const BoxDecoration(
          color: AppColors.success,
          shape: BoxShape.circle,
        ),
        child: Icon(HugeIcons.strokeRoundedCheckmarkCircle01,
            color: Colors.white, size: w * 0.11),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _RoundIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: w * 0.1,
        height: w * 0.1,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: w * 0.05),
      ),
    );
  }
}

class _FaceGuidePainter extends CustomPainter {
  final Offset center;
  final double radius;
  final double progress;
  final Color ringColor;

  _FaceGuidePainter({
    required this.center,
    required this.radius,
    required this.progress,
    required this.ringColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final overlayPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final holePath = Path()..addOval(Rect.fromCircle(center: center, radius: radius));
    final dimmed = Path.combine(PathOperation.difference, overlayPath, holePath);
    canvas.drawPath(dimmed, Paint()..color = Colors.black.withValues(alpha: 0.55));

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.025
        ..color = ringColor.withValues(alpha: 0.9),
    );

    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = radius * 0.045
          ..strokeCap = StrokeCap.round
          ..color = AppColors.success,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FaceGuidePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.ringColor != ringColor ||
        oldDelegate.center != center ||
        oldDelegate.radius != radius;
  }
}
