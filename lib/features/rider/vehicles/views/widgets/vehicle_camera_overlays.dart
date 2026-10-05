import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:delivery_boy/constant/app_theme.dart';
import 'package:delivery_boy/features/rider/kyc/views/widgets/kyc_metrics.dart';
import 'package:delivery_boy/features/rider/kyc/views/widgets/kyc_section_layout.dart';
import 'package:delivery_boy/features/rider/vehicles/capture/camera_access.dart';
import 'package:delivery_boy/features/rider/vehicles/capture/vehicle_photo_inspector.dart';
import 'package:delivery_boy/features/rider/vehicles/model/vehicle_capture.dart';

/// Panels sit on the live preview, so they get a dark scrim rather than a
/// surface colour.
final _scrim = Colors.black.withValues(alpha: 0.6);
final _mutedWhite = Colors.white.withValues(alpha: 0.8);

/// Dims everything outside the frame the vehicle should fill. The frame's
/// proportions come from the capture — tall for a motorbike head-on, wide
/// side-on — and its size from the preview, never fixed pixels.
class CaptureGuideOverlay extends StatelessWidget {
  const CaptureGuideOverlay({super.key, required this.guide});

  final CaptureGuide guide;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Sized to the space between the top bar and the instructions, so
          // neither ever covers part of the frame.
          final size = constraints.biggest;
          final width = math.min(
            size.width * guide.maxWidthFraction,
            size.height * 0.9 * guide.aspectRatio,
          );
          final rect = Rect.fromCenter(
            center: size.center(Offset.zero),
            width: width,
            height: width / guide.aspectRatio,
          );
          return CustomPaint(size: size, painter: _GuidePainter(rect));
        },
      ),
    );
  }
}

class _GuidePainter extends CustomPainter {
  _GuidePainter(this.frame);

  final Rect frame;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = Radius.circular(frame.shortestSide * 0.06);
    final hole = RRect.fromRectAndRadius(frame, radius);
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Offset.zero & size),
        Path()..addRRect(hole),
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.5),
    );
    canvas.drawRRect(
      hole,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(2, frame.shortestSide * 0.012)
        ..color = Colors.white.withValues(alpha: 0.9),
    );
  }

  @override
  bool shouldRepaint(covariant _GuidePainter old) => old.frame != frame;
}

/// Close, step counter with progress, and the flash toggle.
class VehicleCameraTopBar extends StatelessWidget {
  const VehicleCameraTopBar({
    super.key,
    required this.title,
    required this.progress,
    required this.onClose,
    this.torchOn,
    this.onToggleTorch,
  });

  final String title;
  final double progress;
  final VoidCallback onClose;

  /// Null hides the toggle — no flash, or no live preview.
  final bool? torchOn;
  final VoidCallback? onToggleTorch;

  @override
  Widget build(BuildContext context) {
    final m = KycMetrics.of(context);
    return ColoredBox(
      color: _scrim,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          m.gutter * 0.5,
          0,
          m.gutter * 0.5,
          m.gap * 0.5,
        ),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: 'Close camera',
                  onPressed: onClose,
                  icon: const Icon(HugeIcons.strokeRoundedCancel01),
                  color: Colors.white,
                ),
                Expanded(
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: m.bodySize,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                // Same width either way, so the title stays centred.
                Opacity(
                  opacity: torchOn == null ? 0 : 1,
                  child: IconButton(
                    tooltip:
                        torchOn == true ? 'Turn flash off' : 'Turn flash on',
                    onPressed: torchOn == null ? null : onToggleTorch,
                    icon: Icon(torchOn == true
                        ? HugeIcons.strokeRoundedFlash
                        : HugeIcons.strokeRoundedFlashOff),
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            Semantics(
              label: title,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(m.radius),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: m.gap * 0.2,
                  backgroundColor: Colors.white.withValues(alpha: 0.25),
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// What to capture, what must be visible, and the shutter.
class CaptureInstructionPanel extends StatelessWidget {
  const CaptureInstructionPanel({
    super.key,
    required this.requirement,
    required this.isBusy,
    required this.onCapture,
  });

  final VehicleCaptureRequirement requirement;
  final bool isBusy;
  final VoidCallback onCapture;

  @override
  Widget build(BuildContext context) {
    final m = KycMetrics.of(context);
    return _Panel(
      children: [
        Text(
          requirement.title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: m.titleSize,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        Text(
          requirement.instruction,
          textAlign: TextAlign.center,
          style:
              TextStyle(fontSize: m.bodySize, color: _mutedWhite, height: 1.3),
        ),
        if (requirement.checks.isNotEmpty) ...[
          SizedBox(height: m.gap * 0.4),
          Text(
            requirement.checks.join('  ·  '),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: m.captionSize, color: _mutedWhite),
          ),
        ],
        SizedBox(height: m.gap),
        _ShutterButton(isBusy: isBusy, onPressed: onCapture),
      ],
    );
  }
}

class _ShutterButton extends StatelessWidget {
  const _ShutterButton({required this.isBusy, required this.onPressed});

  final bool isBusy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final diameter =
        (MediaQuery.sizeOf(context).shortestSide * 0.18).clamp(56.0, 84.0);
    return Semantics(
      button: true,
      enabled: !isBusy,
      label: 'Take photo',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: isBusy ? null : onPressed,
        child: Container(
          width: diameter,
          height: diameter,
          padding: EdgeInsets.all(diameter * 0.07),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: diameter * 0.06),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isBusy ? Colors.white54 : Colors.white,
            ),
            child: isBusy
                ? Padding(
                    padding: EdgeInsets.all(diameter * 0.22),
                    child: const CircularProgressIndicator(
                      color: AppColors.textPrimary,
                    ),
                  )
                : null,
          ),
        ),
      ),
    );
  }
}

/// Shown over the captured photo: anything wrong with it, then retake or
/// use it.
class CaptureReviewPanel extends StatelessWidget {
  const CaptureReviewPanel({
    super.key,
    required this.inspection,
    required this.isLast,
    required this.onRetake,
    required this.onUse,
  });

  final VehiclePhotoInspection inspection;
  final bool isLast;
  final VoidCallback onRetake;
  final VoidCallback onUse;

  @override
  Widget build(BuildContext context) {
    final m = KycMetrics.of(context);
    final problem = inspection.problem;
    final notes = [
      if (problem != null) (problem, AppColors.error),
      for (final issue in inspection.issues) (issue.message, AppColors.accent),
    ];

    return _Panel(
      children: [
        Text(
          problem == null ? 'Check your photo' : "This photo can't be used",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: m.titleSize,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        if (notes.isEmpty)
          Text(
            'Make sure the whole vehicle is in the photo and nothing is '
            'blurred or cut off.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: m.bodySize, color: _mutedWhite),
          ),
        for (final (text, color) in notes) ...[
          SizedBox(height: m.gap * 0.4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(HugeIcons.strokeRoundedAlert02,
                  size: m.bodySize * 1.2, color: color),
              SizedBox(width: m.gutter * 0.4),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(fontSize: m.bodySize, color: Colors.white),
                ),
              ),
            ],
          ),
        ],
        SizedBox(height: m.gap),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onRetake,
                icon: const Icon(HugeIcons.strokeRoundedRefresh),
                label: const Text('Retake'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white),
                ),
              ),
            ),
            if (problem == null) ...[
              SizedBox(width: m.gutter * 0.5),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onUse,
                  icon: const Icon(HugeIcons.strokeRoundedTick02),
                  label: Text(isLast ? 'Use photo' : 'Use & next'),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// Camera permission missing — denied, off in Settings, or restricted.
class CameraPermissionView extends StatelessWidget {
  const CameraPermissionView({
    super.key,
    required this.access,
    required this.onAllow,
    required this.onClose,
  });

  final CameraAccess access;
  final VoidCallback onAllow;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final (title, message, action) = switch (access) {
      CameraAccess.permanentlyDenied => (
          'Camera permission is turned off',
          'Enable camera access for BagyesRIDER in Settings to take your '
              'vehicle photos.',
          'Open Settings',
        ),
      CameraAccess.restricted => (
          'Camera unavailable',
          'Camera access is restricted on this device, for example by '
              'parental controls or device management.',
          null,
        ),
      _ => (
          'Camera access required',
          'Vehicle verification needs live photos taken with your camera.',
          'Allow camera',
        ),
    };
    return CameraMessageView(
      icon: HugeIcons.strokeRoundedCameraOff01,
      title: title,
      message: message,
      actionLabel: action,
      onAction: onAllow,
      onClose: onClose,
    );
  }
}

/// A centred message with an optional action, for the camera's
/// non-preview states.
class CameraMessageView extends StatelessWidget {
  const CameraMessageView({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    required this.onClose,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final VoidCallback onClose;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final m = KycMetrics.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(m.gutter),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: m.iconBadge),
            SizedBox(height: m.gap),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: m.titleSize,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            SizedBox(height: m.gap * 0.4),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: m.bodySize, color: _mutedWhite),
            ),
            SizedBox(height: m.gap),
            if (actionLabel != null)
              ElevatedButton(onPressed: onAction, child: Text(actionLabel!)),
            TextButton(
              onPressed: onClose,
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              child: const Text('Not now'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final m = KycMetrics.of(context);
    return Padding(
      padding: EdgeInsets.all(m.gutter * 0.5),
      child: KycContentWidth(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: _scrim,
            borderRadius: BorderRadius.circular(m.radius),
          ),
          child: Padding(
            padding: EdgeInsets.all(m.gutter * 0.75),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ),
      ),
    );
  }
}
