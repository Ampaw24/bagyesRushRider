import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:delivery_boy/constant/app_theme.dart';
import 'package:delivery_boy/core/widgets/app_gradient_button.dart';
import 'package:delivery_boy/core/widgets/drag_handle.dart';
import 'package:delivery_boy/features/rider/orders/providers/rider_me_order_providers.dart';
import 'package:delivery_boy/features/rider/shared_widgets/otp_input_field.dart';

/// Collection-code entry, shown right before `POST rider/me/orders/:id/pick-up`
/// on a parcel the customer is receiving.
///
/// The sender was texted a 4-digit code; the rider typing it in is how the
/// sender's side confirms this is the courier their message named. The server
/// locks collection after five wrong codes in ten minutes, so submitting is an
/// explicit tap — never automatic on the fourth digit — and the server's own
/// wording (including the lockout message) is shown as-is.
///
/// Show with `showModalBottomSheet<bool>(isScrollControlled: true,
/// backgroundColor: Colors.transparent, builder: (_) =>
/// PickupCodeSheet(orderId: ...))`. Pops `true` once pickup is confirmed.
class PickupCodeSheet extends ConsumerStatefulWidget {
  final int orderId;

  const PickupCodeSheet({super.key, required this.orderId});

  @override
  ConsumerState<PickupCodeSheet> createState() => _PickupCodeSheetState();
}

class _PickupCodeSheetState extends ConsumerState<PickupCodeSheet> {
  static const _codeLength = 4;

  /// Sizes are proportions of the screen width, but stop growing past a
  /// large-phone width so tablets and landscape get a comfortable sheet
  /// rather than an enormous one.
  static const _maxBaseWidth = 480.0;

  final _codeKey = GlobalKey<OtpInputFieldState>();

  String _code = '';
  bool _submitting = false;
  String? _error;

  bool get _complete => _code.length == _codeLength;

  Future<void> _submit() async {
    if (!_complete || _submitting) return;
    HapticFeedback.mediumImpact();
    setState(() {
      _submitting = true;
      _error = null;
    });

    final notifier = ref.read(riderMeOrdersProvider.notifier);
    final ok = await notifier.pickUpOrder(widget.orderId, pickupPin: _code);
    if (!mounted) return;

    if (ok) {
      Navigator.pop(context, true);
      return;
    }

    final state = ref.read(riderMeOrdersProvider);
    final fieldError = state.actionFieldErrors?['pickup_pin']?.first;
    setState(() {
      _submitting = false;
      _error = fieldError ??
          state.actionMessage ??
          "Couldn't confirm pickup — please try again.";
      // A wrong code is retyped from scratch; any other failure (network,
      // lockout) keeps what was entered.
      if (fieldError != null) {
        _code = '';
        _codeKey.currentState?.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final w = math.min(MediaQuery.sizeOf(context).width, _maxBaseWidth);
    final gap = w * 0.03;

    return PopScope(
      canPop: !_submitting,
      child: Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.vertical(top: Radius.circular(w * 0.05)),
          ),
          padding: EdgeInsets.fromLTRB(w * 0.05, 0, w * 0.05, w * 0.06),
          child: SafeArea(
            top: false,
            // Scrolls rather than overflows in landscape or with large text.
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const DragHandle(),
                  Text(
                    'Enter Collection Code',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: w * 0.045,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: gap * 0.4),
                  Text(
                    'Ask the sender for the 4-digit code we texted them. It '
                    'confirms you are the rider they are expecting.',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: w * 0.034,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: gap * 1.6),
                  Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: w * 0.8),
                      child: OtpInputField(
                        key: _codeKey,
                        digitCount: _codeLength,
                        enabled: !_submitting,
                        onChanged: (code) => setState(() {
                          _code = code;
                          _error = null;
                        }),
                      ),
                    ),
                  ),
                  if (_error != null) ...[
                    SizedBox(height: gap),
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        _error!,
                        style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: w * 0.032,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ],
                  SizedBox(height: gap * 1.6),
                  AppGradientButton(
                    label: 'Confirm Pickup',
                    isLoading: _submitting,
                    onPressed: _complete && !_submitting ? _submit : null,
                    height: w * 0.125,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
