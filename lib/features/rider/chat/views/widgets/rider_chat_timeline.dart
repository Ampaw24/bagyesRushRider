import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:delivery_boy/constant/app_theme.dart';
import 'package:delivery_boy/features/rider/chat/views/widgets/rider_chat_avatar.dart';

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
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
  final base =
      '${_weekdays[local.weekday - 1]}, ${local.day} ${_months[local.month - 1]}';
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
          padding:
              EdgeInsets.symmetric(horizontal: w * 0.03, vertical: w * 0.01),
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

/// Peer-side bubble with three bouncing dots, shown while the peer types.
/// Fades in on appearance; dots stay static when the OS asks for reduced
/// motion.
class RiderTypingIndicator extends StatefulWidget {
  const RiderTypingIndicator(
      {super.key, required this.peerName, this.peerPhotoUrl});

  final String peerName;
  final String? peerPhotoUrl;

  @override
  State<RiderTypingIndicator> createState() => _RiderTypingIndicatorState();
}

class _RiderTypingIndicatorState extends State<RiderTypingIndicator>
    with SingleTickerProviderStateMixin {
  static const _dotCount = 3;

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
    final big = Radius.circular((w * 0.045).clamp(16.0, 20.0));
    final avatarSize = (w * 0.08).clamp(28.0, 36.0);

    return Align(
      alignment: Alignment.centerLeft,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        builder: (_, t, child) => Opacity(opacity: t, child: child),
        child: Padding(
          padding: EdgeInsets.only(top: w * 0.015),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              RiderChatAvatar(
                name: widget.peerName,
                photoUrl: widget.peerPhotoUrl,
                size: avatarSize,
              ),
              SizedBox(width: w * 0.02),
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: w * 0.04, vertical: w * 0.032),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: AppColors.border),
                  // Peer-side tail, matching [RiderMessageBubble].
                  borderRadius: BorderRadius.only(
                    topLeft: big,
                    topRight: big,
                    bottomRight: big,
                    bottomLeft: const Radius.circular(6),
                  ),
                ),
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (_, __) => Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < _dotCount; i++) ...[
                        if (i > 0) SizedBox(width: dot * 0.7),
                        _BouncingDot(size: dot, phase: _phaseFor(i)),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 0→1→0 wave, each dot a third of a cycle behind the previous one.
  double _phaseFor(int index) {
    if (!_controller.isAnimating) return 0;
    final t = (_controller.value - index / _dotCount) % 1.0;
    return math.sin(t * math.pi).clamp(0.0, 1.0);
  }
}

class _BouncingDot extends StatelessWidget {
  const _BouncingDot({required this.size, required this.phase});

  final double size;
  final double phase;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(0, -size * 0.6 * phase),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Color.lerp(AppColors.textHint, AppColors.primary, phase),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
