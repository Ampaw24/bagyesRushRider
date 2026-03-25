import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:delivery_boy/core/di/service_locator.dart';
import 'package:delivery_boy/core/services/user_session_manager.dart';
import 'package:delivery_boy/features/rider/notifications/models/rider_notification_model.dart';
import 'package:delivery_boy/features/rider/notifications/repositories/rider_notifications_repository.dart';

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
  }) {
    return RiderNotificationsState(
      status: status ?? this.status,
      notifications: notifications ?? this.notifications,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, notifications, errorMessage];
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class RiderNotificationsNotifier extends Notifier<RiderNotificationsState> {
  @override
  RiderNotificationsState build() => const RiderNotificationsState();

  Future<void> load() async {
    state = state.copyWith(status: NotificationsStatus.loading);

    final userId = sl<UserSessionManager>().currentUser?['_id']?.toString();
    if (userId == null) {
      state = state.copyWith(
        status: NotificationsStatus.error,
        errorMessage: 'User not found',
      );
      return;
    }

    final result =
        await sl<RiderNotificationsRepository>().getNotifications(userId);

    result.fold(
      (failure) => state = state.copyWith(
        status: NotificationsStatus.error,
        errorMessage: failure.message,
      ),
      (notifications) => state = state.copyWith(
        status: NotificationsStatus.loaded,
        notifications: notifications,
      ),
    );
  }

  void dismiss(String id) {
    final updated = state.notifications.where((n) => n.id != id).toList();
    state = state.copyWith(notifications: updated);
  }

  void clearError() => state = state.copyWith(errorMessage: null);
}

// ── Provider ──────────────────────────────────────────────────────────────────

final riderNotificationsProvider =
    NotifierProvider<RiderNotificationsNotifier, RiderNotificationsState>(
  RiderNotificationsNotifier.new,
);
