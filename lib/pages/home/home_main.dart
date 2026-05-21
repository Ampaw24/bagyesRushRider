import 'dart:convert';

import 'package:delivery_boy/constant/models.dart';
import 'package:delivery_boy/services/app.services.dart';
import 'package:delivery_boy/states/app.state.dart';
import 'package:flutter/material.dart';
import 'package:delivery_boy/constant/constant.dart';
import 'package:delivery_boy/pages/home/new_order.dart';
import 'package:delivery_boy/pages/home/active_order.dart';
import 'package:delivery_boy/pages/home/history.dart';
import 'package:provider/provider.dart';
import 'package:hugeicons/hugeicons.dart';

class HomeMain extends StatefulWidget {
  @override
  _HomeMainState createState() => _HomeMainState();
}

class _HomeMainState extends State<HomeMain> {
  bool loading = false;
  bool queue = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  void go_online() async {
    try {
      setState(() {
        loading = true;
      });
      var state = context.read<AppState>();
      var data = {
        "id": state.user["_id"],
        "data": {"queue": !queue}
      };
      var response = await updateCourier(data, state.token ?? '')
          .then((value) => IApiResponse(value.data));
      if (!response.success) {
        throw Exception(response.message);
      }
      setState(() {
        loading = false;
        queue = response.data["queue"];
      });
    } catch (e) {
      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: scaffoldBgColor,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: whiteColor,
          title: Text(
            'Bagyes Rush',
            style: bigHeadingStyle,
          ),
          actions: <Widget>[
            IconButton(
              icon: queue
                  ? Icon(HugeIcons.strokeRoundedToggleOn, color: Colors.green)
                  : Icon(HugeIcons.strokeRoundedToggleOff, color: blackColor),
              onPressed: () {
                go_online();
              },
            )
          ],
          bottom: TabBar(
            unselectedLabelColor: Colors.grey.withOpacity(0.3),
            labelColor: primaryColor,
            indicatorColor: primaryColor,
            tabs: [
              Tab(text: 'New'),
              Tab(text: 'Active'),
              Tab(text: 'History'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            NewOrder(),
            ActiveOrder(),
            History(),
          ],
        ),
      ),
    );
  }
}
