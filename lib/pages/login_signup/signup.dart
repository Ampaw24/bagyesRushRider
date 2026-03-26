import 'dart:io';
import 'package:delivery_boy/states/app.state.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:delivery_boy/constant/asset_images.dart';
import 'package:delivery_boy/constant/constant.dart';
import 'package:delivery_boy/pages/login_signup/otp_screen.dart';
import 'package:provider/provider.dart';

class Signup extends StatefulWidget {
  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Signup> {
  String phone = '';
  String password = '';

  DateTime? currentBackPressTime;

  @override
  void initState() {
    super.initState();
  }

  void proceed(BuildContext context) {
    try {
      if (phone.length < 10) {
        throw Exception('Please enter a valid phone number');
      }
      if (password.length <= 0) {
        throw Exception('Please enter a valid password');
      }
      var data = {"phone": phone, "password": password};
      context.read<AppState>().setLogin(data);
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => OTPScreen()));
    } catch (e) {
      showDialog(
          context: context,
          builder: (BuildContext context) => AlertDialog(
                title: Text('Oops'),
                content: Text('Please enter  a valid phone'),
                actions: [
                  TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text('Okay'))
                ],
              ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldBgColor,
      body: WillPopScope(
        child: ListView(
          children: <Widget>[
            Padding(
              padding: EdgeInsets.all(fixPadding),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  heightSpace,
                  heightSpace,
                  heightSpace,
                  heightSpace,
                  heightSpace,
                  heightSpace,
                  Image.asset(
                    AssetImages.deliveryBoy,
                    width: 200.0,
                    fit: BoxFit.fitWidth,
                  ),
                  heightSpace,
                  heightSpace,
                  heightSpace,
                  heightSpace,
                  Text('Create your account', style: greyHeadingStyle),
                  heightSpace,
                  heightSpace,
                  Container(
                      padding: EdgeInsets.only(left: fixPadding, bottom: 5),
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
                      child: TextField(
                        style: headingStyle,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintStyle: TextStyle(color: Colors.grey),
                          hintText: 'Phone number',
                          contentPadding: EdgeInsets.all(18.0),
                          border: InputBorder.none,
                        ),
                        onChanged: (v) {
                          phone = v.trim();
                        },
                      )),
                  heightSpace,
                  Container(
                      padding: EdgeInsets.only(left: fixPadding, bottom: 5),
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
                      child: TextField(
                        style: headingStyle,
                        obscureText: true,
                        enableSuggestions: false,
                        autocorrect: false,
                        keyboardType: TextInputType.visiblePassword,
                        decoration: InputDecoration(
                          hintStyle: TextStyle(color: Colors.grey),
                          hintText: 'Password',
                          contentPadding: EdgeInsets.all(18.0),
                          border: InputBorder.none,
                        ),
                        onChanged: (v) {
                          password = v.trim();
                        },
                      )),
                  heightSpace,
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 0),
                    child: InkWell(
                      onTap: () => proceed(context),
                      child: Container(
                        height: 50.0,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5.0),
                          color: primaryColor,
                        ),
                        child: Text(
                          'Continue',
                          style: wbuttonWhiteTextStyle,
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
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
