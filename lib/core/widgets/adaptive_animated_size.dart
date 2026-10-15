import 'package:flutter/widgets.dart';

/// [AnimatedSize] that steps aside when the platform asks for reduced
/// motion, so the size simply jumps. It can't be handed a zero duration
/// instead: its animation would then finish — and mark it for layout again —
/// in the middle of its own layout, which Flutter rejects.
class AdaptiveAnimatedSize extends StatelessWidget {
  final Duration duration;
  final Curve curve;
  final AlignmentGeometry alignment;
  final Widget child;

  const AdaptiveAnimatedSize({
    super.key,
    required this.duration,
    this.curve = Curves.linear,
    this.alignment = Alignment.center,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return AnimatedSize(
      duration: duration,
      curve: curve,
      alignment: alignment,
      child: child,
    );
  }
}
