import 'dart:async';
import 'dart:convert';

import 'package:delivery_boy/services/app.services.dart';
import 'package:delivery_boy/states/app.state.dart';
import 'package:flutter/material.dart';
import 'package:delivery_boy/constant/constant.dart';
import 'package:provider/provider.dart';
import 'package:hugeicons/hugeicons.dart';

class Notifications extends StatefulWidget {
  @override
  _NotificationsState createState() => _NotificationsState();
}

class _NotificationsState extends State<Notifications> {
  var pushNotifications;
  var user;
  var token;

  bool loading = false;

  @override
  void initState() {
    super.initState();
    Timer(Duration(seconds: 1), () { loadNotifications(); });
  }

  Future loadNotifications() async {
    try {
      setState(() {
        loading = true;
      });
      var response = await getNotifications(user['_id'], token)
          .then((value) => value.data);
      setState(() {
        loading = false;
      });
      switch (response['success']) {
        case true:
          pushNotifications(response['data']);
          break;
        default:
      }
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    var notifications = context.read<AppState>().userNotifications;
    user = context.read<AppState>().userInfo;
    token = context.read<AppState>().accessToken;
    pushNotifications = context.read<AppState>().pushNotifications;

    return Scaffold(
      backgroundColor: scaffoldBgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0.0,
        leading: IconButton(
          icon: Icon(
            HugeIcons.strokeRoundedArrowLeft01,
            color: Colors.black,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text('Notifications', style: bigHeadingStyle),
      ),
      body: (notifications.length == 0)
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Icon(
                    HugeIcons.strokeRoundedNotificationOff01,
                    color: Colors.grey,
                    size: 60.0,
                  ),
                  SizedBox(
                    height: 20.0,
                  ),
                  Text(
                    'No Notifications',
                    style: greyHeadingStyle,
                  )
                ],
              ),
            )
          : ListView.builder(
              physics: BouncingScrollPhysics(),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final item = notifications[index];
                return Dismissible(
                  key: Key('$item'),
                  onDismissed: (direction) {
                    setState(() {
                      notifications.removeAt(index);
                    });

                    // Then show a snackbar.
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("${item['title']} dismissed")));
                  },
                  // Show a red background as the item is swiped away.
                  background: Container(color: Colors.red),
                  child: Center(
                    child: Container(
                      width: width - 20.0,
                      margin: EdgeInsets.only(top: 3.0, bottom: 3.0),
                      child: Card(
                        elevation: 2.0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            Container(
                              alignment: Alignment.topLeft,
                              padding: EdgeInsets.all(10.0),
                              child: CircleAvatar(
                                child: Icon(
                                  HugeIcons.strokeRoundedNotification01,
                                  size: 30.0,
                                ),
                                radius: 40.0,
                              ),
                            ),
                            Container(
                              width: width - 130.0,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Padding(
                                    padding: EdgeInsets.only(
                                        top: 8.0, right: 8.0, left: 8.0),
                                    child: Text(
                                      '${item['title']}',
                                      style: headingStyle,
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text(
                                      '${item['message']}',
                                      style: lightGreyStyle,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
