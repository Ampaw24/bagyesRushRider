import 'package:flutter/material.dart';
import 'package:delivery_boy/constant/constant.dart';
import 'package:delivery_boy/features/rider/orders/models/rider_order_model.dart';

class RiderOrderCard extends StatelessWidget {
  final RiderOrderModel order;
  final Widget actionButton;

  const RiderOrderCard({
    super.key,
    required this.order,
    required this.actionButton,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    return Container(
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
        children: [
          Padding(
            padding: EdgeInsets.all(fixPadding),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.fastfood, color: primaryColor, size: 25),
                    widthSpace,
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(order.orderId, style: headingStyle),
                        heightSpace,
                        heightSpace,
                        Text('Payment Mode', style: lightGreyStyle),
                        Text(order.paymentMode, style: headingStyle),
                      ],
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    actionButton,
                    heightSpace,
                    Text('Payment', style: lightGreyStyle),
                    Text('GHS ${order.amount}', style: headingStyle),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.all(fixPadding),
            decoration: BoxDecoration(
              color: lightGreyColor,
              borderRadius: const BorderRadius.only(
                bottomRight: Radius.circular(5),
                bottomLeft: Radius.circular(5),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: (width - fixPadding * 4) / 3.2,
                  child: Text(
                    order.pickUpLocation,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: buttonBlackTextStyle,
                  ),
                ),
                Row(
                  children: [
                    Icon(Icons.location_on, color: primaryColor, size: 20),
                    _dot(),
                    _dot(),
                    _dot(),
                    _dot(),
                    _dot(),
                    Icon(Icons.navigation, color: primaryColor, size: 20),
                  ],
                ),
                SizedBox(
                  width: (width - fixPadding * 4) / 3.2,
                  child: Text(
                    order.deliveryLocation,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: buttonBlackTextStyle,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot() => Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        width: 4,
        height: 4,
        decoration: BoxDecoration(
          color: primaryColor,
          borderRadius: BorderRadius.circular(2),
        ),
      );
}
