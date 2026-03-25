import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:delivery_boy/constant/constant.dart';
import 'package:delivery_boy/features/rider/orders/models/rider_order_model.dart';
import 'package:delivery_boy/features/rider/orders/providers/rider_orders_providers.dart';
import 'package:delivery_boy/features/rider/orders/views/widgets/rider_order_card.dart';
import 'package:delivery_boy/features/rider/orders/views/widgets/rider_order_detail_sheet.dart';

class RiderOrderHistoryScreen extends ConsumerStatefulWidget {
  const RiderOrderHistoryScreen({super.key});

  @override
  ConsumerState<RiderOrderHistoryScreen> createState() =>
      _RiderOrderHistoryScreenState();
}

class _RiderOrderHistoryScreenState
    extends ConsumerState<RiderOrderHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(orderHistoryProvider.notifier).load();
    });
  }

  void _showOrderDialog(RiderOrderModel order) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final width = MediaQuery.sizeOf(ctx).width;
        return Dialog(
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          child: Wrap(
            children: [
              RiderOrderDetailSheet(
                order: order,
                actionButton: InkWell(
                  onTap: () => Navigator.pop(ctx),
                  child: Container(
                    width: width,
                    alignment: Alignment.center,
                    margin: EdgeInsets.all(fixPadding),
                    padding: EdgeInsets.all(fixPadding),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text('Close', style: wbuttonWhiteTextStyle),
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
    final state = ref.watch(orderHistoryProvider);

    if (state.status == OrdersStatus.loading ||
        state.status == OrdersStatus.initial) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.history, color: Colors.grey, size: 60),
            const SizedBox(height: 20),
            Text('No delivery history.', style: greyHeadingStyle),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(orderHistoryProvider.notifier).load(),
      child: ListView.builder(
        itemCount: state.orders.length,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          final order = state.orders[index];
          return Container(
            padding: EdgeInsets.all(fixPadding),
            child: RiderOrderCard(
              order: order,
              actionButton: InkWell(
                onTap: () {
                  ref.read(orderHistoryProvider.notifier).selectOrder(order);
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
          );
        },
      ),
    );
  }
}
