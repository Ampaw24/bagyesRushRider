import 'package:flutter/material.dart';
import 'package:delivery_boy/constant/app_theme.dart';
import 'package:hugeicons/hugeicons.dart';

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
      return AppColors.warning;
    case 'accepted':
      return AppColors.info;
    case 'cancelled':
    case 'rejected':
    case 'refunded':
      return AppColors.error;
    default: // pending_payment | pending
      return AppColors.textSecondary;
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

IconData riderMeOrderStatusIcon(String status) {
  switch (status) {
    case 'pending_payment':
      return HugeIcons.strokeRoundedCreditCard;
    case 'pending':
      return HugeIcons.strokeRoundedHourglass;
    case 'accepted':
      return HugeIcons.strokeRoundedCheckmarkCircle01;
    case 'preparing':
      return HugeIcons.strokeRoundedChefHat;
    case 'ready':
      return HugeIcons.strokeRoundedPackage;
    case 'out_for_delivery':
      return HugeIcons.strokeRoundedMotorbike01;
    case 'delivered':
      return HugeIcons.strokeRoundedPackageDelivered;
    case 'cancelled':
      return HugeIcons.strokeRoundedCancelCircle;
    case 'rejected':
      return HugeIcons.strokeRoundedUnavailable;
    case 'refunded':
      return HugeIcons.strokeRoundedMoneyReceive01;
    default:
      return HugeIcons.strokeRoundedDeliveryBox01;
  }
}
