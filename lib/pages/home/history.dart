import 'dart:convert';

import 'package:delivery_boy/components/order.component.dart';
import 'package:delivery_boy/components/orderDetails.component.dart';
import 'package:delivery_boy/constant/constant.dart';
import 'package:delivery_boy/constant/models.dart';
import 'package:delivery_boy/services/app.services.dart';
import 'package:delivery_boy/states/app.state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class History extends StatefulWidget {
  @override
  _HistoryState createState() => _HistoryState();
}

class _HistoryState extends State<History> {

  List deliveryList=[];
  bool loading=false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    fetchHistory();
  }

  Future<void> fetchHistory () async {
    try {
      final state = context.read<AppState>();
      final token=state.token ?? '';
      final userId=state.user['_id'];
      setState(() {
        loading=true;
      });
      var response=await getHistory(userId, token).then((value) => IApiResponse(jsonDecode(value.body)));
      if(!response.success){
        throw Exception(
          response.message
        );
      }
      setState(() {
        loading=false;
        deliveryList=response.data;
      });
    } catch (e) {
      print(e);
      setState(() {
        loading=false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

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
                    onTap: () {Navigator.pop(context);},
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
                        'Close',
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
                      'view Order',
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
