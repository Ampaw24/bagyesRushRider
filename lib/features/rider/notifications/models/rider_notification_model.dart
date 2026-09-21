import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';

/// An inbox notification — `GET /notifications` (role-agnostic, shared with
/// the customer/vendor app on this backend). Confirmed live shape uses
/// `is_read`/`read_at`/`created_at`, not the old Node-era `read`/`createdAt`.
class RiderNotificationModel extends Equatable {
  final String id;
  final String? type;
  final String? title;
  final String? body;
  final Map<String, dynamic>? data;
  final bool read;
  final String? createdAt;

  const RiderNotificationModel({
    required this.id,
    this.type,
    this.title,
    this.body,
    this.data,
    this.read = false,
    this.createdAt,
  });

  RiderNotificationModel copyWith({bool? read}) => RiderNotificationModel(
        id: id,
        type: type,
        title: title,
        body: body,
        data: data,
        read: read ?? this.read,
        createdAt: createdAt,
      );

  DateTime get createdAtOrNow =>
      DateTime.tryParse(createdAt ?? '')?.toLocal() ?? DateTime.now();

  String get formattedDate {
    if (createdAt == null) return '';
    try {
      return DateFormat('MMM d, h:mm a').format(createdAtOrNow);
    } catch (_) {
      return createdAt!;
    }
  }

  factory RiderNotificationModel.fromJson(Map<String, dynamic> json) {
    return RiderNotificationModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      type: json['type'] as String?,
      title: json['title']?.toString(),
      body: json['body']?.toString() ?? json['message']?.toString(),
      data: json['data'] is Map<String, dynamic>
          ? json['data'] as Map<String, dynamic>
          : null,
      read: json['is_read'] == true || json['read_at'] != null,
      createdAt:
          json['created_at']?.toString() ?? json['createdAt']?.toString(),
    );
  }

  @override
  List<Object?> get props => [id, type, title, body, read, createdAt];
}
