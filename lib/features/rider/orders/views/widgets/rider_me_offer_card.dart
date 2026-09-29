import 'package:flutter/material.dart';
import 'package:delivery_boy/constant/app_theme.dart';
import 'package:delivery_boy/features/rider/orders/models/rider_me_order_model.dart';
import 'package:delivery_boy/features/rider/orders/views/widgets/rider_order_card_shell.dart';
import 'package:delivery_boy/features/rider/orders/views/widgets/rider_route_summary.dart';
import 'package:hugeicons/hugeicons.dart';

/// Card for a `RiderMeOfferModel` — a delivery offer awaiting accept/decline.
/// Distinct from `RiderMeOrderCard` since offers carry a different field
/// set (no `status`/`stops`, but `distanceKm`/`estimatedFare`/`expiresAt`).
/// Accept and Decline are visible buttons rather than a hidden swipe.
class RiderMeOfferCard extends StatelessWidget {
  final RiderMeOfferModel offer;
  final VoidCallback onTap;
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;
  final bool isAccepting;

  const RiderMeOfferCard({
    super.key,
    required this.offer,
    required this.onTap,
    required this.onAccept,
    required this.onDecline,
    this.isAccepting = false,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final fare = offer.estimatedFare;
    final distance = offer.distanceKm;

    return RiderOrderCardShell(
      onTap: onTap,
      semanticLabel: 'Delivery offer ${offer.orderReference ?? offer.id}',
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    offer.orderReference ?? '#${offer.id}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: w * 0.04,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (distance != null) ...[
                    SizedBox(height: w * 0.015),
                    RiderOrderChip(
                      label: '${distance.toStringAsFixed(1)} km',
                      color: AppColors.textSecondary,
                      icon: HugeIcons.strokeRoundedRoute01,
                    ),
                  ],
                ],
              ),
            ),
            if (fare != null)
              Text(
                'GHS ${fare.toStringAsFixed(2)}',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: w * 0.045,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
          ],
        ),
        SizedBox(height: w * 0.035),
        RiderRouteSummary(
          pickup: offer.pickupAddress,
          dropoff: offer.dropoffAddress,
        ),
        SizedBox(height: w * 0.04),
        Row(
          children: [
            Expanded(
              child: RiderOrderCardButton(
                label: 'Decline',
                outlined: true,
                onPressed: isAccepting ? null : onDecline,
              ),
            ),
            SizedBox(width: w * 0.025),
            Expanded(
              flex: 2,
              child: RiderOrderCardButton(
                label: 'Accept',
                isLoading: isAccepting,
                onPressed: onAccept,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
