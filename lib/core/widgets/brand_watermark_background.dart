import 'package:flutter/material.dart';

import 'package:gopady_rider/constant/app_theme.dart';
import 'brand_pattern_background.dart';
import 'skyline_watermark.dart';

/// Light-surface take on the splash/onboarding watermarks: the same mark
/// pattern and bottom skyline, tinted brand green on [AppColors.cream] so form
/// screens keep their legibility. The watermarks sit behind [child].
class BrandWatermarkBackground extends StatelessWidget {
  const BrandWatermarkBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(
          child: BrandPatternBackground(
            backgroundColor: AppColors.cream,
            markColor: AppColors.primary,
            markOpacity: 0.06,
          ),
        ),
        const Align(
          alignment: Alignment.bottomCenter,
          child: SkylineWatermark(
            color: AppColors.primary,
            opacity: 0.12,
            maxHeightFactor: 0.25,
          ),
        ),
        Positioned.fill(child: child),
      ],
    );
  }
}
