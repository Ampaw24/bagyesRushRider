import 'package:flutter/material.dart';
import 'package:delivery_boy/constant/constant.dart';
import 'package:delivery_boy/features/rider/orders/models/rider_order_model.dart';

/// Pure widget — no AppState, no Provider.
/// Receives a typed [RiderOrderModel] and an [actionButton] slot.
class RiderOrderDetailSheet extends StatelessWidget {
  final RiderOrderModel order;
  final Widget actionButton;

  const RiderOrderDetailSheet({
    super.key,
    required this.order,
    required this.actionButton,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final height = MediaQuery.sizeOf(context).height;

    return SizedBox(
      width: width,
      height: height / 1.2,
      child: ListView(
        children: [
          // Header
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
            child: Text(order.orderId, style: wbuttonWhiteTextStyle),
          ),

          // Package image
          if (order.image != null && order.image!.isNotEmpty)
            _card(
              title: 'Package Image',
              child: Padding(
                padding: EdgeInsets.all(fixPadding),
                child: Image.network(order.image!, fit: BoxFit.contain),
              ),
            ),

          // Order details
          _card(
            title: 'Order',
            child: Padding(
              padding: EdgeInsets.all(fixPadding),
              child: Column(
                children: [
                  _row('Package Type', order.packageType ?? '-'),
                  heightSpace,
                  _row('Weight', order.weight ?? '-'),
                  heightSpace,
                  _row('Payment', 'GHS${order.amount}'),
                  heightSpace,
                  _row('Charges', 'GHS${order.charges}'),
                  const Divider(),
                  _row('Total', 'GHS${order.totalAmount}',
                      valueStyle: priceStyle),
                ],
              ),
            ),
          ),

          // Location
          _card(
            title: 'Location',
            child: Padding(
              padding: EdgeInsets.all(fixPadding),
              child: Column(
                children: [
                  _row('Pickup Location', order.pickUpLocation),
                  heightSpace,
                  _row('Delivery Location', order.deliveryLocation),
                ],
              ),
            ),
          ),

          // Customer
          _card(
            title: 'Customer',
            child: Padding(
              padding: EdgeInsets.all(fixPadding),
              child: Column(
                children: [
                  _row('Name', order.customer?.name ?? '-'),
                  heightSpace,
                  _row('Phone', order.customer?.phone ?? '-'),
                ],
              ),
            ),
          ),

          // Payment
          _card(
            title: 'Payment',
            child: Padding(
              padding: EdgeInsets.all(fixPadding),
              child: Column(
                children: [
                  _row('Payment', 'Pay on Delivery'),
                  _row('Order Date', order.formattedDate),
                ],
              ),
            ),
          ),

          heightSpace,
          actionButton,
          heightSpace,
        ],
      ),
    );
  }

  Widget _card({required String title, required Widget child}) {
    return Container(
      margin: EdgeInsets.all(fixPadding),
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.circular(5),
        boxShadow: [
          BoxShadow(
            blurRadius: 1.5,
            spreadRadius: 1.5,
            color: Colors.grey.shade200,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            alignment: Alignment.center,
            padding: EdgeInsets.all(fixPadding),
            decoration: BoxDecoration(
              color: lightGreyColor,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(5),
                topLeft: Radius.circular(5),
              ),
            ),
            child: Text(title, style: buttonBlackTextStyle),
          ),
          child,
        ],
      ),
    );
  }

  Widget _row(String label, String value, {TextStyle? valueStyle}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: listItemTitleStyle),
        Flexible(
          child: Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: valueStyle ?? listItemTitleStyle,
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
