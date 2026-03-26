import 'dart:async';
import 'dart:convert';
import 'package:delivery_boy/constant/models.dart';
import 'package:delivery_boy/services/app.services.dart';
import 'package:delivery_boy/states/app.state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:delivery_boy/constant/constant.dart';
import 'package:delivery_boy/pages/home.dart';
import 'package:provider/provider.dart';

class OTPScreen extends StatefulWidget {
  @override
  _OTPScreenState createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  bool loading = false;
  String otp = "";

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    resendOtp();
  }

  Future<void> resendOtp() async {
    try {
      var loginData = context.read<AppState>().loginData;
      if (loginData["phone"] == null || loginData["phone"] == '') {
        return Navigator.pop(context);
      }
      var data = {"phoneNumber": loginData["phone"]};
      setState(() {
        loading = true;
      });
      var response = await sendOtp(data)
          .then((value) => IApiResponse(value.data));
      if (!response.success) {
        throw Exception(response.message);
      }
      setState(() {
        loading = false;
      });
      print(response.data);
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
                actions: [
                  TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text('Okay'))
                ],
                title: Text('OTP'),
                content: Text(
                    "An OTP has been sent to your phone for verification"));
          });
    } catch (e) {
      setState(() {
        loading = false;
      });
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
                actions: [
                  TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text('Okay'))
                ],
                title: Text('Oops!'),
                content: Text(e.toString()));
          });
    }
  }

  void _signup() async {
    try {
      var loginData = context.read<AppState>().loginData;
      if (otp.length < 5) {
        return;
      }
      var data = {
        "otp": otp,
        "phone": loginData["phone"],
        "password": loginData["password"]
      };
      setState(() {
        loading = true;
      });
      var response = await userSignupLogin(data)
          .then((value) => IApiResponse(value.data));
      setState(() {
        loading = false;
      });
      if (!response.success) {
        throw Exception(response.message);
      }
      context.read<AppState>().setToken(response.token);
      context.read<AppState>().setUser(response.data);

      showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
                actions: [
                  TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(context,
                            MaterialPageRoute(builder: (context) => Home()));
                      },
                      child: Text('Okay'))
                ],
                title: Text('Signup!'),
                content: Text("User account created successfully"));
          });
    } catch (e) {
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
                actions: [
                  TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text('Okay'))
                ],
                title: Text('Oops!'),
                content: Text(e.toString()));
          });
      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldBgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0.0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Colors.black,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: ListView(
        children: <Widget>[
          Container(
            padding: EdgeInsets.all(fixPadding * 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Verification',
                  style: bigHeadingStyle,
                ),
                heightSpace,
                Text(
                  'Enter the OTP code from the phone we just sent you.',
                  style: lightGreyStyle,
                ),
                heightSpace,
                heightSpace,
                heightSpace,
                heightSpace,
                // OTP Box Start
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    // 1 Start
                    Container(
                      width: 150,
                      height: 50,
                      margin: EdgeInsets.symmetric(horizontal: 5),
                      alignment: Alignment.center,
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
                          contentPadding: EdgeInsets.all(18.0),
                          border: InputBorder.none,
                        ),
                        onChanged: (v) {
                          otp = v.trim();
                        },
                      ),
                    ),
                  ],
                ),
                // OTP Box End
                heightSpace,
                heightSpace,
                heightSpace,
                heightSpace,
                heightSpace,
                heightSpace,
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Text('Didn\'t receive OTP Code!', style: lightGreyStyle),
                    widthSpace,
                    InkWell(
                      onTap: () {
                        resendOtp();
                      },
                      child: Text(
                        'Resend',
                        style: listItemTitleStyle,
                      ),
                    ),
                  ],
                ),
                heightSpace,
                heightSpace,
                heightSpace,
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: fixPadding),
                  child: InkWell(
                    onTap: loading ? null : _signup,
                    child: Container(
                      height: 50.0,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5.0),
                        color: primaryColor,
                      ),
                      child: loading
                          ? SpinKitRing(
                              color: Colors.white,
                              lineWidth: 2,
                              size: 25,
                            )
                          : Text(
                              'Submit',
                              style: wbuttonWhiteTextStyle,
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
