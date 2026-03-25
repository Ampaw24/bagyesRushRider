import 'package:flutter/material.dart';


// define all state variables here;
class AppState with ChangeNotifier {
  var loginData;
  var user;
  var notifications = [];
  var orders = [];
  var activeOrders = [];
  var selectedOrder = {};

  String ?token;

  get userInfo => user;

  get tempLoginData => loginData;

  get accessToken => token;

  get userNotifications => notifications;

  void pushSelectedOrder(data) {
    selectedOrder = data;
  }

  void setToken(String t) {
    token = t;
  }

  void setLogin(data) {
    loginData = data;
  }

  void setUser(data) {
    user = data;
  }

  void pushNotifications(data) {
    notifications = data;
  }

  void pushOrders(data) {
    orders = data;
  }
}
