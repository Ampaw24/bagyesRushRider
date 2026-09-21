import 'package:dio/dio.dart';
import 'package:delivery_boy/core/network/api_endpoints.dart';

/// Raw Dio calls for `/notifications` — the in-app inbox, distinct from
/// [DeviceTokenApiService] (FCM device-token registration).
class RiderNotificationApiService {
  final Dio _dio;

  RiderNotificationApiService(this._dio);

  Future<Response<dynamic>> getNotifications() =>
      _dio.get(ApiEndpoints.notifications);

  Future<Response<dynamic>> markRead(String id) =>
      _dio.patch(ApiEndpoints.notificationRead(id));

  Future<Response<dynamic>> markAllRead() =>
      _dio.patch(ApiEndpoints.notificationsReadAll);

  Future<Response<dynamic>> deleteNotification(String id) =>
      _dio.delete(ApiEndpoints.notificationById(id));
}
