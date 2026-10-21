import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:gopady_rider/constant/app_theme.dart';
import 'package:gopady_rider/constant/asset_images.dart';

/// Solid backdrop (brand green by default) with the GoPady mark repeated as large, tonal
/// watermarks bleeding off the edges. Marks are placed by alignment and sized
/// from the shorter screen side, so the composition is identical on every
/// screen size and orientation.
class BrandPatternBackground extends StatelessWidget {
  const BrandPatternBackground({
    super.key,
    this.backgroundColor = AppColors.primary,
    this.markColor = Colors.white,
    this.markOpacity = 0.07,
  });

  final Color backgroundColor;
  final Color markColor;
  final double markOpacity;

  // (alignment, size as a share of the shorter side, rotation in turns)
  static const List<(Alignment, double, double)> _marks = [
    (Alignment(-1.05, -0.9), 0.6, -0.06),
    (Alignment(1.1, -0.55), 0.5, 0.07),
    (Alignment(-1.15, -0.1), 0.42, 0.04),
    (Alignment(1.2, 0.2), 0.55, -0.05),
    (Alignment(-0.7, 0.45), 0.36, 0.08),
  ];

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: backgroundColor,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final unit = constraints.biggest.shortestSide;
          return ExcludeSemantics(
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                for (final (alignment, scale, turns) in _marks)
                  Align(
                    alignment: alignment,
                    child: Transform.rotate(
                      angle: turns * 2 * math.pi,
                      child: Image.asset(
                        AssetImages.gopadyIconYellow,
                        width: unit * scale,
                        fit: BoxFit.contain,
                        color: markColor.withValues(alpha: markOpacity),
                        colorBlendMode: BlendMode.srcIn,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
