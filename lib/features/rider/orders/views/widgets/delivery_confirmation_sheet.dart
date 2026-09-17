import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:delivery_boy/constant/app_theme.dart';
import 'package:delivery_boy/core/widgets/app_gradient_button.dart';
import 'package:delivery_boy/core/widgets/drag_handle.dart';
import 'package:delivery_boy/features/rider/orders/providers/rider_me_order_providers.dart';
import 'package:delivery_boy/features/rider/shared_widgets/otp_input_field.dart';
import 'package:hugeicons/hugeicons.dart';

enum _ConfirmStep { pin, photo }

/// PIN entry + optional proof-of-delivery photo, shown right before
/// `POST rider/me/orders/:id/deliver` (when [stopId] is null) or
/// `POST rider/me/orders/:id/stops/:stopId/deliver` (when it's set).
///
/// A bottom sheet, not a route — matches this feature's existing
/// all-in-memory-sheets convention (no order-detail/PIN/active-delivery
/// route exists anywhere in the app today).
///
/// Show with `showModalBottomSheet<bool>(isScrollControlled: true,
/// backgroundColor: Colors.transparent, builder: (_) =>
/// DeliveryConfirmationSheet(...))`. Pops `true` on success.
class DeliveryConfirmationSheet extends ConsumerStatefulWidget {
  final int orderId;
  final int? stopId;

  const DeliveryConfirmationSheet({
    super.key,
    required this.orderId,
    this.stopId,
  });

  @override
  ConsumerState<DeliveryConfirmationSheet> createState() =>
      _DeliveryConfirmationSheetState();
}

class _DeliveryConfirmationSheetState
    extends ConsumerState<DeliveryConfirmationSheet> {
  final _pinKey = GlobalKey<OtpInputFieldState>();

  _ConfirmStep _step = _ConfirmStep.pin;
  String _pin = '';
  String? _photoPath;
  bool _submitting = false;
  String? _pinError;
  String? _genericError;

  Future<void> _pickPhoto(ImageSource source) async {
    Navigator.pop(context); // close the source-picker sheet
    final picked =
        await ImagePicker().pickImage(source: source, imageQuality: 80);
    if (picked == null) return;
    setState(() => _photoPath = picked.path);
  }

  void _showSourcePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const DragHandle(),
              ListTile(
                leading: const Icon(HugeIcons.strokeRoundedCamera01,
                    color: AppColors.primary),
                title: const Text('Take a photo',
                    style: TextStyle(fontFamily: 'Roboto')),
                onTap: () => _pickPhoto(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(HugeIcons.strokeRoundedImage01,
                    color: AppColors.primary),
                title: const Text('Choose from gallery',
                    style: TextStyle(fontFamily: 'Roboto')),
                onTap: () => _pickPhoto(ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _genericError = null;
    });

    final notifier = ref.read(riderMeOrdersProvider.notifier);
    final ok = widget.stopId == null
        ? await notifier.deliverOrder(
            widget.orderId,
            deliveryPin: _pin,
            proofPhotoPath: _photoPath,
          )
        : await notifier.deliverStop(
            widget.orderId,
            widget.stopId!,
            deliveryPin: _pin,
            proofPhotoPath: _photoPath,
          );

    if (!mounted) return;

    if (ok) {
      Navigator.pop(context, true);
      return;
    }

    final fieldErrors = ref.read(riderMeOrdersProvider).actionFieldErrors;
    final pinError = fieldErrors?['delivery_pin']?.first;

    setState(() {
      _submitting = false;
      if (pinError != null) {
        _pin = '';
        _pinKey.currentState?.clear();
        _pinError = pinError;
        _step = _ConfirmStep.pin;
      } else {
        _genericError =
            ref.read(riderMeOrdersProvider).actionMessage ?? 'Delivery confirmation failed — try again.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_submitting,
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const DragHandle(),
              if (_step == _ConfirmStep.pin) _buildPinStep() else _buildPhotoStep(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPinStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Enter Delivery PIN',
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Ask the customer for their 4-digit delivery PIN',
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 13,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: OtpInputField(
            key: _pinKey,
            digitCount: 4,
            enabled: !_submitting,
            onCompleted: (pin) {
              setState(() {
                _pin = pin;
                _pinError = null;
                _step = _ConfirmStep.photo;
              });
            },
          ),
        ),
        if (_pinError != null) ...[
          const SizedBox(height: 12),
          Text(
            _pinError!,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 12,
              color: AppColors.error,
            ),
          ),
        ],
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildPhotoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Proof of Delivery',
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Optional — attach a photo of the delivered package',
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 13,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: _submitting ? null : _showSourcePicker,
          child: AspectRatio(
            aspectRatio: 1.6,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
              ),
              clipBehavior: Clip.antiAlias,
              child: _photoPath != null
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(File(_photoPath!), fit: BoxFit.cover),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: _submitting
                                ? null
                                : () => setState(() => _photoPath = null),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(HugeIcons.strokeRoundedCancel01,
                                  color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                      ],
                    )
                  : Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(HugeIcons.strokeRoundedCamera01,
                              color: Colors.grey.shade400, size: 32),
                          const SizedBox(height: 6),
                          Text(
                            'Tap to add a photo',
                            style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ),
        if (_genericError != null) ...[
          const SizedBox(height: 12),
          Text(
            _genericError!,
            style: const TextStyle(
              fontFamily: 'Roboto',
              fontSize: 12,
              color: AppColors.error,
            ),
          ),
        ],
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _submitting
                    ? null
                    : () => setState(() => _step = _ConfirmStep.pin),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: Colors.grey.shade300),
                  shape:
                      RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'Back',
                  style: TextStyle(
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: AppGradientButton(
                label: 'Confirm Delivery',
                isLoading: _submitting,
                onPressed: _submitting ? null : () {
                  HapticFeedback.mediumImpact();
                  _submit();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
