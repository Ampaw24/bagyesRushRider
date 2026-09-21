import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:delivery_boy/core/di/service_locator.dart';
import 'package:delivery_boy/features/rider/notifications/models/rider_notification_model.dart';
import 'package:delivery_boy/features/rider/notifications/repositories/rider_notification_repository.dart';

// ── Status ────────────────────────────────────────────────────────────────────

enum NotificationsStatus { initial, loading, loaded, error }

// ── State ─────────────────────────────────────────────────────────────────────

class RiderNotificationsState extends Equatable {
  final NotificationsStatus status;
  final List<RiderNotificationModel> notifications;
  final String? errorMessage;

  const RiderNotificationsState({
    this.status = NotificationsStatus.initial,
    this.notifications = const [],
    this.errorMessage,
  });

  int get unreadCount => notifications.where((n) => !n.read).length;

  RiderNotificationsState copyWith({
    NotificationsStatus? status,
    List<RiderNotificationModel>? notifications,
    String? errorMessage,
    bool clearError = false,
  }) {
    return RiderNotificationsState(
      status: status ?? this.status,
      notifications: notifications ?? this.notifications,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [status, notifications, errorMessage];
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class RiderNotificationsNotifier extends Notifier<RiderNotificationsState> {
  @override
  RiderNotificationsState build() => const RiderNotificationsState();

  RiderNotificationRepository get _repo => sl<RiderNotificationRepository>();

  Future<void> load() async {
    state = state.copyWith(status: NotificationsStatus.loading, clearError: true);
    final result = await _repo.getNotifications();
    result.fold(
      (f) => state = state.copyWith(
          status: NotificationsStatus.error, errorMessage: f.message),
      (notifications) => state = state.copyWith(
          status: NotificationsStatus.loaded, notifications: notifications),
    );
  }

  /// Optimistic — flips locally immediately, then confirms with the server.
  Future<void> markRead(String id) async {
    state = state.copyWith(
      notifications: state.notifications
          .map((n) => n.id == id ? n.copyWith(read: true) : n)
          .toList(),
    );
    await _repo.markRead(id);
  }

  Future<void> markAllRead() async {
    state = state.copyWith(
      notifications:
          state.notifications.map((n) => n.copyWith(read: true)).toList(),
    );
    await _repo.markAllRead();
  }

  /// Removes the notification locally, then deletes it server-side. Restores
  /// it on failure so a swipe doesn't silently lose data the server rejected.
  Future<void> dismiss(String id) async {
    final previous = state.notifications;
    state = state.copyWith(
      notifications: previous.where((n) => n.id != id).toList(),
    );
    final result = await _repo.deleteNotification(id);
    result.fold(
      (f) => state = state.copyWith(notifications: previous),
      (_) {},
    );
  }

  void clearError() => state = state.copyWith(clearError: true);
}

// ── Provider ──────────────────────────────────────────────────────────────────

final riderNotificationsProvider =
    NotifierProvider<RiderNotificationsNotifier, RiderNotificationsState>(
  RiderNotificationsNotifier.new,
);
