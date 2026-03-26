import 'dart:async';
import 'dart:convert';

import 'package:delivery_boy/components/order.component.dart';
import 'package:delivery_boy/components/orderDetails.component.dart';
import 'package:delivery_boy/constant/constant.dart';
import 'package:delivery_boy/constant/models.dart';
import 'package:delivery_boy/services/app.services.dart';
import 'package:delivery_boy/states/app.state.dart';
import 'package:flutter/material.dart';
import 'package:delivery_boy/pages/map.dart';
import 'package:provider/provider.dart';

class ActiveOrder extends StatefulWidget {
  @override
  _ActiveOrderState createState() => _ActiveOrderState();
}

class _ActiveOrderState extends State<ActiveOrder> {
  String token = '';
  bool loading = false;
  var deliveryList = [];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    Timer(Duration(seconds: 1), () {
      fetchActiveOrders();
    });
  }

  Future<void> _startOrder() async {
    try {
      setState(() {
        loading = true;
      });
      var selectedOrder = context.read<AppState>().selectedOrder;
      var data = {
        "id": selectedOrder['_id'],
        "data": {"status": "started"}
      };
      var response = await updateOrder(data, token)
          .then((value) => IApiResponse(value.data));
      if (!response.success) {
        throw Exception(response.message);
      }
      Navigator.pop(context);
      Navigator.push(context, MaterialPageRoute(builder: (context) => Map()));
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

  Future<void> fetchActiveOrders() async {
    try {
      setState(() {
        loading = true;
      });
      var user = context.read<AppState>().user;
      var response = await getActiveOrders(user['_id'], token)
          .then((value) => IApiResponse(value.data));
      setState(() {
        loading = false;
      });
      if (!response.success) {
        throw Exception(response.message);
      }
      print(response);
      setState(() {
        deliveryList = response.data;
      });
    } catch (e) {
      print(e);
      setState(() {
        loading = false;
      });
    }
  }

  String getStatus() {
    try {
      var order = context.read<AppState>().selectedOrder;
      switch (order['status']) {
        case "started":
          return "Open Map";
        default:
          return "Start Order";
      }
    } catch (e) {
      return "Start";
    }
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    token = context.read<AppState>().token ?? '';
    var pushSelectedOrder = context.read<AppState>().pushSelectedOrder;

    viewOrder() {
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
                  child: InkWell(
                    onTap: () {
                      try {
                        var order = context.read<AppState>().selectedOrder;
                        switch (order["status"]) {
                          case "started":
                            Navigator.pop(context);
                            Navigator.push(context,
                                MaterialPageRoute(builder: (context) => Map()));
                            break;
                          default:
                            _startOrder();
                            break;
                        }
                      } catch (err) {}
                    },
                    child: Container(
                      width: width,
                      alignment: Alignment.center,
                      margin: EdgeInsets.all(fixPadding),
                      padding: EdgeInsets.all(fixPadding),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(5.0),
                      ),
                      child: Text(
                        getStatus(),
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

    return ListView.builder(
      itemCount: deliveryList.length,
      physics: BouncingScrollPhysics(),
      itemBuilder: (context, index) {
        final item = deliveryList[index];
        return InkWell(
          onTap: viewOrder,
          child: Container(
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
                      viewOrder();
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
