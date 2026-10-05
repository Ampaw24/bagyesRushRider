import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:delivery_boy/features/rider/vehicles/capture/camera_access.dart';
import 'package:delivery_boy/features/rider/vehicles/capture/vehicle_photo_inspector.dart';
import 'package:delivery_boy/features/rider/vehicles/model/vehicle_capture.dart';
import 'package:delivery_boy/features/rider/vehicles/model/vehicle_verification_configuration.dart';
import 'package:delivery_boy/features/rider/vehicles/views/widgets/vehicle_camera_overlays.dart';

/// One photo the camera will ask for, numbered among all the vehicle's
/// steps ("Step 2 of 4").
class VehicleCameraShot {
  const VehicleCameraShot({required this.requirement, required this.number});

  final VehicleCaptureRequirement requirement;
  final int number;
}

/// Live, camera-only capture of vehicle photos — there is deliberately no
/// gallery route in.
///
/// Walks through [shots] in order: framing guide and instructions, capture,
/// then a review where the rider retakes or keeps the photo. Each kept photo
/// goes to [onCaptured] straight away, so closing the camera part-way keeps
/// everything already accepted. Pops when the last shot is kept.
class VehicleVerificationCamera extends StatefulWidget {
  const VehicleVerificationCamera({
    super.key,
    required this.kind,
    required this.shots,
    required this.totalSteps,
    required this.onCaptured,
  });

  final VehicleKind kind;
  final List<VehicleCameraShot> shots;
  final int totalSteps;

  /// Receives the photo's file, which the caller then owns.
  final void Function(VehicleCaptureType type, String path) onCaptured;

  @override
  State<VehicleVerificationCamera> createState() =>
      _VehicleVerificationCameraState();
}

enum _Phase { starting, permission, live, capturing, review, failed }

class _VehicleVerificationCameraState extends State<VehicleVerificationCamera>
    with WidgetsBindingObserver {
  CameraController? _controller;
  _Phase _phase = _Phase.starting;
  CameraAccess _access = CameraAccess.denied;
  int _shot = 0;
  String? _reviewPath;
  VehiclePhotoInspection? _inspection;

  /// Null when the camera has no controllable flash.
  bool? _torchOn;

  /// The camera was released because the app left the foreground.
  bool _reopenOnResume = false;
  String _failure = '';

  VehicleCameraShot get _current => widget.shots[_shot];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _start(request: true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _discardReview();
    _controller?.dispose();
    super.dispose();
  }

  /// Checks permission before touching the camera plugin — opening it
  /// without access crashes some devices instead of failing cleanly.
  Future<void> _start({required bool request}) async {
    if (_phase != _Phase.starting) setState(() => _phase = _Phase.starting);
    final access = await cameraAccess(request: request);
    if (!mounted) return;
    if (access != CameraAccess.granted) {
      setState(() {
        _access = access;
        _phase = _Phase.permission;
      });
      return;
    }
    await _openCamera();
  }

  Future<void> _openCamera() async {
    CameraController? controller;
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        _fail('No camera was found on this phone.');
        return;
      }
      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      // 1080p keeps a number plate readable without the size of a
      // full-resolution shot on a slow connection.
      controller = CameraController(
        camera,
        ResolutionPreset.veryHigh,
        enableAudio: false,
      );
      // A reopen can overlap an earlier start; only the newest survives.
      final previous = _controller;
      _controller = controller;
      previous?.dispose();
      await controller.initialize();
      if (!mounted || _controller != controller) return;

      bool? torch;
      try {
        await controller.setFlashMode(FlashMode.off);
        torch = false;
      } on CameraException {
        torch = null;
      }
      if (_phase == _Phase.review) controller.pausePreview().ignore();
      setState(() {
        _torchOn = torch;
        if (_phase != _Phase.review) _phase = _Phase.live;
      });
    } on CameraException catch (e) {
      // Released by a lifecycle change mid-start; resuming reopens it.
      if (!mounted || _controller != controller) return;
      final access = switch (e.code) {
        'CameraAccessDenied' => CameraAccess.denied,
        'CameraAccessDeniedWithoutPrompt' => CameraAccess.permanentlyDenied,
        'CameraAccessRestricted' => CameraAccess.restricted,
        _ => null,
      };
      if (access == null) {
        _fail("We couldn't start your camera. Close any other app using it "
            'and try again.');
      } else {
        setState(() {
          _access = access;
          _phase = _Phase.permission;
        });
      }
    } catch (_) {
      if (!mounted || _controller != controller) return;
      _fail("We couldn't start your camera. Please try again.");
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      final controller = _controller;
      if (controller == null) return;
      // A call or app switch can invalidate the camera, so release it now
      // and open a fresh one on return.
      _controller = null;
      _reopenOnResume = true;
      controller.dispose();
      if (mounted) setState(() {});
    } else if (state == AppLifecycleState.resumed) {
      if (_phase == _Phase.permission) {
        // Back from Settings — check again, but never re-prompt on our own.
        _start(request: false);
      } else if (_reopenOnResume) {
        _reopenOnResume = false;
        _openCamera();
      }
    }
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (_phase != _Phase.live ||
        controller == null ||
        !controller.value.isInitialized ||
        controller.value.isTakingPicture) {
      return;
    }
    setState(() => _phase = _Phase.capturing);
    HapticFeedback.mediumImpact();

    final XFile file;
    try {
      file = await controller.takePicture();
    } on CameraException {
      if (!mounted) return;
      if (_controller != controller) {
        // Interrupted by the app leaving the foreground.
        setState(() => _phase = _Phase.live);
        return;
      }
      _fail("We couldn't take the photo. Check your phone has free storage, "
          'then try again.');
      return;
    }

    final inspection = await VehiclePhotoInspector.inspect(file.path);
    if (!mounted) {
      File(file.path).delete().ignore();
      return;
    }
    _controller?.pausePreview().ignore();
    setState(() {
      _reviewPath = file.path;
      _inspection = inspection;
      _phase = _Phase.review;
    });
  }

  void _retake() {
    _discardReview();
    _backToLive();
  }

  void _use() {
    final path = _reviewPath;
    if (path == null || !(_inspection?.isUsable ?? false)) return;
    _reviewPath = null;
    _inspection = null;
    widget.onCaptured(_current.requirement.type, path);

    if (_shot + 1 >= widget.shots.length) {
      Navigator.of(context).pop();
      return;
    }
    _shot++;
    _backToLive();
  }

  void _backToLive() {
    final controller = _controller;
    if (controller == null) {
      setState(() => _phase = _Phase.starting);
      _openCamera();
      return;
    }
    controller.resumePreview().ignore();
    setState(() => _phase = _Phase.live);
  }

  Future<void> _toggleTorch() async {
    final controller = _controller;
    final on = _torchOn;
    if (controller == null || on == null) return;
    try {
      await controller.setFlashMode(on ? FlashMode.off : FlashMode.torch);
      if (mounted) setState(() => _torchOn = !on);
    } on CameraException {
      if (mounted) setState(() => _torchOn = null);
    }
  }

  void _fail(String message) {
    if (!mounted) return;
    setState(() {
      _failure = message;
      _phase = _Phase.failed;
    });
  }

  void _discardReview() {
    final path = _reviewPath;
    if (path != null) File(path).delete().ignore();
    _reviewPath = null;
    _inspection = null;
  }

  void _close() => Navigator.of(context).maybePop();

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final reviewPath = _reviewPath;
    final isLive = _phase == _Phase.live || _phase == _Phase.capturing;
    final shot = _current;

    return PopScope(
      canPop: _phase != _Phase.capturing,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _discardReview();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            if (_phase == _Phase.review && reviewPath != null)
              _ReviewImage(path: reviewPath)
            else if (controller != null && controller.value.isInitialized)
              _Preview(controller: controller),
            SafeArea(
              child: Column(
                children: [
                  VehicleCameraTopBar(
                    title: '${widget.kind.label} · Step ${shot.number} of '
                        '${widget.totalSteps}',
                    progress: shot.number / widget.totalSteps,
                    onClose: _close,
                    torchOn: isLive ? _torchOn : null,
                    onToggleTorch: _toggleTorch,
                  ),
                  Expanded(child: _body(shot)),
                  if (isLive)
                    CaptureInstructionPanel(
                      requirement: shot.requirement,
                      isBusy: _phase == _Phase.capturing,
                      onCapture: _capture,
                    ),
                  if (_phase == _Phase.review)
                    CaptureReviewPanel(
                      inspection: _inspection ?? const VehiclePhotoInspection(),
                      isLast: _shot == widget.shots.length - 1,
                      onRetake: _retake,
                      onUse: _use,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(VehicleCameraShot shot) => switch (_phase) {
        _Phase.starting => const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        _Phase.permission => CameraPermissionView(
            access: _access,
            onAllow: _access == CameraAccess.permanentlyDenied
                ? () => openAppSettings()
                : () => _start(request: true),
            onClose: _close,
          ),
        _Phase.failed => CameraMessageView(
            icon: HugeIcons.strokeRoundedAlert02,
            title: 'Camera problem',
            message: _failure,
            actionLabel: 'Try again',
            onAction: () => _start(request: false),
            onClose: _close,
          ),
        _Phase.live ||
        _Phase.capturing =>
          CaptureGuideOverlay(guide: shot.requirement.guide),
        _Phase.review => const SizedBox.shrink(),
      };
}

/// The preview scaled to cover the screen. Cropping only the preview's
/// edges means the saved photo shows at least what the rider framed.
class _Preview extends StatelessWidget {
  const _Preview({required this.controller});

  final CameraController controller;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: 1 / controller.value.aspectRatio,
          height: 1,
          child: CameraPreview(controller),
        ),
      ),
    );
  }
}

/// The captured photo, decoded at screen width rather than full size.
class _ReviewImage extends StatelessWidget {
  const _ReviewImage({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Image.file(
      File(path),
      fit: BoxFit.contain,
      cacheWidth: (size.width * MediaQuery.devicePixelRatioOf(context)).round(),
      semanticLabel: 'Captured photo',
    );
  }
}
