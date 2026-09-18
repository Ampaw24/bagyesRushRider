import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Spacing and type scale for the verification screens.
///
/// Derived from the screen, but measured against a width capped at
/// [maxContentWidth] so tablets and landscape get a readable column rather
/// than stretched text and oversized gaps.
class KycMetrics {
  static const maxContentWidth = 600.0;

  final double gutter;
  final double gap;
  final double radius;
  final double iconBadge;
  final double titleSize;
  final double bodySize;
  final double captionSize;

  const KycMetrics._({
    required this.gutter,
    required this.gap,
    required this.radius,
    required this.iconBadge,
    required this.titleSize,
    required this.bodySize,
    required this.captionSize,
  });

  factory KycMetrics.of(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final base = math.min(size.width, maxContentWidth);
    return KycMetrics._(
      gutter: (base * 0.05).clamp(16.0, 28.0),
      gap: (size.height * 0.02).clamp(12.0, 24.0),
      radius: (base * 0.035).clamp(10.0, 16.0),
      iconBadge: (base * 0.11).clamp(40.0, 56.0),
      titleSize: (base * 0.045).clamp(16.0, 20.0),
      bodySize: (base * 0.037).clamp(13.0, 16.0),
      captionSize: (base * 0.032).clamp(12.0, 14.0),
    );
  }
}
