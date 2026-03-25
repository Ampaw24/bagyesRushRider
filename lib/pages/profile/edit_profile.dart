import 'dart:convert';
import 'dart:io';

import 'package:delivery_boy/constant/models.dart';
import 'package:delivery_boy/services/app.services.dart';
import 'package:delivery_boy/states/app.state.dart';
import 'package:flutter/material.dart';
import 'package:delivery_boy/constant/constant.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class EditProfile extends StatefulWidget {
  @override
  _EditProfileState createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  late AppState appState;
  bool loading = false;
  String token = '';
  var user;

  var nameController = TextEditingController();
  var phoneController = TextEditingController();
  var emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  Future<void> loadProfile() async {
    try {
      setState(() {
        loading = true;
      });
      var state = context.read<AppState>();
      var response = await loadUserProfile(state.user['_id'], state.token ?? '')
          .then((value) => IApiResponse(jsonDecode(value.body)));
      if (!response.success) {
        throw Exception(response.message);
      }
      setState(() {
        loading = false;
        state.setUser(response.data);
      });
    } catch (e) {
      setState(() {
        loading = false;
      });
    }
  }

  Future uploadPhoto(
      ImageSource media, String doc, BuildContext context) async {
    try {
      final picker = ImagePicker();
      var img = await picker.pickImage(source: media);
      if (img != null) {
        File filePath = File(img.path);
        Uint8List imagebytes = await filePath.readAsBytes();
        String base64string = base64.encode(imagebytes);
        setState(() {
          loading = false;
        });
        Map data;
        String userId = user['_id'];
        data = {"courier": userId, "id": doc, "image": base64string};
        var response = await uploadDoc(data, token)
            .then((res) => IApiResponse(jsonDecode(res.body)));
        if (!response.success) {
          throw Exception(response.message);
        }
        loadProfile();
        showDialog(
            context: context,
            builder: (context) => AlertDialog(
                  title: Text('Congatulations!'),
                  content: Text(response.message),
                  actions: [
                    TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text('Okay'))
                  ],
                ));
      }
    } catch (e) {
      setState(() {
        loading = false;
      });
      showDialog(
          context: context,
          builder: (context) => AlertDialog(
                title: Text('Oops!'),
                content: Text(e.toString()),
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

  void updateProfile(BuildContext context, String field) async {
    try {
      var data = {};
      String name = nameController.text;
      String email = emailController.text;

      switch (field) {
        case 'name':
          if (name == null) {
            throw Exception('Please enter a valid name');
          }
          data['name'] = name;
          break;
        case 'email':
          if (email == null) {
            throw Exception('Please enter a valid email');
          }
          data['email'] = email;
          break;
        default:
          throw Exception('Invalid input');
      }

      setState(() {
        loading = true;
      });
      var d = {"id": user['_id'], "data": data};
      var response = await updateCourier(d, token)
          .then((value) => IApiResponse(jsonDecode(value.body)));
      setState(() {
        loading = false;
      });
      if (!response.success) {
        throw Exception(response.message);
      }
      loadProfile();
      showDialog(
          context: context,
          builder: (context) => AlertDialog(
                title: Text('Oops!'),
                content: Text(response.message),
                actions: [
                  TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text('Okay'))
                ],
              ));
    } catch (e) {
      setState(() {
        loading = false;
      });
      showDialog(
          context: context,
          builder: (context) => AlertDialog(
                title: Text('Oops!'),
                content: Text(e.toString()),
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
    appState = context.read<AppState>();
    token = appState.accessToken;
    user = appState.userInfo;

    double width = MediaQuery.of(context).size.width;

    changeFullName() {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          // return object of type Dialog
          return Dialog(
            elevation: 0.0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0)),
            child: Container(
              height: 200.0,
              padding: EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Text(
                    "Change Full Name",
                    style: headingStyle,
                  ),
                  SizedBox(
                    height: 20.0,
                  ),
                  TextField(
                    onChanged: (value) {
                      nameController.text = value.trim();
                    },
                    style: buttonBlackTextStyle,
                    keyboardType: TextInputType.text,
                    decoration: InputDecoration(
                      hintText: 'Enter Your Full Name',
                      hintStyle: greyHeadingStyle,
                    ),
                  ),
                  SizedBox(height: 20.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: <Widget>[
                      InkWell(
                        onTap: () {
                          nameController.text = "";
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
                          updateProfile(context, 'name');
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
                            'Okay',
                            style: wbuttonWhiteTextStyle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    changePhoneNumber() {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          // return object of type Dialog
          return Dialog(
            elevation: 0.0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0)),
            child: Container(
              height: 200.0,
              padding: EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Text(
                    "Change Phone Number",
                    style: headingStyle,
                  ),
                  SizedBox(
                    height: 20.0,
                  ),
                  TextField(
                    controller: phoneController,
                    style: buttonBlackTextStyle,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Enter Phone Number',
                      hintStyle: greyHeadingStyle,
                    ),
                  ),
                  SizedBox(height: 20.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: <Widget>[
                      InkWell(
                        onTap: () {
                          nameController.text = "";
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
                          setState(() {
                            Navigator.pop(context);
                          });
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
                            'Okay',
                            style: wbuttonWhiteTextStyle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    changeEmail() {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          // return object of type Dialog
          return Dialog(
            elevation: 0.0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0)),
            child: Container(
              height: 200.0,
              padding: EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Text(
                    "Change Email",
                    style: headingStyle,
                  ),
                  SizedBox(
                    height: 20.0,
                  ),
                  TextField(
                    onChanged: (value) {
                      emailController.text = value.trim();
                    },
                    style: buttonBlackTextStyle,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: 'Enter Your Email Address',
                      hintStyle: greyHeadingStyle,
                    ),
                  ),
                  SizedBox(height: 20.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: <Widget>[
                      InkWell(
                        onTap: () {
                          nameController.text = "";
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
                          updateProfile(context, 'email');
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
                            'Okay',
                            style: wbuttonWhiteTextStyle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    return Scaffold(
      backgroundColor: scaffoldBgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0.0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: blackColor),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: <Widget>[
          Container(
              padding: EdgeInsets.all(fixPadding),
              alignment: Alignment.center,
              child: loading
                  ? SpinKitRing(
                      color: Colors.red,
                      lineWidth: 2,
                      size: 25,
                    )
                  : null),
        ],
      ),
      body: ListView(
        children: <Widget>[
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Container(
                decoration: BoxDecoration(
                    border: Border(
                        bottom: BorderSide(color: Colors.grey, width: 0.3))),
                child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: width / 1.5,
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  margin: EdgeInsets.only(bottom: 10),
                                  child: Text('Selfie',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w300,
                                          fontSize: 25)),
                                ),
                                Text(
                                  'This is the image customers see when requesting for a delivery and also can be used for verification purposes.',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey),
                                )
                              ]),
                        ),
                        InkWell(
                          onTap: () {
                            uploadPhoto(ImageSource.gallery, 'selfie', context);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(50),
                              border: Border.all(
                                  color: Colors.grey,
                                  width: 0.5,
                                  style: BorderStyle.solid),
                            ),
                            width: 45,
                            height: 45,
                            child: user['selfie'] != null
                                ? Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                  )
                                : Icon(
                                    Icons.upload_file,
                                    color: Colors.red,
                                  ),
                          ),
                        )
                      ],
                    )),
              ),
              Container(
                decoration: BoxDecoration(
                    border: Border(
                        bottom: BorderSide(color: Colors.grey, width: 0.3))),
                child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: width / 1.5,
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  margin: EdgeInsets.only(bottom: 10),
                                  child: Text('Driver\s Licence ( FRONT )',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w300,
                                          fontSize: 25)),
                                ),
                                Text(
                                  'Must be a valid licence with permit to use a motor bike.',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey),
                                )
                              ]),
                        ),
                        InkWell(
                          onTap: () {
                            uploadPhoto(
                                ImageSource.gallery, 'licenceFront', context);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(50),
                              border: Border.all(
                                  color: Colors.grey,
                                  width: 0.5,
                                  style: BorderStyle.solid),
                            ),
                            width: 45,
                            height: 45,
                            child: user['licenceFront'] != null
                                ? Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                  )
                                : Icon(
                                    Icons.upload_file,
                                    color: Colors.red,
                                  ),
                          ),
                        )
                      ],
                    )),
              ),
              Container(
                decoration: BoxDecoration(
                    border: Border(
                        bottom: BorderSide(color: Colors.grey, width: 0.3))),
                child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: width / 1.5,
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  margin: EdgeInsets.only(bottom: 10),
                                  child: Text('Driver\s Licence ( BACK )',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w300,
                                          fontSize: 25)),
                                ),
                                Text(
                                  'Must be a valid licence with permit to use a motor bike.',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey),
                                )
                              ]),
                        ),
                        InkWell(
                          onTap: () {
                            uploadPhoto(
                                ImageSource.gallery, 'licenceBack', context);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(50),
                              border: Border.all(
                                  color: Colors.grey,
                                  width: 0.5,
                                  style: BorderStyle.solid),
                            ),
                            width: 45,
                            height: 45,
                            child: user['licenceBack'] != null
                                ? Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                  )
                                : Icon(
                                    Icons.upload_file,
                                    color: Colors.red,
                                  ),
                          ),
                        )
                      ],
                    )),
              ),
              // Profile Image Start
              Container(
                decoration: BoxDecoration(
                    border: Border(
                        bottom: BorderSide(color: Colors.grey, width: 0.3))),
                child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: width / 1.5,
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  margin: EdgeInsets.only(bottom: 10),
                                  child: Text('Motor Insurance',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w300,
                                          fontSize: 25)),
                                ),
                                Text(
                                  'Upload Motor insurance',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey),
                                )
                              ]),
                        ),
                        InkWell(
                          onTap: () {
                            uploadPhoto(
                                ImageSource.gallery, 'motorIssurance', context);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(50),
                              border: Border.all(
                                  color: Colors.grey,
                                  width: 0.5,
                                  style: BorderStyle.solid),
                            ),
                            width: 45,
                            height: 45,
                            child: user['motorIssurance'] != null
                                ? Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                  )
                                : Icon(
                                    Icons.upload_file,
                                    color: Colors.red,
                                  ),
                          ),
                        )
                      ],
                    )),
              ),
              // Profile Image Start
              Container(
                decoration: BoxDecoration(
                    border: Border(
                        bottom: BorderSide(color: Colors.grey, width: 0.3))),
                child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: width / 1.5,
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  margin: EdgeInsets.only(bottom: 10),
                                  child: Text('Moto Road Worthy',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w300,
                                          fontSize: 25)),
                                ),
                                Text(
                                  'Upload motor road worthy document',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey),
                                )
                              ]),
                        ),
                        InkWell(
                          onTap: () {
                            uploadPhoto(
                                ImageSource.gallery, 'roadWorthy', context);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(50),
                              border: Border.all(
                                  color: Colors.grey,
                                  width: 0.5,
                                  style: BorderStyle.solid),
                            ),
                            width: 45,
                            height: 45,
                            child: user['roadWorthy'] != null
                                ? Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                  )
                                : Icon(
                                    Icons.upload_file,
                                    color: Colors.red,
                                  ),
                          ),
                        )
                      ],
                    )),
              ),
              Container(
                decoration: BoxDecoration(
                    border: Border(
                        bottom: BorderSide(color: Colors.grey, width: 0.3))),
                child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: width / 1.5,
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  margin: EdgeInsets.only(bottom: 10),
                                  child: Text('Moto Registration Number',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w300,
                                          fontSize: 25)),
                                ),
                                Text(
                                  'Upload motor registration number plate',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey),
                                )
                              ]),
                        ),
                        InkWell(
                          onTap: () {
                            uploadPhoto(
                                ImageSource.gallery, 'numberPlate', context);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(50),
                              border: Border.all(
                                  color: Colors.grey,
                                  width: 0.5,
                                  style: BorderStyle.solid),
                            ),
                            width: 45,
                            height: 45,
                            child: user['numberPlate'] != null
                                ? Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                  )
                                : Icon(
                                    Icons.upload_file,
                                    color: Colors.red,
                                  ),
                          ),
                        )
                      ],
                    )),
              ),
              // Profile Image Start
              Container(
                margin: EdgeInsets.only(top: 10, bottom: 10),
              ),
              InkWell(
                onTap: changeFullName,
                child: getTile('Full Name', user['name']),
              ),
              // Password End
              // Phone Start
              InkWell(
                onTap: null,
                child: getTile('Phone', user['phone']),
              ),
              // Phone End
              // Email Start
              InkWell(
                onTap: changeEmail,
                child: getTile('Email', user['email']),
              ),
              // Email End
            ],
          ),
        ],
      ),
    );
  }

  getTile(String title, String value) {
    double width = MediaQuery.of(context).size.width;
    return Container(
      margin: EdgeInsets.only(
          right: fixPadding, left: fixPadding, bottom: fixPadding * 1.5),
      padding: EdgeInsets.only(
        right: fixPadding,
        left: fixPadding,
        top: fixPadding * 2.0,
        bottom: fixPadding * 2.0,
      ),
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
          Container(
            width: width - 80.0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                Container(
                  width: (width - 80.0) / 2.4,
                  child: Text(
                    title,
                    style: greyHeadingStyle,
                  ),
                ),
                Container(
                  width: (width - 80.0) / 2.0,
                  child: Text(
                    value,
                    style: headingStyle,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            size: 16.0,
            color: Colors.grey.withOpacity(0.6),
          ),
        ],
      ),
    );
  }

  // Bottom Sheet for Select Options (Camera or Gallery) Start Here
  void _selectOptionBottomSheet() {
    double width = MediaQuery.of(context).size.width;
    showModalBottomSheet(
        context: context,
        builder: (BuildContext bc) {
          return Container(
            color: whiteColor,
            child: new Wrap(
              children: <Widget>[
                Container(
                  child: Container(
                    padding: EdgeInsets.only(bottom: 20, left: 10, right: 10),
                    child: Column(
                      children: <Widget>[
                        Container(
                          width: width,
                          padding: EdgeInsets.all(10.0),
                          child: Text(
                            'Choose Option',
                            textAlign: TextAlign.center,
                            style: headingStyle,
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            Navigator.pop(context);
                            uploadPhoto(ImageSource.camera, 'FRONT', context);
                          },
                          child: Container(
                            width: width,
                            padding: EdgeInsets.all(10.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[
                                Icon(
                                  Icons.camera_alt,
                                  color: Colors.black.withOpacity(0.7),
                                  size: 18.0,
                                ),
                                SizedBox(
                                  width: 10.0,
                                ),
                                Text(
                                  'Camera',
                                  style: listItemTitleStyle,
                                ),
                              ],
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            Navigator.pop(context);
                            uploadPhoto(ImageSource.gallery, 'BACK', context);
                          },
                          child: Container(
                            width: width,
                            padding: EdgeInsets.all(10.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[
                                Icon(
                                  Icons.photo_album,
                                  color: Colors.black.withOpacity(0.7),
                                  size: 18.0,
                                ),
                                SizedBox(
                                  width: 10.0,
                                ),
                                Text(
                                  'Upload from Gallery',
                                  style: listItemTitleStyle,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              ],
            ),
          );
        });
  }
  // Bottom Sheet for Select Options (Camera or Gallery) Ends Here
}
