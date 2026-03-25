import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:delivery_boy/constant/api.dart';

Future<http.Response> loadUserProfile(String id, String token) {
  Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ' + token
  };
  return http.get(
    Uri.parse("$BASEURL/couriers/details/$id"),
    headers: headers,
  );
}

Future<http.Response> login(data) {
  const headers = {'Content-Type': 'application/json'};
  return http.post(
    Uri.parse("$BASEURL/couriers/login"),
    headers: headers,
    body: jsonEncode(data),
  );
}

Future<http.Response> userSignupLogin(data) {
  const headers = {'Content-Type': 'application/json'};
  return http.post(
    Uri.parse("$BASEURL/couriers/signup"),
    headers: headers,
    body: jsonEncode(data),
  );
}

Future<http.Response> getNotifications(String id, String token) {
  Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ' + token
  };
  return http.get(Uri.parse("$BASEURL/notifications/user/$id"),
      headers: headers);
}

Future<http.Response> uploadDoc(dynamic data, String token) {
  Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ' + token
  };
  return http.put(Uri.parse("$BASEURL/couriers/upload/doc"),
      headers: headers, body: jsonEncode(data));
}

Future<http.Response> updateRiderLocation(dynamic data, String token) {
  Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ' + token
  };
  return http.put(Uri.parse("$BASEURL/orders/location/update"),
      headers: headers, body: jsonEncode(data));
}


Future<http.Response> getEarnings(String id, String token) {
  Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ' + token
  };
  return http.get(Uri.parse("$BASEURL/earnings/user/$id"),
      headers: headers);
}


Future<http.Response> getHistory(String id, String token) {
  Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ' + token
  };
  return http.get(Uri.parse("$BASEURL/orders/history/$id"),
      headers: headers);
}


Future<http.Response> rejectOrder(dynamic data, String token) {
  Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ' + token
  };
  return http.put(Uri.parse("$BASEURL/orders/reject"),
      headers: headers, body: jsonEncode(data));
}


Future<http.Response> acceptOrder(dynamic data, String token) {
  Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ' + token
  };
  return http.post(Uri.parse("$BASEURL/orders/accept"),
      headers: headers, body: jsonEncode(data));
}

Future<http.Response> finishTrip(dynamic data, String token) {
  Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ' + token
  };
  return http.put(Uri.parse("$BASEURL/orders/trip/finish"),
      headers: headers, body: jsonEncode(data));
}

Future<http.Response> setTrip(dynamic data, String token) {
  Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ' + token
  };
  return http.put(Uri.parse("$BASEURL/orders/trip/set"),
      headers: headers, body: jsonEncode(data));
}

Future<http.Response> getActiveOrders(String courierId, String token) {
  Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ' + token
  };
  return http.get(Uri.parse("$BASEURL/orders/active/$courierId"),
      headers: headers);
}

Future<http.Response> getOrders(String token) {
  var headers = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ' + token
  };
  return http.get(Uri.parse("$BASEURL/orders/get"),
      headers: headers);
}



Future<http.Response> getRequested(String id, String token) {
  var headers = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ' + token
  };
  return http.get(Uri.parse("$BASEURL/orders/requested/$id"),
      headers: headers);
}

Future<http.Response> updateCourier(data, String token) {
  Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ' + token
  };
  return http.put(Uri.parse("$BASEURL/couriers/update"),
      headers: headers, body: jsonEncode(data));
}

Future<http.Response> updateOrder(data, String token) {
  Map<String, String> headers = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ' + token
  };
  return http.put(Uri.parse("$BASEURL/orders/update"),
      headers: headers, body: jsonEncode(data));
}

Future<http.Response> sendOtp(data) {
  const headers = {'Content-Type': 'application/json'};
  return http.post(Uri.parse("$BASEURL/otp/send"),
      headers: headers, body: jsonEncode(data));
}
