import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:delivery_boy/features/rider/notifications/models/rider_notification_model.dart';

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

  // TODO(backend): there is no `/rider/me/notifications` endpoint yet — the
  // old Node `/notifications/user/:id` route 404s on the Laravel backend, so
  // this is stubbed to an empty inbox until a replacement endpoint exists.
  Future<void> load() async {
    state = state.copyWith(
      status: NotificationsStatus.loaded,
      notifications: const [],
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
