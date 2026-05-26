import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:delivery_boy/constant/app_theme.dart';
import 'package:delivery_boy/core/di/service_locator.dart';
import 'package:hugeicons/hugeicons.dart';

// ═════════════════════════════════════════════════════════════════════════════
// MODELS
// ═════════════════════════════════════════════════════════════════════════════

enum _NotifType { order, payment, kyc, zone, system, promo }

class _Notif {
  final String id;
  final String title;
  final String body;
  final bool read;
  final DateTime createdAt;
  final _NotifType type;

  const _Notif({
    required this.id,
    required this.title,
    required this.body,
    required this.read,
    required this.createdAt,
    required this.type,
  });

  _Notif copyWith({bool? read}) => _Notif(
        id: id,
        title: title,
        body: body,
        read: read ?? this.read,
        createdAt: createdAt,
        type: type,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'read': read,
        'createdAt': createdAt.toIso8601String(),
        'type': type.name,
      };

  factory _Notif.fromJson(Map<String, dynamic> j) => _Notif(
        id: j['id'] as String,
        title: j['title'] as String,
        body: j['body'] as String,
        read: j['read'] as bool,
        createdAt: DateTime.parse(j['createdAt'] as String),
        type: _NotifType.values.firstWhere(
          (t) => t.name == j['type'],
          orElse: () => _NotifType.system,
        ),
      );
}

class _Thread {
  final String id;
  final String senderName;
  final String lastMessage;
  final String time;
  final int unread;
  final Color avatarColor;
  final bool isOnline;

  const _Thread({
    required this.id,
    required this.senderName,
    required this.lastMessage,
    required this.time,
    required this.unread,
    required this.avatarColor,
    this.isOnline = false,
  });

  String get initials {
    final parts = senderName.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return senderName.isNotEmpty ? senderName[0].toUpperCase() : '?';
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// MOCK DATA
// ═════════════════════════════════════════════════════════════════════════════

DateTime _ago({int days = 0, int hours = 0, int minutes = 0}) {
  return DateTime.now()
      .subtract(Duration(days: days, hours: hours, minutes: minutes));
}

List<_Notif> _buildMockNotifs() => [
      _Notif(
        id: 'n01',
        title: 'New Delivery Request',
        body:
            'A pickup is ready at Accra Mall, East Legon. Estimated 3.4 km from your location.',
        read: false,
        createdAt: _ago(minutes: 8),
        type: _NotifType.order,
      ),
      _Notif(
        id: 'n02',
        title: 'Payment Received',
        body:
            'GH₵ 28.50 has been credited to your wallet for order #BR-00421.',
        read: false,
        createdAt: _ago(hours: 1, minutes: 20),
        type: _NotifType.payment,
      ),
      _Notif(
        id: 'n03',
        title: 'KYC Approved ✓',
        body:
            'Your identity verification is complete. You can now go online and accept orders.',
        read: false,
        createdAt: _ago(hours: 3),
        type: _NotifType.kyc,
      ),
      _Notif(
        id: 'n04',
        title: 'New Zone Unlocked',
        body:
            'The Tema Industrial Area zone is now active. Deliveries in this zone earn 15% more.',
        read: true,
        createdAt: _ago(hours: 6, minutes: 45),
        type: _NotifType.zone,
      ),
      _Notif(
        id: 'n05',
        title: 'Order Completed',
        body: 'Order #BR-00418 delivered successfully to Osu Oxford Street. Great work!',
        read: false,
        createdAt: _ago(days: 1, hours: 2),
        type: _NotifType.order,
      ),
      _Notif(
        id: 'n06',
        title: 'Bonus Earnings Alert 🎉',
        body:
            'You completed 10 orders this week! GH₵ 50 bonus has been added to your wallet.',
        read: false,
        createdAt: _ago(days: 1, hours: 5),
        type: _NotifType.payment,
      ),
      _Notif(
        id: 'n07',
        title: 'Document Expiring Soon',
        body:
            'Your motor insurance document expires in 7 days. Upload a renewed copy to avoid suspension.',
        read: true,
        createdAt: _ago(days: 1, hours: 9),
        type: _NotifType.kyc,
      ),
      _Notif(
        id: 'n08',
        title: 'App Update Available',
        body:
            'BagyesRUSH v2.4 is out with faster order matching and improved maps. Update now.',
        read: true,
        createdAt: _ago(days: 3, hours: 11),
        type: _NotifType.system,
      ),
      _Notif(
        id: 'n09',
        title: 'Weekend Promo Active',
        body:
            'Earn double points on all deliveries this Saturday and Sunday from 8AM – 10PM.',
        read: true,
        createdAt: _ago(days: 4, hours: 7),
        type: _NotifType.promo,
      ),
      _Notif(
        id: 'n10',
        title: 'Account Verified',
        body:
            'Your BagyesRUSH rider account setup is complete. Welcome to the fleet!',
        read: true,
        createdAt: _ago(days: 6, hours: 14),
        type: _NotifType.kyc,
      ),
    ];

final _mockThreads = <_Thread>[
  const _Thread(
    id: 't1',
    senderName: 'BagyesRUSH Support',
    lastMessage: 'Your account has been verified! Welcome aboard 🎉',
    time: '10:30 AM',
    unread: 2,
    avatarColor: AppColors.primary,
    isOnline: true,
  ),
  const _Thread(
    id: 't2',
    senderName: 'Delivery Team',
    lastMessage: 'New delivery zones are now available in your area.',
    time: 'Yesterday',
    unread: 0,
    avatarColor: Color(0xFF0097A7),
  ),
  const _Thread(
    id: 't3',
    senderName: 'BagyesRUSH Admin',
    lastMessage: 'Please complete your document upload to go online.',
    time: 'Mon',
    unread: 1,
    avatarColor: AppColors.secondary,
  ),
];

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
// LOCAL STORE  — persists notifications in SharedPreferences (no API)
// ═════════════════════════════════════════════════════════════════════════════

class _LocalStore {
  static const _notifsKey = 'rider_notifs_v1';

  final SharedPreferences _prefs;
  _LocalStore(this._prefs);

  /// Load saved list; seeds mock data on first run.
  List<_Notif> load() {
    final raw = _prefs.getString(_notifsKey);
    if (raw == null) {
      final seed = _buildMockNotifs();
      _persist(seed);
      return seed;
    }
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((e) => _Notif.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // Corrupted data — re-seed.
      final seed = _buildMockNotifs();
      _persist(seed);
      return seed;
    }
  }

  /// Persist the current list.
  void save(List<_Notif> notifs) => _persist(notifs);

  void _persist(List<_Notif> notifs) {
    _prefs.setString(
      _notifsKey,
      jsonEncode(notifs.map((n) => n.toJson()).toList()),
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
    extends ConsumerState<RiderNotificationsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  late final _LocalStore _store;

  List<_Notif> _notifs = [];
  List<_Thread> _threads = List.from(_mockThreads);

  int get _notifUnread => _notifs.where((n) => !n.read).length;
  int get _msgUnread => _threads.fold(0, (s, t) => s + t.unread);

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() => setState(() {}));

    // Load from SharedPreferences (seeds mock data on first run).
    _store = _LocalStore(sl<SharedPreferences>());
    _notifs = _store.load();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  void _updateNotifs(List<_Notif> updated) {
    setState(() => _notifs = updated);
    _store.save(updated);
  }

  void _markRead(String id) => _updateNotifs(
        _notifs.map((n) => n.id == id ? n.copyWith(read: true) : n).toList(),
      );

  void _markAllRead() {
    HapticFeedback.lightImpact();
    _updateNotifs(_notifs.map((n) => n.copyWith(read: true)).toList());
  }

  void _archiveNotif(String id) =>
      _updateNotifs(_notifs.where((n) => n.id != id).toList());

  void _deleteNotif(String id) =>
      _updateNotifs(_notifs.where((n) => n.id != id).toList());

  void _dismissThread(String id) => setState(
      () => _threads = _threads.where((t) => t.id != id).toList());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _InboxHeader(
              tabIndex: _tab.index,
              notifUnread: _notifUnread,
              msgUnread: _msgUnread,
              tabController: _tab,
              onMarkAllRead: _notifUnread > 0 ? _markAllRead : null,
            ),
            Expanded(
              child: TabBarView(
                controller: _tab,
                physics: const BouncingScrollPhysics(),
                children: [
                  _NotificationsTab(
                    notifs: _notifs,
                    onMarkRead: _markRead,
                    onArchive: _archiveNotif,
                    onDelete: _deleteNotif,
                    onMarkAllRead: _markAllRead,
                  ),
                  _MessagesTab(
                    threads: _threads,
                    onDismiss: _dismissThread,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// INBOX HEADER  (plain widget — self-sizes, no fixed height)
// ═════════════════════════════════════════════════════════════════════════════

class _InboxHeader extends StatelessWidget {
  final int tabIndex;
  final int notifUnread;
  final int msgUnread;
  final TabController tabController;
  final VoidCallback? onMarkAllRead;

  const _InboxHeader({
    required this.tabIndex,
    required this.notifUnread,
    required this.msgUnread,
    required this.tabController,
    this.onMarkAllRead,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return Container(
      color: AppColors.scaffold,
      child: Column(
        children: [
          // Title row
          Padding(
            padding: EdgeInsets.fromLTRB(w * 0.04, w * 0.03, w * 0.04, 0),
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
                    'Inbox',
                    style: TextStyle(
                      fontSize: w * 0.055,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                // Mark all read — only on notif tab
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: (tabIndex == 0 && onMarkAllRead != null)
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
          SizedBox(height: w * 0.03),
          // Segmented bar
          _SegmentedBar(
            controller: tabController,
            notifUnread: notifUnread,
            msgUnread: msgUnread,
          ),
          SizedBox(height: w * 0.02),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// SEGMENTED TAB BAR
// ═════════════════════════════════════════════════════════════════════════════

class _SegmentedBar extends StatelessWidget {
  final TabController controller;
  final int notifUnread;
  final int msgUnread;

  const _SegmentedBar({
    required this.controller,
    required this.notifUnread,
    required this.msgUnread,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final selected = controller.index;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: w * 0.04),
      child: Container(
        height: w * 0.115,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(w * 0.03),
        ),
        child: Stack(
          children: [
            // Sliding pill
            AnimatedAlign(
              alignment:
                  selected == 0 ? Alignment.centerLeft : Alignment.centerRight,
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeInOutCubic,
              child: FractionallySizedBox(
                widthFactor: 0.5,
                child: Padding(
                  padding: EdgeInsets.all(w * 0.012),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(w * 0.022),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.07),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ),
            // Labels
            Row(
              children: [
                Expanded(
                  child: _SegLabel(
                    label: 'Notifications',
                    badge: notifUnread,
                    active: selected == 0,
                    onTap: () => controller.animateTo(0),
                  ),
                ),
                Expanded(
                  child: _SegLabel(
                    label: 'Messages',
                    badge: msgUnread,
                    active: selected == 1,
                    onTap: () => controller.animateTo(1),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SegLabel extends StatelessWidget {
  final String label;
  final int badge;
  final bool active;
  final VoidCallback onTap;

  const _SegLabel({
    required this.label,
    required this.badge,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: w * 0.036,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color:
                    active ? AppColors.textPrimary : AppColors.textSecondary,
              ),
              child: Text(label),
            ),
            if (badge > 0) ...[
              SizedBox(width: w * 0.015),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(
                    horizontal: w * 0.017, vertical: w * 0.006),
                decoration: BoxDecoration(
                  color: active
                      ? AppColors.primary
                      : AppColors.primary.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badge > 99 ? '99+' : '$badge',
                  style: TextStyle(
                    fontSize: w * 0.027,
                    fontWeight: FontWeight.w700,
                    color: active ? Colors.white : AppColors.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// NOTIFICATIONS TAB
// ═════════════════════════════════════════════════════════════════════════════

class _NotificationsTab extends StatelessWidget {
  final List<_Notif> notifs;
  final ValueChanged<String> onMarkRead;
  final ValueChanged<String> onArchive;
  final ValueChanged<String> onDelete;
  final VoidCallback onMarkAllRead;

  const _NotificationsTab({
    required this.notifs,
    required this.onMarkRead,
    required this.onArchive,
    required this.onDelete,
    required this.onMarkAllRead,
  });

  @override
  Widget build(BuildContext context) {
    if (notifs.isEmpty) return const _EmptyNotifications();

    // Group by date label
    final groups = <String, List<_Notif>>{};
    for (final n in notifs) {
      groups.putIfAbsent(_groupLabel(n.createdAt), () => []).add(n);
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
        return _NotifCard(
          notif: item as _Notif,
          onTap: () => onMarkRead((item).id),
          onArchive: () => onArchive((item).id),
          onDelete: () => onDelete((item).id),
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
  final _Notif notif;
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
    final style = _notifStyle(notif.type);
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
                              notif.title,
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
                                _timeLabel(notif.createdAt),
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
                        notif.body,
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
                          _chipLabel(notif.type),
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
// MESSAGES TAB
// ═════════════════════════════════════════════════════════════════════════════

class _MessagesTab extends StatelessWidget {
  final List<_Thread> threads;
  final ValueChanged<String> onDismiss;

  const _MessagesTab({required this.threads, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    if (threads.isEmpty) return const _EmptyMessages();

    final w = MediaQuery.sizeOf(context).width;
    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(vertical: w * 0.03),
      itemCount: threads.length,
      separatorBuilder: (_, __) =>
          Divider(height: 1, indent: w * 0.22, color: AppColors.divider),
      itemBuilder: (ctx, i) => _ThreadTile(
        thread: threads[i],
        onDismiss: () => onDismiss(threads[i].id),
      ),
    );
  }
}

class _ThreadTile extends StatelessWidget {
  final _Thread thread;
  final VoidCallback onDismiss;

  const _ThreadTile({required this.thread, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final hasUnread = thread.unread > 0;

    return Dismissible(
      key: ValueKey(thread.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: w * 0.05),
        color: AppColors.error,
        child: Icon(HugeIcons.strokeRoundedDelete01,
            color: Colors.white, size: w * 0.055),
      ),
      onDismissed: (_) => onDismiss(),
      child: InkWell(
        onTap: () {},
        child: Padding(
          padding: EdgeInsets.symmetric(
              horizontal: w * 0.04, vertical: w * 0.035),
          child: Row(
            children: [
              Stack(
                children: [
                  Container(
                    width: w * 0.135,
                    height: w * 0.135,
                    decoration: BoxDecoration(
                      color: thread.avatarColor,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        thread.initials,
                        style: TextStyle(
                          fontSize: w * 0.045,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  if (thread.isOnline)
                    Positioned(
                      right: 1,
                      bottom: 1,
                      child: Container(
                        width: w * 0.032,
                        height: w * 0.032,
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(width: w * 0.035),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            thread.senderName,
                            style: TextStyle(
                              fontSize: w * 0.038,
                              fontWeight: hasUnread
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          thread.time,
                          style: TextStyle(
                            fontSize: w * 0.029,
                            fontWeight:
                                hasUnread ? FontWeight.w600 : FontWeight.w400,
                            color: hasUnread
                                ? AppColors.primary
                                : AppColors.textHint,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: w * 0.01),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            thread.lastMessage,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: w * 0.033,
                              fontWeight: hasUnread
                                  ? FontWeight.w500
                                  : FontWeight.w400,
                              color: hasUnread
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                        if (hasUnread) ...[
                          SizedBox(width: w * 0.02),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: w * 0.018, vertical: w * 0.007),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${thread.unread}',
                              style: TextStyle(
                                fontSize: w * 0.027,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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

class _EmptyMessages extends StatelessWidget {
  const _EmptyMessages();

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
              color: AppColors.info.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              HugeIcons.strokeRoundedBubbleChatAdd,
              size: w * 0.13,
              color: AppColors.info.withValues(alpha: 0.6),
            ),
          ),
          SizedBox(height: w * 0.06),
          Text(
            'No messages yet',
            style: TextStyle(
              fontSize: w * 0.048,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: w * 0.02),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: w * 0.15),
            child: Text(
              'Support and team messages will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: w * 0.036,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
