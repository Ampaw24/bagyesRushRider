import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:delivery_boy/constant/constant.dart';
import 'package:delivery_boy/core/di/service_locator.dart';
import 'package:delivery_boy/core/services/user_session_manager.dart';
import 'package:delivery_boy/features/rider/orders/models/rider_order_model.dart';
import 'package:delivery_boy/features/rider/orders/providers/rider_orders_providers.dart';
import 'package:delivery_boy/features/rider/orders/views/widgets/rider_order_card.dart';
import 'package:delivery_boy/features/rider/orders/views/widgets/rider_order_detail_sheet.dart';

class RiderNewOrdersScreen extends ConsumerStatefulWidget {
  const RiderNewOrdersScreen({super.key});

  @override
  ConsumerState<RiderNewOrdersScreen> createState() =>
      _RiderNewOrdersScreenState();
}

class _RiderNewOrdersScreenState extends ConsumerState<RiderNewOrdersScreen> {
  String _rejectReason = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(newOrdersProvider.notifier).load();
    });
  }

  String get _userId =>
      sl<UserSessionManager>().currentUser?['_id'] as String? ?? '';

  void _showRejectDialog(RiderOrderModel order) {
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: width,
                    padding: EdgeInsets.all(fixPadding),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(10),
                        topLeft: Radius.circular(10),
                      ),
                    ),
                    child: Text('Reason to Reject',
                        style: wbuttonWhiteTextStyle),
                  ),
                  Container(
                    padding: EdgeInsets.all(fixPadding),
                    alignment: Alignment.center,
                    child: const Text(
                        'Write a specific reason to reject order'),
                  ),
                  Container(
                    width: width,
                    padding: EdgeInsets.all(fixPadding),
                    child: TextField(
                      onChanged: (v) => _rejectReason = v,
                      keyboardType: TextInputType.multiline,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'Enter Reason Here',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(5),
                          borderSide:
                              const BorderSide(color: Colors.transparent),
                        ),
                        fillColor: Colors.grey.withValues(alpha: 0.1),
                        filled: true,
                      ),
                    ),
                  ),
                  heightSpace,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _dialogBtn(
                        label: 'Cancel',
                        color: Colors.grey[300]!,
                        textStyle: buttonBlackTextStyle,
                        onTap: () => Navigator.pop(ctx),
                        width: width,
                      ),
                      _dialogBtn(
                        label: 'Send',
                        color: primaryColor,
                        textStyle: wbuttonWhiteTextStyle,
                        onTap: () async {
                          if (_rejectReason.isEmpty) return;
                          Navigator.pop(ctx);
                          final ok = await ref
                              .read(newOrdersProvider.notifier)
                              .rejectOrder(
                                orderId: order.id,
                                courierId: _userId,
                                reason: _rejectReason,
                              );
                          if (ok && mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Order rejected')),
                            );
                          }
                        },
                        width: width,
                      ),
                    ],
                  ),
                  heightSpace,
                ],
              ),
            ],
          ),
        );
      },
    );
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
                actionButton: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _dialogBtn(
                      label: 'Reject',
                      color: Colors.grey[300]!,
                      textStyle: buttonBlackTextStyle,
                      onTap: () {
                        Navigator.pop(ctx);
                        _showRejectDialog(order);
                      },
                      width: width,
                    ),
                    _dialogBtn(
                      label: 'Accept',
                      color: primaryColor,
                      textStyle: wbuttonWhiteTextStyle,
                      onTap: () async {
                        Navigator.pop(ctx);
                        final ok = await ref
                            .read(newOrdersProvider.notifier)
                            .acceptOrder(
                              orderId: order.id,
                              courierId: _userId,
                            );
                        if (ok && mounted) {
                          showDialog(
                            context: context,
                            builder: (c) => AlertDialog(
                              title: const Text('Congratulations!'),
                              content: const Text('Yay! Order accepted'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(c),
                                  child: const Text('Okay'),
                                ),
                              ],
                            ),
                          );
                        }
                      },
                      width: width,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _dialogBtn({
    required String label,
    required Color color,
    required TextStyle textStyle,
    required VoidCallback onTap,
    required double width,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: width / 3.5,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Text(label, style: textStyle),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(newOrdersProvider);

    ref.listen<NewOrdersState>(newOrdersProvider, (_, next) {
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.errorMessage!)),
        );
        ref.read(newOrdersProvider.notifier).clearError();
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
            const Icon(Icons.local_mall, color: Colors.grey, size: 60),
            const SizedBox(height: 20),
            Text('No new orders.', style: greyHeadingStyle),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(newOrdersProvider.notifier).load(),
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
                onTap: () => _showOrderDialog(order),
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
