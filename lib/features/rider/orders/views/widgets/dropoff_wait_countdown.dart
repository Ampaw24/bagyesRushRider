import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:delivery_boy/constant/app_theme.dart';
import 'package:delivery_boy/features/rider/orders/models/rider_me_order_model.dart';

/// `mm:ss`, rounded up so the clock never shows 00:00 while time remains.
String formatWaitClock(Duration remaining) {
  final seconds = (remaining.inMilliseconds / 1000).ceil();
  final mm = (seconds ~/ 60).toString().padLeft(2, '0');
  final ss = (seconds % 60).toString().padLeft(2, '0');
  return '$mm:$ss';
}

/// Ticks once a second until [wait] runs out, rebuilding only [builder]'s
/// subtree. Remaining time is recomputed from the clock on every tick, so it
/// stays correct after the app has been in the background.
class WaitCountdownBuilder extends StatefulWidget {
  final RiderMeOrderWait wait;
  final Widget Function(BuildContext context, Duration remaining) builder;

  const WaitCountdownBuilder({
    super.key,
    required this.wait,
    required this.builder,
  });

  @override
  State<WaitCountdownBuilder> createState() => _WaitCountdownBuilderState();
}

class _WaitCountdownBuilderState extends State<WaitCountdownBuilder> {
  Timer? _timer;
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(WaitCountdownBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.wait != widget.wait) _sync();
  }

  void _sync() {
    _timer?.cancel();
    _remaining = widget.wait.remainingAt(DateTime.now());
    if (_remaining > Duration.zero) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    }
  }

  void _tick() {
    final remaining = widget.wait.remainingAt(DateTime.now());
    setState(() => _remaining = remaining);
    if (remaining == Duration.zero) _timer?.cancel();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _remaining);
}

/// Shown while the rider waits at a drop-off or stop. Counts down the wait
/// window; when it runs out it offers the way out via [onGiveUp] (labelled
/// [giveUpLabel]).
class DropoffWaitBanner extends StatelessWidget {
  final Duration remaining;

  /// Full length of the window — drives the progress bar; omitted when the
  /// server didn't send both ends.
  final Duration? total;
  final VoidCallback? onGiveUp;
  final String giveUpLabel;
  final String waitingSubtitle;
  final String expiredSubtitle;

  const DropoffWaitBanner({
    super.key,
    required this.remaining,
    this.total,
    this.onGiveUp,
    this.giveUpLabel = "Can't reach customer",
    this.waitingSubtitle = 'The customer has been told you are here.',
    this.expiredSubtitle =
        'Still no answer? You can mark the customer unreachable.',
  });

  bool get _expired => remaining <= Duration.zero;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final motion = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 250);
    final tint = _expired ? AppColors.error : AppColors.warning;

    return AnimatedContainer(
      duration: motion,
      padding: EdgeInsets.all(w * 0.035),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(w * 0.03),
        border: Border.all(color: tint.withValues(alpha: 0.3)),
      ),
      child: AnimatedSize(
        duration: motion,
        alignment: Alignment.topCenter,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _WaitIcon(tint: tint, pulsing: !_expired),
                SizedBox(width: w * 0.03),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: motion,
                    child: _WaitMessage(
                      key: ValueKey(_expired),
                      expired: _expired,
                      subtitle: _expired ? expiredSubtitle : waitingSubtitle,
                    ),
                  ),
                ),
                if (!_expired) ...[
                  SizedBox(width: w * 0.02),
                  Semantics(
                    label: '${remaining.inMinutes} minutes '
                        '${remaining.inSeconds % 60} seconds left',
                    excludeSemantics: true,
                    child: Text(
                      formatWaitClock(remaining),
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: (w * 0.055).clamp(18.0, 26.0),
                        fontWeight: FontWeight.w700,
                        color: tint,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ],
              ],
            ),
            if (!_expired && total != null && total! > Duration.zero) ...[
              SizedBox(height: w * 0.03),
              _WaitProgress(
                fraction: remaining.inMilliseconds / total!.inMilliseconds,
                color: tint,
                animate: motion != Duration.zero,
              ),
            ],
            if (_expired && onGiveUp != null) ...[
              SizedBox(height: w * 0.03),
              OutlinedButton(
                onPressed: onGiveUp,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  minimumSize: Size.fromHeight((w * 0.11).clamp(44.0, 52.0)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(w * 0.03),
                  ),
                ),
                child: Text(
                  giveUpLabel,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _WaitMessage extends StatelessWidget {
  final bool expired;
  final String subtitle;

  const _WaitMessage({
    super.key,
    required this.expired,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          expired ? 'Wait time is over' : 'Waiting for customer',
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: (w * 0.038).clamp(14.0, 17.0),
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          subtitle,
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: (w * 0.032).clamp(12.0, 14.0),
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// Bar that glides to each new value over one tick instead of stepping.
class _WaitProgress extends StatelessWidget {
  final double fraction;
  final Color color;
  final bool animate;

  const _WaitProgress({
    required this.fraction,
    required this.color,
    required this.animate,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return TweenAnimationBuilder<double>(
      tween: Tween(end: fraction.clamp(0.0, 1.0)),
      duration: animate ? const Duration(seconds: 1) : Duration.zero,
      curve: Curves.linear,
      builder: (_, value, __) => ClipRRect(
        borderRadius: BorderRadius.circular(w * 0.01),
        child: LinearProgressIndicator(
          value: value,
          minHeight: w * 0.015,
          color: color,
          backgroundColor: color.withValues(alpha: 0.15),
        ),
      ),
    );
  }
}

/// Hourglass that breathes gently while the clock runs; still once the wait
/// is over, or when the user has asked the system to reduce motion.
class _WaitIcon extends StatefulWidget {
  final Color tint;
  final bool pulsing;

  const _WaitIcon({required this.tint, required this.pulsing});

  @override
  State<_WaitIcon> createState() => _WaitIconState();
}

class _WaitIconState extends State<_WaitIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );
  late final Animation<double> _scale = Tween(begin: 1.0, end: 1.12)
      .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncPulse();
  }

  @override
  void didUpdateWidget(_WaitIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncPulse();
  }

  void _syncPulse() {
    final shouldPulse =
        widget.pulsing && !MediaQuery.disableAnimationsOf(context);
    if (shouldPulse) {
      if (!_controller.isAnimating) _controller.repeat(reverse: true);
    } else {
      _controller.animateTo(0, duration: Duration.zero);
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
    return ScaleTransition(
      scale: _scale,
      child: Container(
        width: w * 0.1,
        height: w * 0.1,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: widget.tint.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(
          widget.pulsing
              ? HugeIcons.strokeRoundedHourglass
              : HugeIcons.strokeRoundedCallBlocked,
          size: w * 0.055,
          color: widget.tint,
        ),
      ),
    );
  }
}
