import 'package:flutter/material.dart';

import 'package:delivery_boy/constant/app_theme.dart';

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];
const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

bool isSameDay(DateTime a, DateTime b) {
  final la = a.toLocal(), lb = b.toLocal();
  return la.year == lb.year && la.month == lb.month && la.day == lb.day;
}

String _dayLabel(DateTime date) {
  final local = date.toLocal();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(local.year, local.month, local.day);
  final diff = today.difference(day).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  final base = '${_weekdays[local.weekday - 1]}, ${local.day} ${_months[local.month - 1]}';
  return local.year == now.year ? base : '$base ${local.year}';
}

/// Centered "Today" / "Yesterday" / "Mon, 12 Sep" chip between days.
class RiderChatDaySeparator extends StatelessWidget {
  const RiderChatDaySeparator({super.key, required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: w * 0.03),
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: w * 0.03, vertical: w * 0.01),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(
            _dayLabel(date),
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: (w * 0.029).clamp(11.0, 13.0),
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Peer-side bubble with three pulsing dots, shown while the peer types.
/// Static dots when the OS asks for reduced motion.
class RiderTypingIndicator extends StatefulWidget {
  const RiderTypingIndicator({super.key});

  @override
  State<RiderTypingIndicator> createState() => _RiderTypingIndicatorState();
}

class _RiderTypingIndicatorState extends State<RiderTypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.of(context).disableAnimations) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final dot = (w * 0.018).clamp(6.0, 8.0);

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(top: w * 0.015),
        padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: w * 0.032),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(18),
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (_, __) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < 3; i++) ...[
                if (i > 0) SizedBox(width: dot * 0.6),
                Opacity(
                  opacity: _opacityFor(i),
                  child: Container(
                    width: dot,
                    height: dot,
                    decoration: const BoxDecoration(
                      color: AppColors.textSecondary,
                      shape: BoxShape.circle,
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

  /// Each dot peaks a third of a cycle after the previous one.
  double _opacityFor(int index) {
    if (!_controller.isAnimating) return 0.6;
    final phase = (_controller.value - index / 3) % 1.0;
    final wave = phase < 0.5 ? phase * 2 : (1 - phase) * 2;
    return 0.3 + 0.7 * wave;
  }
}
