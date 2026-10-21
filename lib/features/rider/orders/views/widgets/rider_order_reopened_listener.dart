import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gopady_rider/core/widgets/app_toast.dart';
import 'package:gopady_rider/features/rider/orders/providers/reopened_order_logic.dart';
import 'package:gopady_rider/features/rider/orders/providers/rider_me_order_providers.dart';

/// Tells the rider when support reopens an order they gave up on, so they
/// can go back and deliver it.
///
/// It reacts to the orders list rather than to any transport, so it works
/// the same whether the change came from the on-hold poll, the rider
/// channel, a refresh on app show or the rider's own "Check again".
/// Wrap the dashboard shell in it (it is mounted for the whole session).
class RiderOrderReopenedListener extends ConsumerWidget {
  final Widget child;

  const RiderOrderReopenedListener({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<RiderMeOrdersState>(riderMeOrdersProvider, (previous, next) {
      for (final order in reopenedOrders(previous, next)) {
        HapticFeedback.mediumImpact();
        AppToast.show(
          context,
          isSuccess: true,
          title: 'Delivery reopened',
          subtitle: '${order.reference ?? '#${order.id}'} can be delivered '
              'again.',
        );
      }
    });
    return child;
  }
}
