import 'package:delivery_boy/states/app.state.dart';
import 'package:flutter/material.dart';
import 'package:delivery_boy/constant/constant.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class OrderDetailsComponent extends StatelessWidget {
  final Widget child;
  const OrderDetailsComponent({Key? key, required this.child}) : super(key: key);

  String getCustomerPhone(selectedOrder) {
    try {
      return selectedOrder['customer']['phone'];
    } catch (e) {
      return '';
    }
  }

  String getCustomerName(selectedOrder) {
    try {
      return selectedOrder['customer']['name'];
    } catch (e) {
      return '';
    }
  }

  String formatDate(date) {
    try {
      final f = new DateFormat('yyyy-MM-dd');
      return f.format(date);
    } catch (e) {
      return date;
    }
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    var selectedOrder = context.read<AppState>().selectedOrder;

    return Container(
      width: width,
      height: height / 1.2,
      child: ListView(
        children: <Widget>[
          Container(
            width: width,
            padding: EdgeInsets.all(fixPadding),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(10.0),
                topLeft: Radius.circular(10.0),
              ),
            ),
            child: Text(
              selectedOrder['orderId'],
              style: wbuttonWhiteTextStyle,
            ),
          ),
          Container(
            margin: EdgeInsets.all(fixPadding),
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
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  alignment: Alignment.center,
                  padding: EdgeInsets.all(fixPadding),
                  decoration: BoxDecoration(
                      color: lightGreyColor,
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(5.0),
                        topLeft: Radius.circular(5.0),
                      )),
                  child: Text(
                    'Package Image',
                    style: buttonBlackTextStyle,
                  ),
                ),
                Padding(
                    padding: EdgeInsets.all(fixPadding),
                    child: Container(
                      child: Image(
                        image: NetworkImage(selectedOrder['image']),
                        fit: BoxFit.contain,
                      ),
                    )),
              ],
            ),
          ),
          // Order Start
          Container(
            margin: EdgeInsets.all(fixPadding),
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
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  alignment: Alignment.center,
                  padding: EdgeInsets.all(fixPadding),
                  decoration: BoxDecoration(
                      color: lightGreyColor,
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(5.0),
                        topLeft: Radius.circular(5.0),
                      )),
                  child: Text(
                    'Order',
                    style: buttonBlackTextStyle,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(fixPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            'Package Type',
                            style: listItemTitleStyle,
                          ),
                          Text(
                            selectedOrder["packageType"],
                            style: listItemTitleStyle,
                          ),
                        ],
                      ),
                      heightSpace,
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            'Weight',
                            style: listItemTitleStyle,
                          ),
                          Text(
                            selectedOrder['weight'],
                            style: listItemTitleStyle,
                          ),
                        ],
                      ),
                      heightSpace,
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            'Payment',
                            style: listItemTitleStyle,
                          ),
                          Text(
                            'GHS' + selectedOrder['amount'].toString(),
                            style: listItemTitleStyle,
                          ),
                        ],
                      ),
                      heightSpace,
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            'Charges',
                            style: listItemTitleStyle,
                          ),
                          Text(
                            'GHS' + selectedOrder['charges'].toString(),
                            style: listItemTitleStyle,
                          ),
                        ],
                      ),
                      Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            'Total',
                            style: headingStyle,
                          ),
                          Text(
                            'GHS' + selectedOrder['totalAmount'].toString(),
                            style: priceStyle,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          //Order End
          // Location Start
          Container(
            margin: EdgeInsets.all(fixPadding),
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
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  alignment: Alignment.center,
                  padding: EdgeInsets.all(fixPadding),
                  decoration: BoxDecoration(
                      color: lightGreyColor,
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(5.0),
                        topLeft: Radius.circular(5.0),
                      )),
                  child: Text(
                    'Location',
                    style: buttonBlackTextStyle,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(fixPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Container(
                            width: ((width - fixPadding * 13) / 2.0),
                            child: Text(
                              'Pickup Location',
                              style: listItemTitleStyle,
                            ),
                          ),
                          widthSpace,
                          Container(
                            width: ((width - fixPadding * 13) / 2.0),
                            child: Text(
                              selectedOrder['pickUpLocation'],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: listItemTitleStyle,
                            ),
                          ),
                        ],
                      ),
                      heightSpace,
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Container(
                            width: ((width - fixPadding * 13) / 2.0),
                            child: Text(
                              'Delivery Location',
                              style: listItemTitleStyle,
                            ),
                          ),
                          widthSpace,
                          Container(
                            width: ((width - fixPadding * 13) / 2.0),
                            child: Text(
                              selectedOrder['deliveryLocation'],
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: listItemTitleStyle,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Location End

          // Customer Start
          Container(
            margin: EdgeInsets.all(fixPadding),
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
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  alignment: Alignment.center,
                  padding: EdgeInsets.all(fixPadding),
                  decoration: BoxDecoration(
                      color: lightGreyColor,
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(5.0),
                        topLeft: Radius.circular(5.0),
                      )),
                  child: Text(
                    'Customer',
                    style: buttonBlackTextStyle,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(fixPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            'Name',
                            style: listItemTitleStyle,
                          ),
                          Text(
                            getCustomerName(selectedOrder),
                            style: listItemTitleStyle,
                          ),
                        ],
                      ),
                      heightSpace,
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Text(
                            'Phone',
                            style: listItemTitleStyle,
                          ),
                          Text(
                            getCustomerPhone(selectedOrder),
                            style: listItemTitleStyle,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          //Customer End

          // Payment Start
          Container(
            margin: EdgeInsets.all(fixPadding),
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
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  alignment: Alignment.center,
                  padding: EdgeInsets.all(fixPadding),
                  decoration: BoxDecoration(
                      color: lightGreyColor,
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(5.0),
                        topLeft: Radius.circular(5.0),
                      )),
                  child: Text(
                    'Payment',
                    style: buttonBlackTextStyle,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(fixPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Container(
                            child: Text(
                              'Payment',
                              style: listItemTitleStyle,
                            ),
                          ),
                          Container(
                            child: Text(
                              'Pay on Delivery',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: listItemTitleStyle,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Container(
                            child: Text(
                              'Order Date',
                              style: listItemTitleStyle,
                            ),
                          ),
                          Container(
                            child: Text(
                              formatDate(selectedOrder["createdAt"]),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: listItemTitleStyle,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Payment End
          heightSpace,
          Expanded(child: child),
          heightSpace,
        ],
      ),
    );
  }
}
