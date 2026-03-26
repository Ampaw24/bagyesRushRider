/// Legacy service layer — used by lib/pages/ during migration to Clean Architecture.
/// All calls use the shared Dio instance from GetIt so the auth interceptor
/// handles token injection and 401 clearing automatically.
/// This file will be deleted once all old pages are removed.
import 'package:dio/dio.dart';
import 'package:delivery_boy/constant/api.dart';
import 'package:delivery_boy/core/di/service_locator.dart';

Dio get _dio => sl<Dio>();

// ── Auth ──────────────────────────────────────────────────────────────────────

Future<Response<dynamic>> login(Map<String, dynamic> data) {
  return _dio.post('$BASEURL/couriers/login', data: data);
}

Future<Response<dynamic>> userSignupLogin(Map<String, dynamic> data) {
  return _dio.post('$BASEURL/couriers/signup', data: data);
}

Future<Response<dynamic>> sendOtp(Map<String, dynamic> data) {
  return _dio.post('$BASEURL/otp/send', data: data);
}

// ── Couriers ──────────────────────────────────────────────────────────────────

Future<Response<dynamic>> loadUserProfile(String id, String token) {
  return _dio.get('$BASEURL/couriers/details/$id');
}

Future<Response<dynamic>> updateCourier(Map<String, dynamic> data,
    String token) {
  return _dio.put('$BASEURL/couriers/update', data: data);
}

Future<Response<dynamic>> uploadDoc(Map<String, dynamic> data, String token) {
  return _dio.put('$BASEURL/couriers/upload/doc', data: data);
}

// ── Orders ────────────────────────────────────────────────────────────────────

Future<Response<dynamic>> getOrders(String token) {
  return _dio.get('$BASEURL/orders/get');
}

Future<Response<dynamic>> getRequested(String id, String token) {
  return _dio.get('$BASEURL/orders/requested/$id');
}

Future<Response<dynamic>> getActiveOrders(String courierId, String token) {
  return _dio.get('$BASEURL/orders/active/$courierId');
}

Future<Response<dynamic>> getHistory(String id, String token) {
  return _dio.get('$BASEURL/orders/history/$id');
}

Future<Response<dynamic>> acceptOrder(Map<String, dynamic> data, String token) {
  return _dio.post('$BASEURL/orders/accept', data: data);
}

Future<Response<dynamic>> rejectOrder(Map<String, dynamic> data, String token) {
  return _dio.put('$BASEURL/orders/reject', data: data);
}

Future<Response<dynamic>> updateOrder(Map<String, dynamic> data, String token) {
  return _dio.put('$BASEURL/orders/update', data: data);
}

Future<Response<dynamic>> setTrip(Map<String, dynamic> data, String token) {
  return _dio.put('$BASEURL/orders/trip/set', data: data);
}

Future<Response<dynamic>> finishTrip(Map<String, dynamic> data, String token) {
  return _dio.put('$BASEURL/orders/trip/finish', data: data);
}

Future<Response<dynamic>> updateRiderLocation(
    Map<String, dynamic> data, String token) {
  return _dio.put('$BASEURL/orders/location/update', data: data);
}

// ── Earnings ──────────────────────────────────────────────────────────────────

Future<Response<dynamic>> getEarnings(String id, String token) {
  return _dio.get('$BASEURL/earnings/user/$id');
}

// ── Notifications ─────────────────────────────────────────────────────────────

Future<Response<dynamic>> getNotifications(String id, String token) {
  return _dio.get('$BASEURL/notifications/user/$id');
}
