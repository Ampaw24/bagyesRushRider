import 'package:flutter/material.dart';
import 'package:delivery_boy/constant/constant.dart';
import 'package:hugeicons/hugeicons.dart';

class OrderComponent extends StatelessWidget {

  OrderComponent(this.item, this.child);
  
  final item;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    return Container(
      decoration: BoxDecoration(
        color: whiteColor,
        borderRadius: BorderRadius.circular(5.0),
        boxShadow: <BoxShadow>[
          BoxShadow(
            blurRadius: 1.5,
            spreadRadius: 1.5,
            color: Colors.grey.shade200,
          ),
        ],
      ),
      child: Column(
        children: <Widget>[
          Padding(
            padding: EdgeInsets.all(fixPadding),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Icon(HugeIcons.strokeRoundedDeliveryBox01, color: primaryColor, size: 25.0),
                    widthSpace,
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(item['orderId'], style: headingStyle),
                        heightSpace,
                        heightSpace,
                        Text('Payment Mode', style: lightGreyStyle),
                        Text(item['paymentMode'], style: headingStyle),
                      ],
                    ),
                  ],
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    child,
                    heightSpace,
                    Text('Payment', style: lightGreyStyle),
                    Text('\GHS ${item['amount'].toString()}',
                        style: headingStyle),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.all(fixPadding),
            decoration: BoxDecoration(
              color: lightGreyColor,
              borderRadius: BorderRadius.only(
                bottomRight: Radius.circular(5.0),
                bottomLeft: Radius.circular(5.0),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Container(
                  width: (width - fixPadding * 4.0) / 3.2,
                  child: Text(
                    item['pickUpLocation'],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: buttonBlackTextStyle,
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Icon(
                      HugeIcons.strokeRoundedLocation01,
                      color: primaryColor,
                      size: 20.0,
                    ),
                    getDot(),
                    getDot(),
                    getDot(),
                    getDot(),
                    getDot(),
                    Icon(
                      HugeIcons.strokeRoundedNavigation01,
                      color: primaryColor,
                      size: 20.0,
                    ),
                  ],
                ),
                Container(
                  width: (width - fixPadding * 4.0) / 3.2,
                  child: Text(
                    item['deliveryLocation'],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: buttonBlackTextStyle,
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  getDot() {
    return Container(
      margin: EdgeInsets.only(left: 2.0, right: 2.0),
      width: 4.0,
      height: 4.0,
      decoration: BoxDecoration(
        color: primaryColor,
        borderRadius: BorderRadius.circular(2.0),
      ),
    );
  }
}
