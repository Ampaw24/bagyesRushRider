import 'package:delivery_boy/constant/typedef.dart';
import 'package:delivery_boy/features/rider/notifications/models/rider_notification_model.dart';

abstract class RiderNotificationsRepository {
  ResultFuture<List<RiderNotificationModel>> getNotifications(String userId);
}
