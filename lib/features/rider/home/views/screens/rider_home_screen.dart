import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:delivery_boy/constant/app_theme.dart';
import 'package:delivery_boy/core/di/service_locator.dart';
import 'package:delivery_boy/core/router/app_routes.dart';
import 'package:delivery_boy/core/services/user_session_manager.dart';
import 'package:delivery_boy/features/rider/auth/models/rider_user_model.dart';
import 'package:delivery_boy/features/rider/dashboard/views/screens/rider_dashboard_screen.dart';
import 'package:delivery_boy/features/rider/home/views/widgets/customer_drawer.dart';
import 'package:delivery_boy/features/rider/notifications/providers/rider_notifications_providers.dart';
import 'package:delivery_boy/features/rider/orders/models/rider_order_model.dart';
import 'package:delivery_boy/features/rider/orders/providers/rider_orders_providers.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data models (local / mock)
// ─────────────────────────────────────────────────────────────────────────────

class _Announcement {
  final String title;
  final String body;
  final Color color;
  final IconData icon;

  const _Announcement({
    required this.title,
    required this.body,
    required this.color,
    required this.icon,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class RiderHomeScreen extends ConsumerStatefulWidget {
  final VoidCallback onToggleQueue;
  final VoidCallback onViewAllOrders;
  final VoidCallback onViewWallet;

  const RiderHomeScreen({
    super.key,
    required this.onToggleQueue,
    required this.onViewAllOrders,
    required this.onViewWallet,
  });

  @override
  ConsumerState<RiderHomeScreen> createState() => _RiderHomeScreenState();
}

class _RiderHomeScreenState extends ConsumerState<RiderHomeScreen>
    with TickerProviderStateMixin {
  // Staggered section animations
  late final List<AnimationController> _sectionAnims;
  late final List<Animation<double>> _sectionFades;
  late final List<Animation<Offset>> _sectionSlides;

  // Announcement carousel
  final _pageCtrl = PageController(viewportFraction: 0.92);
  int _currentPage = 0;

  // Drawer
  bool _drawerOpen = false;
  void _openDrawer() => setState(() => _drawerOpen = true);
  void _closeDrawer() => setState(() => _drawerOpen = false);

  final _announcements = const [
    _Announcement(
      title: '🎉 Bonus Weekend',
      body: 'Earn 20% extra on every completed delivery this weekend. Keep riding!',
      color: Color(0xFF2563EB),
      icon: HugeIcons.strokeRoundedStar,
    ),
    _Announcement(
      title: '📍 New Delivery Zone',
      body: 'Osu and Cantonments are now active. Expect higher order volume.',
      color: Color(0xFF059669),
      icon: HugeIcons.strokeRoundedLocation01,
    ),
    _Announcement(
      title: '⚠️ Maintenance Notice',
      body: 'Brief downtime scheduled Sunday 2–3 AM. Orders pause during this window.',
      color: Color(0xFFD97706),
      icon: HugeIcons.strokeRoundedAlert01,
    ),
  ];

  @override
  void initState() {
    super.initState();

    const sectionCount = 4;
    _sectionAnims = List.generate(
      sectionCount,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 480),
      ),
    );
    _sectionFades = _sectionAnims
        .map((c) => CurvedAnimation(parent: c, curve: Curves.easeOut))
        .toList();
    _sectionSlides = _sectionAnims
        .map(
          (c) => Tween<Offset>(
            begin: const Offset(0, 0.07),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: c, curve: Curves.easeOutCubic)),
        )
        .toList();

    _startStagger();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(orderHistoryProvider.notifier).load();
    });
  }

  Future<void> _startStagger() async {
    for (int i = 0; i < _sectionAnims.length; i++) {
      await Future.delayed(Duration(milliseconds: 90 * i));
      if (mounted) _sectionAnims[i].forward();
    }
  }

  @override
  void dispose() {
    for (final c in _sectionAnims) c.dispose();
    _pageCtrl.dispose();
    super.dispose();
  }

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String get _riderName {
    final name = sl<UserSessionManager>().displayName ?? '';
    return name.isNotEmpty ? name.split(' ').first : 'Rider';
  }

  Widget _section(int index, Widget child) => FadeTransition(
        opacity: _sectionFades[index],
        child: SlideTransition(position: _sectionSlides[index], child: child),
      );

  void _handleLogout() => context.go(AppRoutes.login);

  void _handleDeleteAccount() {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Account', style: TextStyle(fontFamily: 'Mukta')),
        content: const Text(
          'Account deletion is not yet available. Contact support for assistance.',
          style: TextStyle(fontFamily: 'Mukta'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(fontFamily: 'Mukta')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final w = mq.size.width;
    final h = mq.size.height;
    final hPad = w * 0.05;

    final isOnline = ref.watch(riderQueueProvider);
    final unread = ref.watch(riderNotificationsProvider).unreadCount;
    final historyOrders = ref.watch(orderHistoryProvider).orders.take(2).toList();

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: Stack(
        children: [
          // ── Main scrollable content ──────────────────────────────────
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: h * 0.018),

                      // ── Header ────────────────────────────────────────
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: hPad),
                        child: _section(
                          0,
                          _HomeHeader(
                            greeting: _greeting,
                            name: _riderName,
                            unread: unread,
                            onMenu: _openDrawer,
                            onBell: () => context.push(AppRoutes.notifications),
                          ),
                        ),
                      ),

                      SizedBox(height: h * 0.022),

                      // ── Online / Offline card ─────────────────────────
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: hPad),
                        child: _section(
                          1,
                          _OnlineCard(
                            isOnline: isOnline,
                            onToggle: () {
                              HapticFeedback.lightImpact();
                              widget.onToggleQueue();
                            },
                          ),
                        ),
                      ),

                      SizedBox(height: h * 0.026),

                      // ── Announcements ─────────────────────────────────
                      _section(
                        2,
                        _AnnouncementsSection(
                          announcements: _announcements,
                          controller: _pageCtrl,
                          currentPage: _currentPage,
                          onPageChanged: (i) =>
                              setState(() => _currentPage = i),
                          hPad: hPad,
                          h: h,
                          w: w,
                        ),
                      ),

                      SizedBox(height: h * 0.026),

                      // ── Recent deliveries ─────────────────────────────
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: hPad),
                        child: _section(
                          3,
                          _RecentOrdersSection(
                            orders: historyOrders,
                            onShowAll: widget.onViewAllOrders,
                            w: w,
                            h: h,
                          ),
                        ),
                      ),

                      SizedBox(height: h * 0.04),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Drawer overlay ───────────────────────────────────────────
          if (_drawerOpen)
            CustomerDrawer(
              onClose: _closeDrawer,
              onOrders: widget.onViewAllOrders,
              onWallet: widget.onViewWallet,
              onLogout: _handleLogout,
              onDeleteAccount: _handleDeleteAccount,
              isVerified:
                  ref.watch(riderKycStatusProvider) == KycStatus.approved,
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────────────────────

class _HomeHeader extends StatelessWidget {
  final String greeting;
  final String name;
  final int unread;
  final VoidCallback onMenu;
  final VoidCallback onBell;

  const _HomeHeader({
    required this.greeting,
    required this.name,
    required this.unread,
    required this.onMenu,
    required this.onBell,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    return Row(
      children: [
        // Hamburger menu button
        GestureDetector(
          onTap: onMenu,
          child: Container(
            width: (w * 0.11).clamp(40.0, 50.0),
            height: (w * 0.11).clamp(40.0, 50.0),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(w * 0.032),
              border: Border.all(color: AppColors.border),
            ),
            child: Icon(
              HugeIcons.strokeRoundedMenu01,
              size: (w * 0.056).clamp(20.0, 24.0),
              color: AppColors.textPrimary,
            ),
          ),
        ),
        SizedBox(width: w * 0.03),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: TextStyle(
                  fontFamily: 'Mukta',
                  fontSize: (w * 0.034).clamp(12.0, 15.0),
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w400,
                ),
              ),
              SizedBox(height: w * 0.005),
              Text(
                name,
                style: TextStyle(
                  fontFamily: 'Mukta',
                  fontSize: (w * 0.058).clamp(20.0, 28.0),
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
        // Bell button
        GestureDetector(
          onTap: onBell,
          child: Container(
            width: (w * 0.11).clamp(40.0, 50.0),
            height: (w * 0.11).clamp(40.0, 50.0),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(w * 0.032),
              border: Border.all(color: AppColors.border),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  HugeIcons.strokeRoundedNotification01,
                  size: (w * 0.056).clamp(20.0, 24.0),
                  color: AppColors.textPrimary,
                ),
                if (unread > 0)
                  Positioned(
                    top: (w * 0.018).clamp(6.0, 9.0),
                    right: (w * 0.018).clamp(6.0, 9.0),
                    child: Container(
                      width: (w * 0.022).clamp(7.0, 10.0),
                      height: (w * 0.022).clamp(7.0, 10.0),
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Online / Offline card
// ─────────────────────────────────────────────────────────────────────────────

class _OnlineCard extends StatelessWidget {
  final bool isOnline;
  final VoidCallback onToggle;

  const _OnlineCard({required this.isOnline, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: w * 0.05,
        vertical: h * 0.022,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isOnline
              ? [const Color(0xFF059669), const Color(0xFF10B981)]
              : [const Color(0xFF374151), const Color(0xFF4B5563)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(w * 0.045),
        boxShadow: [
          BoxShadow(
            color: (isOnline ? const Color(0xFF059669) : const Color(0xFF374151))
                .withValues(alpha: 0.28),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Status dot + text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _PulseDot(active: isOnline),
                    SizedBox(width: w * 0.02),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: Text(
                        isOnline ? 'You\'re Online' : 'You\'re Offline',
                        key: ValueKey(isOnline),
                        style: TextStyle(
                          fontFamily: 'Mukta',
                          fontSize: (w * 0.048).clamp(16.0, 22.0),
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: h * 0.006),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Text(
                    isOnline
                        ? 'Accepting new delivery orders'
                        : 'Tap to start accepting orders',
                    key: ValueKey(isOnline),
                    style: TextStyle(
                      fontFamily: 'Mukta',
                      fontSize: (w * 0.032).clamp(11.0, 14.0),
                      color: Colors.white.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: w * 0.04),
          // Toggle switch
          GestureDetector(
            onTap: onToggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOut,
              width: (w * 0.14).clamp(52.0, 64.0),
              height: (w * 0.08).clamp(30.0, 36.0),
              decoration: BoxDecoration(
                color: isOnline
                    ? Colors.white.withValues(alpha: 0.25)
                    : Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(w * 0.05),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              child: Padding(
                padding: EdgeInsets.all(w * 0.008),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  alignment:
                      isOnline ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    width: (w * 0.065).clamp(24.0, 30.0),
                    height: (w * 0.065).clamp(24.0, 30.0),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isOnline
                          ? HugeIcons.strokeRoundedCheckmarkCircle01
                          : HugeIcons.strokeRoundedCancelCircle,
                      size: (w * 0.035).clamp(12.0, 16.0),
                      color: isOnline
                          ? const Color(0xFF059669)
                          : const Color(0xFF374151),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pulsing dot
// ─────────────────────────────────────────────────────────────────────────────

class _PulseDot extends StatefulWidget {
  final bool active;
  const _PulseDot({required this.active});

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _scale = Tween<double>(begin: 0.8, end: 1.2)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    if (widget.active) _ctrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_PulseDot old) {
    super.didUpdateWidget(old);
    if (widget.active != old.active) {
      widget.active ? _ctrl.repeat(reverse: true) : (_ctrl..stop()..value = 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final size = (w * 0.022).clamp(7.0, 10.0);
    return ScaleTransition(
      scale: _scale,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: widget.active ? Colors.white : Colors.white54,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Announcements carousel
// ─────────────────────────────────────────────────────────────────────────────

class _AnnouncementsSection extends StatelessWidget {
  final List<_Announcement> announcements;
  final PageController controller;
  final int currentPage;
  final ValueChanged<int> onPageChanged;
  final double hPad;
  final double h;
  final double w;

  const _AnnouncementsSection({
    required this.announcements,
    required this.controller,
    required this.currentPage,
    required this.onPageChanged,
    required this.hPad,
    required this.h,
    required this.w,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: hPad),
          child: Text(
            'Announcements',
            style: TextStyle(
              fontFamily: 'Mukta',
              fontSize: (w * 0.042).clamp(14.0, 18.0),
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        SizedBox(height: h * 0.012),
        SizedBox(
          height: (h * 0.16).clamp(110.0, 150.0),
          child: PageView.builder(
            controller: controller,
            onPageChanged: onPageChanged,
            itemCount: announcements.length,
            itemBuilder: (context, index) {
              final ann = announcements[index];
              return _AnnouncementCard(ann: ann, w: w, h: h);
            },
          ),
        ),
        SizedBox(height: h * 0.01),
        // Dot indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(announcements.length, (i) {
            final active = i == currentPage;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              margin: EdgeInsets.symmetric(horizontal: w * 0.008),
              width: active ? (w * 0.05).clamp(16.0, 22.0) : (w * 0.018).clamp(6.0, 8.0),
              height: (w * 0.018).clamp(6.0, 8.0),
              decoration: BoxDecoration(
                color: active
                    ? AppColors.primary
                    : AppColors.border,
                borderRadius: BorderRadius.circular(w * 0.01),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  final _Announcement ann;
  final double w;
  final double h;

  const _AnnouncementCard({required this.ann, required this.w, required this.h});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: w * 0.015),
      padding: EdgeInsets.symmetric(
        horizontal: w * 0.05,
        vertical: h * 0.018,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ann.color,
            ann.color.withValues(alpha: 0.75),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(w * 0.04),
        boxShadow: [
          BoxShadow(
            color: ann.color.withValues(alpha: 0.22),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: (w * 0.12).clamp(42.0, 52.0),
            height: (w * 0.12).clamp(42.0, 52.0),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(w * 0.03),
            ),
            child: Icon(
              ann.icon,
              size: (w * 0.06).clamp(22.0, 26.0),
              color: Colors.white,
            ),
          ),
          SizedBox(width: w * 0.04),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  ann.title,
                  style: TextStyle(
                    fontFamily: 'Mukta',
                    fontSize: (w * 0.04).clamp(14.0, 17.0),
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: h * 0.005),
                Text(
                  ann.body,
                  style: TextStyle(
                    fontFamily: 'Mukta',
                    fontSize: (w * 0.03).clamp(10.0, 13.0),
                    color: Colors.white.withValues(alpha: 0.88),
                    height: 1.35,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Recent orders section
// ─────────────────────────────────────────────────────────────────────────────

class _RecentOrdersSection extends StatelessWidget {
  final List<RiderOrderModel> orders;
  final VoidCallback onShowAll;
  final double w;
  final double h;

  const _RecentOrdersSection({
    required this.orders,
    required this.onShowAll,
    required this.w,
    required this.h,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            Expanded(
              child: Text(
                'Recent Deliveries',
                style: TextStyle(
                  fontFamily: 'Mukta',
                  fontSize: (w * 0.042).clamp(14.0, 18.0),
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            GestureDetector(
              onTap: onShowAll,
              child: Row(
                children: [
                  Text(
                    'Show all',
                    style: TextStyle(
                      fontFamily: 'Mukta',
                      fontSize: (w * 0.032).clamp(11.0, 14.0),
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(width: w * 0.01),
                  Icon(
                    HugeIcons.strokeRoundedArrowRight01,
                    size: (w * 0.038).clamp(13.0, 16.0),
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ],
        ),

        SizedBox(height: h * 0.014),

        if (orders.isEmpty)
          _EmptyOrders(w: w, h: h)
        else
          ...orders.map((order) => _MiniOrderCard(order: order, w: w, h: h)),
      ],
    );
  }
}

class _EmptyOrders extends StatelessWidget {
  final double w;
  final double h;

  const _EmptyOrders({required this.w, required this.h});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: h * 0.04),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(w * 0.04),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(
            HugeIcons.strokeRoundedDeliveryBox01,
            size: (w * 0.1).clamp(36.0, 48.0),
            color: AppColors.textHint,
          ),
          SizedBox(height: h * 0.012),
          Text(
            'No recent deliveries',
            style: TextStyle(
              fontFamily: 'Mukta',
              fontSize: (w * 0.036).clamp(12.0, 15.0),
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: h * 0.004),
          Text(
            'Your completed orders will appear here',
            style: TextStyle(
              fontFamily: 'Mukta',
              fontSize: (w * 0.03).clamp(10.0, 12.0),
              color: AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniOrderCard extends StatelessWidget {
  final RiderOrderModel order;
  final double w;
  final double h;

  const _MiniOrderCard({
    required this.order,
    required this.w,
    required this.h,
  });

  Color get _statusColor => switch (order.status) {
        'delivered' => AppColors.success,
        'en_route' || 'picked_up' => AppColors.primary,
        'heading_to_pickup' || 'arrived_at_pickup' => const Color(0xFFF59E0B),
        'accepted' => const Color(0xFF3182CE),
        _ => AppColors.textHint,
      };

  String get _statusLabel => switch (order.status) {
        'delivered' => 'Delivered',
        'en_route' => 'En Route',
        'picked_up' => 'Picked Up',
        'heading_to_pickup' => 'Heading to Pickup',
        'arrived_at_pickup' => 'At Pickup',
        'accepted' => 'Accepted',
        _ => order.status ?? 'Unknown',
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: h * 0.012),
      padding: EdgeInsets.symmetric(
        horizontal: w * 0.04,
        vertical: h * 0.016,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(w * 0.038),
        border: Border.all(color: AppColors.border, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: (w * 0.11).clamp(40.0, 50.0),
            height: (w * 0.11).clamp(40.0, 50.0),
            decoration: BoxDecoration(
              color: _statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(w * 0.03),
            ),
            child: Icon(
              HugeIcons.strokeRoundedDeliveryBox01,
              size: (w * 0.055).clamp(20.0, 24.0),
              color: _statusColor,
            ),
          ),
          SizedBox(width: w * 0.035),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '#${order.orderId}',
                  style: TextStyle(
                    fontFamily: 'Mukta',
                    fontSize: (w * 0.036).clamp(12.0, 15.0),
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: h * 0.003),
                Row(
                  children: [
                    Icon(
                      HugeIcons.strokeRoundedLocation01,
                      size: (w * 0.03).clamp(10.0, 13.0),
                      color: AppColors.textHint,
                    ),
                    SizedBox(width: w * 0.01),
                    Expanded(
                      child: Text(
                        order.deliveryLocation,
                        style: TextStyle(
                          fontFamily: 'Mukta',
                          fontSize: (w * 0.029).clamp(10.0, 12.0),
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(width: w * 0.02),

          // Amount + status
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                order.totalFormatted,
                style: TextStyle(
                  fontFamily: 'Mukta',
                  fontSize: (w * 0.036).clamp(12.0, 15.0),
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: h * 0.004),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: w * 0.02,
                  vertical: h * 0.003,
                ),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(w * 0.02),
                ),
                child: Text(
                  _statusLabel,
                  style: TextStyle(
                    fontFamily: 'Mukta',
                    fontSize: (w * 0.026).clamp(9.0, 11.0),
                    fontWeight: FontWeight.w600,
                    color: _statusColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
