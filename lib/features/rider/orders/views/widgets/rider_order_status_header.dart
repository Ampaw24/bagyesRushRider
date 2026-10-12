import 'package:flutter/material.dart';
import 'package:delivery_boy/constant/app_theme.dart';
import 'package:delivery_boy/core/widgets/pulse_scale.dart';
import 'package:delivery_boy/features/rider/orders/views/widgets/rider_me_order_status.dart';

/// Full-width band leading an order card with the order's status: its icon,
/// label and [subtitle] on a light tint of the status colour, plus a
/// pulsing "Live" cue while the order is in progress ([isLive]).
///
/// Stateless on purpose — a new [status] (e.g. from a realtime
/// `order.status` event) cross-fades through the implicit animations below.
class RiderOrderStatusHeader extends StatelessWidget {
  final String status;
  final bool isLive;

  /// Second line under the label, e.g. when the order was placed. Hidden
  /// when empty.
  final String subtitle;

  /// Defaults to the order card's inset; the detail sheet passes its own
  /// gutter so the band lines up with the content below it.
  final EdgeInsetsGeometry? padding;

  const RiderOrderStatusHeader({
    super.key,
    required this.status,
    required this.isLive,
    this.subtitle = '',
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 300);
    final color = riderMeOrderStatusColor(status);
    final iconBox = (w * 0.09).clamp(32.0, 44.0);

    return AnimatedContainer(
      duration: duration,
      curve: Curves.easeOutCubic,
      color: color.withValues(alpha: 0.08),
      padding: padding ??
          EdgeInsets.symmetric(horizontal: w * 0.04, vertical: w * 0.03),
      child: Row(
        children: [
          Container(
            width: iconBox,
            height: iconBox,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.card,
              shape: BoxShape.circle,
            ),
            child: AnimatedSwitcher(
              duration: duration,
              transitionBuilder: (child, animation) => ScaleTransition(
                scale: animation,
                child: FadeTransition(opacity: animation, child: child),
              ),
              child: Icon(
                riderMeOrderStatusIcon(status),
                key: ValueKey(status),
                size: iconBox * 0.5,
                color: color,
              ),
            ),
          ),
          SizedBox(width: w * 0.03),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedSwitcher(
                  duration: duration,
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  // The new label rolls up into place as the old one leaves
                  // upwards, like a ticker.
                  transitionBuilder: (child, animation) {
                    final incoming = child.key == ValueKey(status);
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: Offset(0, incoming ? 0.4 : -0.4),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  // Default is centred, which shifts a shorter label sideways
                  // mid-fade.
                  layoutBuilder: (current, previous) => Stack(
                    alignment: Alignment.centerLeft,
                    children: [...previous, if (current != null) current],
                  ),
                  child: Text(
                    riderMeOrderStatusLabel(status),
                    key: ValueKey(status),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: (w * 0.038).clamp(13.0, 17.0),
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                if (subtitle.isNotEmpty) ...[
                  SizedBox(height: w * 0.005),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: (w * 0.03).clamp(11.0, 13.0),
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (isLive) ...[
            SizedBox(width: w * 0.02),
            _LiveIndicator(color: color, duration: duration),
          ],
        ],
      ),
    );
  }
}

class _LiveIndicator extends StatelessWidget {
  final Color color;
  final Duration duration;

  const _LiveIndicator({required this.color, required this.duration});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final dot = (w * 0.02).clamp(6.0, 9.0);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PulseScale(
          active: true,
          child: AnimatedContainer(
            duration: duration,
            width: dot,
            height: dot,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        ),
        SizedBox(width: w * 0.012),
        Text(
          'Live',
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: (w * 0.03).clamp(11.0, 13.0),
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
