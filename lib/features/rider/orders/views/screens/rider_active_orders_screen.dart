import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:delivery_boy/constant/constant.dart';
import 'package:delivery_boy/core/router/app_routes.dart';
import 'package:delivery_boy/features/rider/orders/models/rider_order_model.dart';
import 'package:delivery_boy/features/rider/orders/providers/rider_orders_providers.dart';
import 'package:delivery_boy/features/rider/orders/views/widgets/rider_order_card.dart';
import 'package:delivery_boy/features/rider/orders/views/widgets/rider_order_detail_sheet.dart';

class RiderActiveOrdersScreen extends ConsumerStatefulWidget {
  const RiderActiveOrdersScreen({super.key});

  @override
  ConsumerState<RiderActiveOrdersScreen> createState() =>
      _RiderActiveOrdersScreenState();
}

class _RiderActiveOrdersScreenState
    extends ConsumerState<RiderActiveOrdersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(activeOrdersProvider.notifier).load();
    });
  }

  void _showOrderDialog(RiderOrderModel order) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final width = MediaQuery.sizeOf(ctx).width;
        final isStarted = order.isStarted;

        return Dialog(
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Wrap(
            children: [
              RiderOrderDetailSheet(
                order: order,
                actionButton: InkWell(
                  onTap: () async {
                    if (isStarted) {
                      Navigator.pop(ctx);
                      context.go(AppRoutes.map);
                    } else {
                      final ok = await ref
                          .read(activeOrdersProvider.notifier)
                          .updateOrderStatus(
                            orderId: order.id,
                            status: 'started',
                          );
                      if (ok && mounted) {
                        Navigator.pop(ctx);
                        context.go(AppRoutes.map);
                      }
                    }
                  },
                  child: Container(
                    width: width,
                    alignment: Alignment.center,
                    margin: EdgeInsets.all(fixPadding),
                    padding: EdgeInsets.all(fixPadding),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      isStarted ? 'Open Map' : 'Start Order',
                      style: wbuttonWhiteTextStyle,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(activeOrdersProvider);

    ref.listen<ActiveOrdersState>(activeOrdersProvider, (_, next) {
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage!)),
        );
        ref.read(activeOrdersProvider.notifier).clearError();
      }
    });

    if (state.status == OrdersStatus.loading ||
        state.status == OrdersStatus.initial) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.directions_bike, color: Colors.grey, size: 60),
            const SizedBox(height: 20),
            Text('No active orders.', style: greyHeadingStyle),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(activeOrdersProvider.notifier).load(),
      child: ListView.builder(
        itemCount: state.orders.length,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          final order = state.orders[index];
          return InkWell(
            onTap: () {
              ref.read(activeOrdersProvider.notifier).selectOrder(order);
              _showOrderDialog(order);
            },
            child: Container(
              padding: EdgeInsets.all(fixPadding),
              child: RiderOrderCard(
                order: order,
                actionButton: InkWell(
                  onTap: () {
                    ref.read(activeOrdersProvider.notifier).selectOrder(order);
                    _showOrderDialog(order);
                  },
                  borderRadius: BorderRadius.circular(5),
                  child: Container(
                    height: 40,
                    width: 100,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      color: primaryColor,
                    ),
                    child: Text('View Order', style: wbuttonWhiteTextStyle),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
