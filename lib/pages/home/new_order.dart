import 'dart:async';
import 'dart:convert';

import 'package:delivery_boy/components/order.component.dart';
import 'package:delivery_boy/components/orderDetails.component.dart';
import 'package:delivery_boy/constant/constant.dart';
import 'package:delivery_boy/constant/models.dart';
import 'package:delivery_boy/services/app.services.dart';
import 'package:delivery_boy/states/app.state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class NewOrder extends StatefulWidget {
  @override
  _NewOrderState createState() => _NewOrderState();
}

class _NewOrderState extends State<NewOrder> {
  String reason = '';
  bool loading = false;
  var pushOrders;
  var user;
  var selectedOrder;
  String token = '';

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    Timer(Duration(seconds: 1), () {
      loadOrders();
    });
  }

  Future<void> loadOrders() async {
    try {
      setState(() {
        loading = true;
      });
      var response = await getRequested(user['_id'],token)
          .then((value) => IApiResponse(value.data));
      if (!response.success) {
        throw Exception(response.message);
      }
      setState(() {
        loading = false;
        pushOrders(response.data);
      });
    } catch (err) {
      setState(() {
        loading = false;
      });
      print(err);
    }
  }

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

  Future<void> _rejectOrder() async {
    try {
      if(reason.length<=0){
        throw Exception(
          'Please provide a valid reason for rejection'
        );
      }
      setState(() {
        loading = true;
      });
      var data = {
        "orderId": selectedOrder['_id'],
        "courier": user['_id'],
        "reason": reason
      };
      var response = await rejectOrder(data, token)
          .then((value) => IApiResponse(value.data));
      setState(() {
        loading = false;
      });
      if (!response.success) {
        throw Exception(response.message);
      }
      this.loadOrders();
      showDialog(
          context: context,
          builder: (BuildContext context) => AlertDialog(
                  actions: [
                    TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text('Okay'))
                  ],
                  title: Text("Rejected"),
                  content: Text(response.message)));
    } catch (e) {
      setState(() {
        loading = false;
      });
      showDialog(
          context: context,
          builder: (BuildContext context) => AlertDialog(
                  actions: [
                    TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text('Okay'))
                  ],
                  title: Text("Oops! Something went wrong"),
                  content: Text(e.toString())));
    }
  }

  Future<void> _acceptOrder() async {
    try {
      setState(() {
        loading = true;
      });
      var data = {"orderId": selectedOrder['_id'], "courier": user["_id"]};
      var response = await acceptOrder(data, token)
          .then((value) => IApiResponse(value.data));
      setState(() {
        loading = false;
      });
      if (!response.success) {
        throw Exception(response.message);
      }
      showDialog(
          context: context,
          builder: (BuildContext context) => AlertDialog(
                  actions: [
                    TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          this.loadOrders();
                        },
                        child: Text('Okay'))
                  ],
                  title: Text("Congratulatins!"),
                  content: Text("Yay! Order accepted")));
    } catch (e) {
      setState(() {
        loading = false;
      });
      showDialog(
          context: context,
          builder: (BuildContext context) => AlertDialog(
                  actions: [
                    TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text('Okay'))
                  ],
                  title: Text("Oops! Something went wrong"),
                  content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    pushOrders = context.read<AppState>().pushOrders;
    token = context.read<AppState>().token ?? '';
    user = context.read<AppState>().user;
    selectedOrder = context.read<AppState>().selectedOrder;
    var deliveryList = context.read<AppState>().orders;
    var pushSelectedOrder = context.read<AppState>().pushSelectedOrder;

    rejectreasonDialog() {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          // return object of type Dialog
          return Dialog(
            elevation: 0.0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0)),
            child: Wrap(
              children: <Widget>[
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                        'Reason to Reject',
                        style: wbuttonWhiteTextStyle,
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.all(fixPadding),
                      alignment: Alignment.center,
                      child: Text('Write a specific reason to reject order'),
                    ),
                    Container(
                      width: width,
                      padding: EdgeInsets.all(fixPadding),
                      child: TextField(
                        onChanged: (v) {
                          reason = v;
                        },
                        keyboardType: TextInputType.multiline,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'Enter Reason Here',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(5.0),
                            borderSide: BorderSide(color: Colors.transparent),
                          ),
                          fillColor: Colors.grey.withOpacity(0.1),
                          filled: true,
                        ),
                      ),
                    ),
                    heightSpace,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: <Widget>[
                        InkWell(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: Container(
                            width: (width / 3.5),
                            alignment: Alignment.center,
                            padding: EdgeInsets.all(10.0),
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(5.0),
                            ),
                            child: Text(
                              'Cancel',
                              style: buttonBlackTextStyle,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            Navigator.pop(context);
                            _rejectOrder();
                          },
                          child: Container(
                            width: (width / 3.5),
                            alignment: Alignment.center,
                            padding: EdgeInsets.all(10.0),
                            decoration: BoxDecoration(
                              color: primaryColor,
                              borderRadius: BorderRadius.circular(5.0),
                            ),
                            child: Text(
                              'Send',
                              style: wbuttonWhiteTextStyle,
                            ),
                          ),
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

    orderAcceptDialog(index) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          // return object of type Dialog
          return Dialog(
            elevation: 0.0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0)),
            child: Wrap(
              children: <Widget>[
                OrderDetailsComponent(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: <Widget>[
                      InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          rejectreasonDialog();
                        },
                        child: Container(
                          width: (width / 3.5),
                          alignment: Alignment.center,
                          padding: EdgeInsets.all(10.0),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(5.0),
                          ),
                          child: Text(
                            'Reject',
                            style: buttonBlackTextStyle,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          _acceptOrder();
                        },
                        child: Container(
                          width: (width / 3.5),
                          alignment: Alignment.center,
                          padding: EdgeInsets.all(10.0),
                          decoration: BoxDecoration(
                            color: primaryColor,
                            borderRadius: BorderRadius.circular(5.0),
                          ),
                          child: Text(
                            'Accept',
                            style: wbuttonWhiteTextStyle,
                          ),
                        ),
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

    return (deliveryList.length == 0)
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Icon(
                  Icons.local_mall,
                  color: Colors.grey,
                  size: 60.0,
                ),
                SizedBox(
                  height: 20.0,
                ),
                Text(
                  'No new orders.',
                  style: greyHeadingStyle,
                ),
              ],
            ),
          )
        : ListView.builder(
            itemCount: deliveryList.length,
            physics: BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final item = deliveryList[index];
              return Container(
                padding: EdgeInsets.all(fixPadding),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    OrderComponent(
                      item,
                      InkWell(
                        onTap: () {
                          pushSelectedOrder(item);
                          orderAcceptDialog(index);
                        },
                        borderRadius: BorderRadius.circular(5.0),
                        child: Container(
                          height: 40.0,
                          width: 100.0,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5.0),
                            color: primaryColor,
                          ),
                          child: Text(
                            'View Order',
                            style: wbuttonWhiteTextStyle,
                          ),
                        ),
                      ),
                    )
                  ],
                ),
              );
            },
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
