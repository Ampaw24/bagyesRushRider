import 'package:flutter/material.dart';

/// Looping 0.9 ↔ 1.1 scale pulse while [active] — the app's "live" cue
/// (the online toggle, in-progress orders). Holds still when the platform
/// asks for reduced motion.
class PulseScale extends StatefulWidget {
  final bool active;
  final Widget child;

  const PulseScale({super.key, required this.active, required this.child});

  @override
  State<PulseScale> createState() => _PulseScaleState();
}

class _PulseScaleState extends State<PulseScale>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  );
  late final Animation<double> _scale = Tween<double>(begin: 0.9, end: 1.1)
      .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncPulse();
  }

  @override
  void didUpdateWidget(PulseScale oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncPulse();
  }

  void _syncPulse() {
    final shouldPulse =
        widget.active && !MediaQuery.disableAnimationsOf(context);
    if (shouldPulse) {
      if (!_ctrl.isAnimating) _ctrl.repeat(reverse: true);
    } else {
      _ctrl
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Keeps the per-frame repaint to the pulsing child rather than whatever
    // card or bar it sits in.
    return RepaintBoundary(
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}
