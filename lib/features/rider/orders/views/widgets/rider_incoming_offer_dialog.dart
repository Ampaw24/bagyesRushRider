import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:delivery_boy/constant/app_theme.dart';
import 'package:delivery_boy/core/widgets/app_gradient_button.dart';
import 'package:delivery_boy/features/rider/orders/models/rider_me_order_model.dart';
import 'package:delivery_boy/features/rider/orders/providers/rider_me_order_providers.dart';

/// How an [RiderIncomingOfferDialog] ended. Closing it any other way (back
/// button) pops null: the rider chose neither, and the offer stays in the New
/// tab.
enum IncomingOfferResult { accepted, declined, expired }

/// Full-attention prompt for a new delivery offer: route, fare, a countdown to
/// the offer's expiry, and Accept / Decline. Shown by
/// `RiderIncomingOfferListener`, which also rings while it is open.
class RiderIncomingOfferDialog extends ConsumerStatefulWidget {
  final RiderMeOfferModel offer;

  const RiderIncomingOfferDialog({super.key, required this.offer});

  @override
  ConsumerState<RiderIncomingOfferDialog> createState() =>
      _RiderIncomingOfferDialogState();
}

class _RiderIncomingOfferDialogState
    extends ConsumerState<RiderIncomingOfferDialog> {
  Timer? _tick;
  late final DateTime? _expiresAt = widget.offer.expiresAtTime;

  /// How long the offer had left when the dialog opened — the denominator for
  /// the progress bar, so it starts full whatever the server's window is.
  late final Duration? _window = _expiresAt?.difference(DateTime.now());
  Duration? _remaining;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _remaining = _window;
    if (_expiresAt != null) {
      _tick = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
    }
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  void _onTick() {
    final remaining = _expiresAt!.difference(DateTime.now());
    if (remaining <= Duration.zero) {
      _tick?.cancel();
      // Mid-request, the server's answer decides — let that finish.
      if (!_busy && mounted)
        Navigator.pop(context, IncomingOfferResult.expired);
      return;
    }
    setState(() => _remaining = remaining);
  }

  Future<void> _accept() async {
    setState(() => _busy = true);
    final ok =
        await ref.read(riderMeOffersProvider.notifier).accept(widget.offer.id);
    if (!mounted) return;
    if (ok) {
      HapticFeedback.mediumImpact();
      Navigator.pop(context, IncomingOfferResult.accepted);
    } else {
      // Stays open: the failure may just be the network, and the offer is
      // still live. A genuinely taken or expired offer ends via the countdown
      // or the rider declining; the server's message says which it is.
      final message = ref.read(riderMeOffersProvider).actionMessage ??
          "Couldn't accept this offer. Please try again.";
      setState(() => _busy = false);
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  Future<void> _decline() async {
    setState(() => _busy = true);
    await ref.read(riderMeOffersProvider.notifier).decline(widget.offer.id);
    if (!mounted) return;
    Navigator.pop(context, IncomingOfferResult.declined);
  }

  static String _clock(Duration d) {
    final seconds = d.inSeconds.clamp(0, 359999);
    return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final offer = widget.offer;
    // Sizes scale with the screen width but stop growing at a large-phone
    // width, so tablets and landscape don't get oversized text.
    final screenWidth = MediaQuery.sizeOf(context).width;
    final w = math.min(screenWidth, 480.0);
    final gap = w * 0.03;

    final remaining = _remaining;
    final window = _window;
    final progress =
        (remaining != null && window != null && window > Duration.zero)
            ? (remaining.inMilliseconds / window.inMilliseconds).clamp(0.0, 1.0)
            : null;

    return Dialog(
      backgroundColor: AppColors.card,
      insetPadding:
          EdgeInsets.symmetric(horizontal: screenWidth * 0.05, vertical: gap),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(w * 0.04)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: w),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(w * 0.05),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  _OfferIcon(isParcel: offer.isParcel),
                  SizedBox(width: gap),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'New Delivery Request',
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: w * 0.048,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          offer.orderReference ?? '#${offer.id}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: w * 0.035,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (progress != null) ...[
                SizedBox(height: gap),
                ClipRRect(
                  borderRadius: BorderRadius.circular(w * 0.01),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: w * 0.015,
                    color: AppColors.primary,
                    backgroundColor: AppColors.divider,
                  ),
                ),
                SizedBox(height: w * 0.015),
                Text(
                  'Expires in ${_clock(remaining!)}',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: w * 0.032,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              SizedBox(height: gap),
              _StopRow(
                icon: HugeIcons.strokeRoundedCheckmarkCircle01,
                color: AppColors.success,
                label: 'Pickup',
                address: offer.pickupAddress ?? 'Pickup not provided',
              ),
              SizedBox(height: gap * 0.7),
              _StopRow(
                icon: HugeIcons.strokeRoundedLocation01,
                color: AppColors.primary,
                label: 'Dropoff',
                address: offer.dropoffAddress ?? 'Drop-off not provided',
              ),
              if (offer.distanceKm != null || offer.estimatedFare != null) ...[
                SizedBox(height: gap),
                Row(
                  children: [
                    if (offer.distanceKm != null)
                      Expanded(
                        child: _Stat(
                          label: 'Distance',
                          value: '${offer.distanceKm!.toStringAsFixed(1)} km',
                        ),
                      ),
                    if (offer.estimatedFare != null)
                      Expanded(
                        child: _Stat(
                          label: 'Est. Fare',
                          value:
                              'GHS ${offer.estimatedFare!.toStringAsFixed(2)}',
                        ),
                      ),
                  ],
                ),
              ],
              SizedBox(height: gap * 1.4),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _busy ? null : _decline,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        side: const BorderSide(color: AppColors.border),
                        minimumSize: Size.fromHeight(w * 0.125),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(w * 0.03),
                        ),
                      ),
                      child: Text(
                        'Decline',
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: w * 0.04,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: gap),
                  Expanded(
                    flex: 2,
                    child: AppGradientButton(
                      label: 'Accept',
                      isLoading: _busy,
                      onPressed: _busy ? null : _accept,
                      height: w * 0.125,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The dialog's lead icon: the notification bell, or — for a parcel
/// delivery — the parcel box, so the rider can tell the two apart at a glance.
class _OfferIcon extends StatelessWidget {
  final bool isParcel;

  const _OfferIcon({required this.isParcel});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    if (isParcel) {
      final side = w * 0.14;
      return Semantics(
        label: 'Parcel delivery',
        child: Image.asset(
          'assets/images/parcel_box.jpg',
          width: side,
          height: side,
          fit: BoxFit.contain,
          // Bound the decode: the box is only ever shown this small.
          cacheWidth: (side * MediaQuery.devicePixelRatioOf(context)).round(),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(w * 0.025),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        HugeIcons.strokeRoundedNotification01,
        color: AppColors.primary,
        size: w * 0.06,
      ),
    );
  }
}

class _StopRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String address;

  const _StopRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.address,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: w * 0.055),
        SizedBox(width: w * 0.025),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: w * 0.03,
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                address,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: w * 0.038,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;

  const _Stat({required this.label, required this.value});

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
            fontSize: w * 0.03,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: w * 0.045,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
