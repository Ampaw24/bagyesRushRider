import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:delivery_boy/constant/app_theme.dart';
import 'package:delivery_boy/core/widgets/shimmer_list_placeholder.dart';
import 'package:delivery_boy/features/rider/notifications/models/rider_notification_model.dart';
import 'package:delivery_boy/features/rider/notifications/providers/rider_notifications_providers.dart';
import 'package:hugeicons/hugeicons.dart';

// ═════════════════════════════════════════════════════════════════════════════
// MODELS
// ═════════════════════════════════════════════════════════════════════════════

enum _NotifType { order, payment, kyc, zone, system, promo }

/// Maps the backend's free-form `type` string to this screen's icon/color
/// styling — unrecognised or missing values fall back to [_NotifType.system]
/// rather than guessing.
_NotifType _notifTypeFromApi(String? type) {
  switch (type) {
    case 'order':
      return _NotifType.order;
    case 'payment':
      return _NotifType.payment;
    case 'kyc':
      return _NotifType.kyc;
    case 'zone':
      return _NotifType.zone;
    case 'promo':
      return _NotifType.promo;
    default:
      return _NotifType.system;
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// HELPERS
// ═════════════════════════════════════════════════════════════════════════════

String _groupLabel(DateTime dt) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(dt.year, dt.month, dt.day);
  final diff = today.difference(day).inDays;
  if (diff == 0) return 'Today';
  if (diff == 1) return 'Yesterday';
  return 'Earlier';
}

String _timeLabel(DateTime dt) {
  final now = DateTime.now();
  final diff = now.difference(dt);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) {
    final h = dt.hour;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = h >= 12 ? 'PM' : 'AM';
    final hour = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    return '$hour:$m $period';
  }
  if (diff.inDays == 1) return 'Yesterday';
  const months = [
    'Jan','Feb','Mar','Apr','May','Jun',
    'Jul','Aug','Sep','Oct','Nov','Dec'
  ];
  return '${months[dt.month - 1]} ${dt.day}';
}

({IconData icon, Color color, Color bg}) _notifStyle(_NotifType type) {
  switch (type) {
    case _NotifType.order:
      return (
        icon: HugeIcons.strokeRoundedDeliveryBox01,
        color: const Color(0xFFE65100),
        bg: const Color(0xFFFFF3E0),
      );
    case _NotifType.payment:
      return (
        icon: HugeIcons.strokeRoundedWallet01,
        color: AppColors.success,
        bg: const Color(0xFFE8F5E9),
      );
    case _NotifType.kyc:
      return (
        icon: HugeIcons.strokeRoundedUserCheck01,
        color: AppColors.info,
        bg: const Color(0xFFE3F2FD),
      );
    case _NotifType.zone:
      return (
        icon: HugeIcons.strokeRoundedMapsLocation01,
        color: const Color(0xFF7B1FA2),
        bg: const Color(0xFFF3E5F5),
      );
    case _NotifType.promo:
      return (
        icon: HugeIcons.strokeRoundedDiscount01,
        color: const Color(0xFFC2185B),
        bg: const Color(0xFFFCE4EC),
      );
    case _NotifType.system:
      return (
        icon: HugeIcons.strokeRoundedInformationCircle,
        color: AppColors.textSecondary,
        bg: AppColors.surfaceVariant,
      );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// MAIN SCREEN
// ═════════════════════════════════════════════════════════════════════════════

class RiderNotificationsScreen extends ConsumerStatefulWidget {
  const RiderNotificationsScreen({super.key});

  @override
  ConsumerState<RiderNotificationsScreen> createState() =>
      _RiderNotificationsScreenState();
}

class _RiderNotificationsScreenState
    extends ConsumerState<RiderNotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(riderNotificationsProvider.notifier).load();
    });
  }

  void _markAllRead() {
    HapticFeedback.lightImpact();
    ref.read(riderNotificationsProvider.notifier).markAllRead();
  }

  @override
  Widget build(BuildContext context) {
    final notifState = ref.watch(riderNotificationsProvider);
    final notifUnread = notifState.unreadCount;

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _NotificationsHeader(
              notifUnread: notifUnread,
              onMarkAllRead: notifUnread > 0 ? _markAllRead : null,
            ),
            Expanded(
              child: _NotificationsTab(
                isLoading: notifState.status == NotificationsStatus.loading ||
                    notifState.status == NotificationsStatus.initial,
                notifs: notifState.notifications,
                onMarkRead: (id) =>
                    ref.read(riderNotificationsProvider.notifier).markRead(id),
                // There is only one removal endpoint on the backend — both
                // swipe directions dismiss the notification the same way.
                onArchive: (id) =>
                    ref.read(riderNotificationsProvider.notifier).dismiss(id),
                onDelete: (id) =>
                    ref.read(riderNotificationsProvider.notifier).dismiss(id),
                onMarkAllRead: _markAllRead,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// HEADER  (plain widget — self-sizes, no fixed height)
// ═════════════════════════════════════════════════════════════════════════════

class _NotificationsHeader extends StatelessWidget {
  final int notifUnread;
  final VoidCallback? onMarkAllRead;

  const _NotificationsHeader({
    required this.notifUnread,
    this.onMarkAllRead,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return Container(
      color: AppColors.scaffold,
      child: Padding(
        padding: EdgeInsets.fromLTRB(w * 0.04, w * 0.03, w * 0.04, w * 0.02),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.maybePop(context),
              child: Container(
                width: w * 0.09,
                height: w * 0.09,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(w * 0.025),
                ),
                child: Icon(
                  HugeIcons.strokeRoundedArrowLeft01,
                  size: w * 0.048,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            SizedBox(width: w * 0.03),
            Expanded(
              child: Text(
                'Notifications',
                style: TextStyle(
                  fontSize: w * 0.055,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: onMarkAllRead != null
                  ? GestureDetector(
                      key: const ValueKey('markAll'),
                      onTap: onMarkAllRead,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: w * 0.03, vertical: w * 0.015),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(w * 0.05),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              HugeIcons.strokeRoundedCheckmarkCircle01,
                              size: w * 0.038,
                              color: AppColors.primary,
                            ),
                            SizedBox(width: w * 0.015),
                            Text(
                              'Mark all read',
                              style: TextStyle(
                                fontSize: w * 0.031,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : const SizedBox.shrink(key: ValueKey('empty')),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// NOTIFICATIONS LIST
// ═════════════════════════════════════════════════════════════════════════════

class _NotificationsTab extends StatelessWidget {
  final bool isLoading;
  final List<RiderNotificationModel> notifs;
  final ValueChanged<String> onMarkRead;
  final ValueChanged<String> onArchive;
  final ValueChanged<String> onDelete;
  final VoidCallback onMarkAllRead;

  const _NotificationsTab({
    required this.isLoading,
    required this.notifs,
    required this.onMarkRead,
    required this.onArchive,
    required this.onDelete,
    required this.onMarkAllRead,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const ShimmerListPlaceholder(itemCount: 5, itemHeight: 96);
    }
    if (notifs.isEmpty) return const _EmptyNotifications();

    // Group by date label
    final groups = <String, List<RiderNotificationModel>>{};
    for (final n in notifs) {
      groups.putIfAbsent(_groupLabel(n.createdAtOrNow), () => []).add(n);
    }
    const order = ['Today', 'Yesterday', 'Earlier'];
    final keys = order.where(groups.containsKey).toList();

    // Flatten into mixed list of headers + items
    final rows = <Object>[];
    for (final k in keys) {
      rows.add(k); // String = section header
      rows.addAll(groups[k]!);
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: rows.length,
      itemBuilder: (ctx, i) {
        final item = rows[i];
        if (item is String) return _SectionHeader(label: item);
        final notif = item as RiderNotificationModel;
        return _NotifCard(
          notif: notif,
          onTap: () => onMarkRead(notif.id),
          onArchive: () => onArchive(notif.id),
          onDelete: () => onDelete(notif.id),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return Padding(
      padding: EdgeInsets.fromLTRB(w * 0.045, w * 0.05, w * 0.045, w * 0.02),
      child: Row(
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: w * 0.029,
              fontWeight: FontWeight.w800,
              color: AppColors.textSecondary,
              letterSpacing: 1.2,
            ),
          ),
          SizedBox(width: w * 0.025),
          Expanded(
            child: Divider(
              color: AppColors.border,
              thickness: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotifCard extends StatelessWidget {
  final RiderNotificationModel notif;
  final VoidCallback onTap;
  final VoidCallback onArchive;
  final VoidCallback onDelete;

  const _NotifCard({
    required this.notif,
    required this.onTap,
    required this.onArchive,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final notifType = _notifTypeFromApi(notif.type);
    final style = _notifStyle(notifType);
    final isUnread = !notif.read;

    return Dismissible(
      key: ValueKey(notif.id),
      direction: DismissDirection.horizontal,
      // Right swipe → Archive
      background: _SwipeBackground(
        alignment: Alignment.centerLeft,
        color: const Color(0xFF1565C0),
        icon: HugeIcons.strokeRoundedArchive,
        label: 'Archive',
        padding: EdgeInsets.only(left: w * 0.06),
      ),
      // Left swipe → Delete
      secondaryBackground: _SwipeBackground(
        alignment: Alignment.centerRight,
        color: AppColors.error,
        icon: HugeIcons.strokeRoundedDelete01,
        label: 'Delete',
        padding: EdgeInsets.only(right: w * 0.06),
      ),
      confirmDismiss: (direction) async {
        HapticFeedback.mediumImpact();
        return true;
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.startToEnd) {
          onArchive();
        } else {
          onDelete();
        }
      },
      child: GestureDetector(
        onTap: isUnread ? onTap : null,
        child: Container(
          margin: EdgeInsets.symmetric(
              horizontal: w * 0.04, vertical: w * 0.013),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(w * 0.035),
            border: Border.all(color: AppColors.border, width: 0.8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(w * 0.034),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Left accent strip
                  Container(
                    width: 3.5,
                    color: isUnread ? AppColors.primary : Colors.transparent,
                  ),
                  // Card body
                  Expanded(
                    child: ColoredBox(
                      color: isUnread
                          ? AppColors.primary.withValues(alpha: 0.03)
                          : Colors.white,
                      child: Padding(
                        padding: EdgeInsets.all(w * 0.04),
                        child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon box
                Container(
                  width: w * 0.115,
                  height: w * 0.115,
                  decoration: BoxDecoration(
                    color: style.bg,
                    borderRadius: BorderRadius.circular(w * 0.028),
                  ),
                  child:
                      Icon(style.icon, color: style.color, size: w * 0.055),
                ),
                SizedBox(width: w * 0.035),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              notif.title ?? 'Notification',
                              style: TextStyle(
                                fontSize: w * 0.038,
                                fontWeight: isUnread
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isUnread
                                    ? AppColors.textPrimary
                                    : AppColors.textSecondary,
                                height: 1.3,
                              ),
                            ),
                          ),
                          SizedBox(width: w * 0.02),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                _timeLabel(notif.createdAtOrNow),
                                style: TextStyle(
                                  fontSize: w * 0.029,
                                  color: isUnread
                                      ? AppColors.primary
                                      : AppColors.textHint,
                                  fontWeight: isUnread
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                              ),
                              if (isUnread) ...[
                                SizedBox(height: w * 0.012),
                                Container(
                                  width: w * 0.02,
                                  height: w * 0.02,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: w * 0.015),
                      Text(
                        notif.body ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: w * 0.033,
                          color: AppColors.textSecondary,
                          height: 1.5,
                        ),
                      ),
                      SizedBox(height: w * 0.02),
                      // Type chip
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: w * 0.022, vertical: w * 0.008),
                        decoration: BoxDecoration(
                          color: style.bg,
                          borderRadius: BorderRadius.circular(w * 0.04),
                        ),
                        child: Text(
                          _chipLabel(notifType),
                          style: TextStyle(
                            fontSize: w * 0.027,
                            fontWeight: FontWeight.w600,
                            color: style.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),          // inner Row
          ),            // Padding
        ),              // ColoredBox
      ),                // Expanded (card body)
    ],
    ),                  // IntrinsicHeight Row
    ),                  // IntrinsicHeight
    ),                  // ClipRRect
    ),                  // Container
    ),                  // GestureDetector
  );                    // Dismissible
  }

  String _chipLabel(_NotifType type) {
    switch (type) {
      case _NotifType.order:
        return 'Delivery';
      case _NotifType.payment:
        return 'Payment';
      case _NotifType.kyc:
        return 'Account';
      case _NotifType.zone:
        return 'Zone';
      case _NotifType.promo:
        return 'Promo';
      case _NotifType.system:
        return 'System';
    }
  }
}

class _SwipeBackground extends StatelessWidget {
  final Alignment alignment;
  final Color color;
  final IconData icon;
  final String label;
  final EdgeInsets padding;

  const _SwipeBackground({
    required this.alignment,
    required this.color,
    required this.icon,
    required this.label,
    required this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return Container(
      margin: EdgeInsets.symmetric(
          horizontal: w * 0.04, vertical: w * 0.013),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(w * 0.035),
      ),
      padding: padding,
      alignment: alignment,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: w * 0.055),
          SizedBox(width: w * 0.02),
          Text(
            label,
            style: TextStyle(
              fontSize: w * 0.033,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// EMPTY STATES
// ═════════════════════════════════════════════════════════════════════════════

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications();

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: w * 0.26,
            height: w * 0.26,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.07),
              shape: BoxShape.circle,
            ),
            child: Icon(
              HugeIcons.strokeRoundedNotificationOff01,
              size: w * 0.13,
              color: AppColors.primary.withValues(alpha: 0.5),
            ),
          ),
          SizedBox(height: w * 0.06),
          Text(
            'All caught up!',
            style: TextStyle(
              fontSize: w * 0.048,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: w * 0.02),
          Text(
            'No new notifications right now.',
            style: TextStyle(
              fontSize: w * 0.036,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

