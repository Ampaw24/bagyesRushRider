import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';

class RiderNotificationModel extends Equatable {
  final String id;
  final String? title;
  final String? body;
  final bool read;
  final String? createdAt;

  const RiderNotificationModel({
    required this.id,
    this.title,
    this.body,
    this.read = false,
    this.createdAt,
  });

  String get formattedDate {
    if (createdAt == null) return '';
    try {
      final dt = DateTime.parse(createdAt!).toLocal();
      return DateFormat('MMM d, h:mm a').format(dt);
    } catch (_) {
      return createdAt!;
    }
  }

  factory RiderNotificationModel.fromJson(Map<String, dynamic> json) {
    return RiderNotificationModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      title: json['title']?.toString(),
      body: json['body']?.toString() ?? json['message']?.toString(),
      read: json['read'] == true,
      createdAt: json['createdAt']?.toString(),
    );
  }

  @override
  List<Object?> get props => [id, title, body, read, createdAt];
}
