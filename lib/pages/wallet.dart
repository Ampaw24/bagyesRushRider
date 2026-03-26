import 'dart:convert';

import 'package:delivery_boy/constant/constant.dart';
import 'package:delivery_boy/constant/models.dart';
import 'package:delivery_boy/services/app.services.dart';
import 'package:delivery_boy/states/app.state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class Wallet extends StatefulWidget {
  @override
  _WalletState createState() => _WalletState();
}

class _WalletState extends State<Wallet> {
  List earningList = [];
  bool loading = false;
  String totalAmount="0";

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _getEarnings();
  }

  String _getAmount() {
    try {
      return totalAmount.toString();
    } catch (e) {
      return "GHS0";
    }
  }

  void _getEarnings() async {
    try {
      setState(() {
        loading = true;
      });
      var state = context.read<AppState>();
      var response = await getEarnings(state.user['_id'], state.token ?? '')
          .then((value) => IApiResponse(value.data));
      if (!response.success) {
        throw Exception(response.message);
      }
      setState(() {
        loading = false;
        totalAmount = response.data['total'];
        earningList = response.data['earnings'];
      });
    } catch (e) {
      print(e);
      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: primaryColor,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(100.0), // here the desired height
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            AppBar(
              backgroundColor: primaryColor,
              automaticallyImplyLeading: false,
              centerTitle: true,
              elevation: 0.0,
              title: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Text(
                    'Earning',
                    style: bigWhiteHeadingStyle,
                  ),
                  heightSpace,
                  Text(
                    'GHS$totalAmount',
                    style: whiteHeadingStyle,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Container(
        width: width,
        height: height,
        color: primaryColor,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(10.0),
              topLeft: Radius.circular(10.0),
            ),
            color: scaffoldBgColor,
          ),
          child: ListView.builder(
            itemCount: earningList.length,
            physics: BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final item = earningList[index];
              print(item);
              return Container(
                padding: (index == 0)
                    ? EdgeInsets.only(
                        right: fixPadding,
                        left: fixPadding,
                        bottom: fixPadding,
                        top: fixPadding * 2.0)
                    : EdgeInsets.only(
                        right: fixPadding,
                        left: fixPadding,
                        bottom: fixPadding),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Container(
                      padding: EdgeInsets.all(fixPadding),
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
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              Icon(
                                Icons.fastfood,
                                size: 25.0,
                                color: primaryColor,
                              ),
                              widthSpace,
                              Text(item['description'] ?? "",
                                  style: headingStyle),
                            ],
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: <Widget>[
                              Text(_getAmount(), style: greyHeadingStyle),
                              SizedBox(height: 5.0),
                              Text('Earning', style: appbarHeadingStyle),
                            ],
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
