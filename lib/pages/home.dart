import 'dart:async';
import 'dart:io';

import 'package:delivery_boy/constant/constant.dart';
import 'package:delivery_boy/pages/profile/edit_profile.dart';
import 'package:delivery_boy/pages/profile/profile.dart';
import 'package:delivery_boy/states/app.state.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:delivery_boy/pages/home/home_main.dart';
import 'package:delivery_boy/pages/wallet.dart';
import 'package:provider/provider.dart';
import 'package:hugeicons/hugeicons.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  var user;
  int currentIndex = 0;
  DateTime? currentBackPressTime;
  @override
  void initState() {
    super.initState();
    currentIndex = 0;
  }

  void checkUser(BuildContext context) {
    user = context.read<AppState>().userInfo;
    Timer(Duration(seconds: 1), () {
      if (user['name'] == null ||
          user['email'] == null ||
          user['licenceBack'] == null ||
          user['licenceFront'] == null ||
          user['motorIssurance'] == null ||
          user['roadWorthy'] == null ||
          user['numberPlate'] == null ||
          user['selfie'] == null) {
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => EditProfile()));
      }
    });
  }

  void changePage(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {

    checkUser(context);

    return Scaffold(
      bottomNavigationBar: ClipRRect(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        child: BottomNavigationBar(
          backgroundColor: whiteColor,
          currentIndex: currentIndex,
          onTap: changePage,
          elevation: 8,
          selectedItemColor: primaryColor,
          unselectedItemColor: greyColor,
          items: <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(HugeIcons.strokeRoundedShoppingCart01),
              label: 'Order',
            ),
            BottomNavigationBarItem(
              icon: Icon(HugeIcons.strokeRoundedWallet01),
              label: 'Wallet',
            ),
            BottomNavigationBarItem(
              icon: Icon(HugeIcons.strokeRoundedUser),
              label: 'Profile',
            ),
          ],
        ),
      ),
      body: WillPopScope(
        child: (currentIndex == 0)
            ? HomeMain()
            : (currentIndex == 1)
                ? Wallet()
                : Profile(),
        onWillPop: () async {
          bool backStatus = onWillPop();
          if (backStatus) {
            exit(0);
          }
          return false;
        },
      ),
    );
  }

  onWillPop() {
    DateTime now = DateTime.now();
    if (currentBackPressTime == null ||
        now.difference(currentBackPressTime!) > Duration(seconds: 2)) {
      currentBackPressTime = now;
      Fluttertoast.showToast(
        msg: 'Press Back Once Again to Exit.',
        backgroundColor: Colors.black,
        textColor: whiteColor,
      );
      return false;
    } else {
      return true;
    }
  }
}
