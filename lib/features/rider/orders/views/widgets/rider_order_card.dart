import 'package:flutter/material.dart';
import 'package:delivery_boy/constant/app_theme.dart';
import 'package:delivery_boy/features/rider/orders/models/rider_order_model.dart';

class RiderOrderCard extends StatelessWidget {
  final RiderOrderModel order;
  final Widget actionButton;

  const RiderOrderCard({
    super.key,
    required this.order,
    required this.actionButton,
  });

  Color get _statusColor {
    return switch (order.status) {
      'delivered' => AppColors.success,
      'en_route' || 'picked_up' => AppColors.primary,
      'heading_to_pickup' || 'arrived_at_pickup' => Colors.orange,
      'accepted' => Colors.blue,
      _ => Colors.grey.shade400,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: _statusColor, width: 4),
        ),
        boxShadow: [
          BoxShadow(
            blurRadius: 8,
            spreadRadius: 0,
            color: Colors.black.withValues(alpha: 0.06),
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.fastfood_outlined,
                      color: _statusColor, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '#${order.orderId}',
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              order.paymentMode,
                              style: TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 11,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    actionButton,
                    const SizedBox(height: 6),
                    Text(
                      'GHS ${order.amount}',
                      style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Location footer ──────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.radio_button_checked,
                          color: Colors.green, size: 14),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          order.pickUpLocation,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.arrow_forward_rounded,
                      size: 14, color: AppColors.primary),
                ),
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.location_on,
                          color: AppColors.primary, size: 14),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          order.deliveryLocation,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
