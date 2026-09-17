import 'package:flutter/material.dart';
import 'package:delivery_boy/constant/app_theme.dart';

/// Single source of truth for rendering `RiderMeOrderModel.status` — shared
/// by the order card, the home screen's mini card, and the detail sheet's
/// badge, instead of each hand-rolling its own switch over the (legacy)
/// status vocabulary.
Color riderMeOrderStatusColor(String status) {
  switch (status) {
    case 'delivered':
      return AppColors.success;
    case 'out_for_delivery':
      return AppColors.primary;
    case 'preparing':
    case 'ready':
      return Colors.orange;
    case 'accepted':
      return Colors.blue;
    case 'cancelled':
    case 'rejected':
    case 'refunded':
      return AppColors.error;
    default: // pending_payment | pending
      return Colors.grey.shade400;
  }
}

String riderMeOrderStatusLabel(String status) {
  switch (status) {
    case 'pending_payment':
      return 'Pending Payment';
    case 'pending':
      return 'Pending';
    case 'accepted':
      return 'Accepted';
    case 'preparing':
      return 'Preparing';
    case 'ready':
      return 'Ready';
    case 'out_for_delivery':
      return 'Out for Delivery';
    case 'delivered':
      return 'Delivered';
    case 'cancelled':
      return 'Cancelled';
    case 'rejected':
      return 'Rejected';
    case 'refunded':
      return 'Refunded';
    default:
      return status;
  }
}
