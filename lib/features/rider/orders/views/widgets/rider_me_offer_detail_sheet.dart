import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:delivery_boy/constant/app_theme.dart';
import 'package:delivery_boy/core/widgets/app_gradient_button.dart';
import 'package:delivery_boy/core/widgets/drag_handle.dart';
import 'package:delivery_boy/features/rider/orders/models/rider_me_order_model.dart';
import 'package:delivery_boy/features/rider/orders/providers/rider_me_order_providers.dart';
import 'package:delivery_boy/features/rider/orders/views/widgets/reason_input_sheet.dart';
import 'package:hugeicons/hugeicons.dart';

/// Self-contained offer detail sheet — accept/decline are built in rather
/// than an injected action slot, since there's exactly one pair of actions
/// an offer ever needs (unlike the order sheet, whose action area varies by
/// stage/branch).
class RiderMeOfferDetailSheet extends ConsumerStatefulWidget {
  final RiderMeOfferModel offer;

  const RiderMeOfferDetailSheet({super.key, required this.offer});

  @override
  ConsumerState<RiderMeOfferDetailSheet> createState() =>
      _RiderMeOfferDetailSheetState();
}

class _RiderMeOfferDetailSheetState
    extends ConsumerState<RiderMeOfferDetailSheet> {
  bool _busy = false;

  Future<void> _accept() async {
    setState(() => _busy = true);
    final ok = await ref.read(riderMeOffersProvider.notifier).accept(widget.offer.id);
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      Navigator.pop(context);
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order accepted!'), backgroundColor: AppColors.success),
      );
    } else {
      final msg = ref.read(riderMeOffersProvider).actionMessage ?? 'Could not accept this offer';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: AppColors.error),
      );
    }
  }

  void _decline() {
    Navigator.pop(context);
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReasonInputSheet(
        title: 'Reason for Declining',
        submitLabel: 'Submit',
        onSubmit: (reason) => ref
            .read(riderMeOffersProvider.notifier)
            .decline(widget.offer.id, reason: reason.isEmpty ? null : reason),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final offer = widget.offer;
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, scrollCtrl) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: scrollCtrl,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            children: [
              const DragHandle(),
              Text(
                offer.orderReference ?? '#${offer.id}',
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              _detailRow(HugeIcons.strokeRoundedCheckmarkCircle01, Colors.green,
                  'Pickup', offer.pickupAddress ?? '-'),
              const SizedBox(height: 10),
              _detailRow(HugeIcons.strokeRoundedLocation01, AppColors.primary,
                  'Dropoff', offer.dropoffAddress ?? '-'),
              const SizedBox(height: 16),
              Row(
                children: [
                  if (offer.distanceKm != null)
                    Expanded(
                      child: _statTile('Distance', '${offer.distanceKm!.toStringAsFixed(1)} km'),
                    ),
                  if (offer.estimatedFare != null)
                    Expanded(
                      child: _statTile(
                          'Est. Fare', 'GHS ${offer.estimatedFare!.toStringAsFixed(2)}'),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: _busy ? null : _decline,
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'Decline',
                          style: TextStyle(
                              fontFamily: 'Roboto',
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: AppColors.textPrimary),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppGradientButton(
                      label: 'Accept',
                      isLoading: _busy,
                      onPressed: _busy ? null : _accept,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow(IconData icon, Color iconColor, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 11,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statTile(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(fontFamily: 'Roboto', fontSize: 11, color: Colors.grey.shade500)),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}
