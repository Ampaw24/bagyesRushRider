import 'package:flutter/material.dart';
import 'package:delivery_boy/constant/app_theme.dart';

/// Pickup → drop-off shown as a two-point vertical timeline, giving each
/// address its own line instead of squeezing both into one truncated row.
class RiderRouteSummary extends StatelessWidget {
  final String? pickup;
  final String? dropoff;

  /// Replaces the drop-off label, e.g. "3 stops" for a multi-stop order.
  final String? dropoffLabel;

  const RiderRouteSummary({
    super.key,
    required this.pickup,
    required this.dropoff,
    this.dropoffLabel,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final dot = w * 0.026;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline rail: pickup dot, connector, drop-off dot.
          Padding(
            padding: EdgeInsets.symmetric(vertical: w * 0.012),
            child: Column(
              children: [
                _Dot(size: dot, color: AppColors.success),
                Expanded(
                  child: Container(
                    width: w * 0.004,
                    margin: EdgeInsets.symmetric(vertical: w * 0.008),
                    color: AppColors.border,
                  ),
                ),
                _Dot(size: dot, color: AppColors.primary),
              ],
            ),
          ),
          SizedBox(width: w * 0.03),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Stop(
                  label: 'Pickup',
                  value: pickup ?? 'Pickup not provided',
                  isMissing: pickup == null,
                ),
                SizedBox(height: w * 0.03),
                _Stop(
                  label: 'Drop-off',
                  value: dropoffLabel ?? dropoff ?? 'Drop-off not provided',
                  isMissing: dropoffLabel == null && dropoff == null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final double size;
  final Color color;

  const _Dot({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(color: color, width: size * 0.3),
      ),
    );
  }
}

class _Stop extends StatelessWidget {
  final String label;
  final String value;
  final bool isMissing;

  const _Stop({
    required this.label,
    required this.value,
    required this.isMissing,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: w * 0.028,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: w * 0.005),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: w * 0.034,
            fontWeight: FontWeight.w500,
            height: 1.3,
            color: isMissing ? AppColors.textHint : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
