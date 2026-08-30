import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:delivery_boy/constant/app_theme.dart';
import 'package:delivery_boy/core/di/service_locator.dart';
import 'package:delivery_boy/core/router/app_routes.dart';
import 'package:delivery_boy/core/services/user_session_manager.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data model
// ─────────────────────────────────────────────────────────────────────────────

class _TileData {
  final IconData icon;
  final String label;
  final Color color;
  final bool isDestructive;

  const _TileData({
    required this.icon,
    required this.label,
    required this.color,
    this.isDestructive = false,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// CustomerDrawer — Stack-overlay animated side drawer
// ─────────────────────────────────────────────────────────────────────────────

class CustomerDrawer extends StatefulWidget {
  final VoidCallback onClose;
  final VoidCallback onOrders;
  final VoidCallback onWallet;
  final VoidCallback onLogout;
  final VoidCallback onDeleteAccount;

  /// Supplied by the parent, which already watches the rider profile —
  /// verification state lives on `GET /rider/me`, not in the session.
  final bool isVerified;

  const CustomerDrawer({
    super.key,
    required this.onClose,
    required this.onOrders,
    required this.onWallet,
    required this.onLogout,
    required this.onDeleteAccount,
    this.isVerified = false,
  });

  @override
  State<CustomerDrawer> createState() => _CustomerDrawerState();
}

class _CustomerDrawerState extends State<CustomerDrawer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _slideAnim;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _blurAnim;

  // Cubic approximation of easeOutExpo
  static const _easeOutExpo = Cubic(0.16, 1.0, 0.3, 1.0);

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _slideAnim = Tween<double>(begin: -1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.7, curve: _easeOutExpo),
      ),
    );

    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _blurAnim = Tween<double>(begin: 0.0, end: 6.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _ctrl.forward();
  }

  Future<void> _close() async {
    if (!mounted) return;
    await _ctrl.reverse();
    if (mounted) widget.onClose();
  }

  void _handleTap(_TileData item) {
    switch (item.label) {
      case 'My Profile':
        _close().then((_) { if (mounted) context.push(AppRoutes.editProfile); });
      case 'My Orders':
        _close().then((_) => widget.onOrders());
      case 'Notifications':
        _close().then((_) { if (mounted) context.push(AppRoutes.notifications); });
      case 'Wallet':
        _close().then((_) => widget.onWallet());
      case 'Delete Account':
        _close().then((_) => widget.onDeleteAccount());
      case 'Logout':
        _close().then((_) => widget.onLogout());
      default:
        _close();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final viewPadding = MediaQuery.viewPaddingOf(context);
    final w = size.width;
    final h = size.height;
    final drawerWidth = w * 0.78;

    // Session info
    final session = sl<UserSessionManager>();
    final name = (session.displayName ?? '').trim();
    final displayName = name.isNotEmpty ? name : 'Rider';
    final email = session.email ?? '';
    final isVerified = widget.isVerified;
    final initials = displayName
        .split(' ')
        .where((s) => s.isNotEmpty)
        .map((s) => s[0])
        .take(2)
        .join()
        .toUpperCase();

    final regularItems = <_TileData>[
      const _TileData(icon: HugeIcons.strokeRoundedUser,             label: 'My Profile',       color: AppColors.primary),
      const _TileData(icon: HugeIcons.strokeRoundedDeliveryBox01,    label: 'My Orders',        color: Color(0xFF3182CE)),
      const _TileData(icon: HugeIcons.strokeRoundedNotification01,   label: 'Notifications',    color: Color(0xFF2D3748)),
      const _TileData(icon: HugeIcons.strokeRoundedWallet01,         label: 'Wallet',           color: Color(0xFF059669)),
      const _TileData(icon: HugeIcons.strokeRoundedCreditCard,       label: 'Payment Methods',  color: Color(0xFF7C3AED)),
      const _TileData(icon: HugeIcons.strokeRoundedShield01,         label: 'Privacy Policy',   color: Color(0xFF0369A1)),
      const _TileData(icon: HugeIcons.strokeRoundedHeadphones,       label: 'Help & Support',   color: Color(0xFFD97706)),
    ];

    final bottomItems = <_TileData>[
      const _TileData(icon: HugeIcons.strokeRoundedDelete01,  label: 'Delete Account', color: AppColors.warning, isDestructive: true),
      const _TileData(icon: HugeIcons.strokeRoundedLogout01,  label: 'Logout',         color: AppColors.error,   isDestructive: true),
    ];

    return SizedBox.expand(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          return Stack(
            children: [
              // ── Blurred backdrop ───────────────────────────────────────────
              Positioned.fill(
                child: GestureDetector(
                  onTap: _close,
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: _blurAnim.value,
                      sigmaY: _blurAnim.value,
                    ),
                    child: Container(
                      color: Colors.black.withValues(
                        alpha: 0.35 * _fadeAnim.value,
                      ),
                    ),
                  ),
                ),
              ),

              // ── Sliding panel ──────────────────────────────────────────────
              Positioned(
                left: 0,
                top: h * 0.09,
                bottom: viewPadding.bottom + w * 0.22,
                child: Transform.translate(
                  offset: Offset(_slideAnim.value * drawerWidth, 0),
                  child: Container(
                    width: drawerWidth,
                    margin: EdgeInsets.symmetric(horizontal: w * 0.02),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(w * 0.07),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: w * 0.1,
                          offset: Offset(w * 0.02, w * 0.01),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(w * 0.07),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          _DrawerHeader(
                            ctrl: _ctrl,
                            name: displayName,
                            email: email,
                            initials: initials,
                            isVerified: isVerified,
                            onClose: _close,
                            w: w,
                            h: h,
                          ),

                          Divider(color: AppColors.divider, height: 1),

                          // Scrollable menu items
                          Expanded(
                            child: SingleChildScrollView(
                              padding: EdgeInsets.symmetric(vertical: h * 0.008),
                              child: Column(
                                children: List.generate(
                                  regularItems.length,
                                  (i) => _DrawerTile(
                                    item: regularItems[i],
                                    index: i,
                                    ctrl: _ctrl,
                                    w: w,
                                    h: h,
                                    onTap: () => _handleTap(regularItems[i]),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          Divider(color: AppColors.divider, height: 1),

                          // Bottom destructive actions
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: h * 0.008),
                            child: Column(
                              children: List.generate(
                                bottomItems.length,
                                (i) => _DrawerTile(
                                  item: bottomItems[i],
                                  index: regularItems.length + i,
                                  ctrl: _ctrl,
                                  w: w,
                                  h: h,
                                  onTap: () => _handleTap(bottomItems[i]),
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: h * 0.025),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Drawer header — avatar (bouncy scale) + name/email (fade)
// ─────────────────────────────────────────────────────────────────────────────

class _DrawerHeader extends StatelessWidget {
  final AnimationController ctrl;
  final String name;
  final String email;
  final String initials;
  final bool isVerified;
  final VoidCallback onClose;
  final double w;
  final double h;

  const _DrawerHeader({
    required this.ctrl,
    required this.name,
    required this.email,
    required this.initials,
    required this.isVerified,
    required this.onClose,
    required this.w,
    required this.h,
  });

  @override
  Widget build(BuildContext context) {
    final avatarScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: ctrl,
        curve: const Interval(0.2, 0.6, curve: Curves.easeOutBack),
      ),
    );

    final textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: ctrl,
        curve: const Interval(0.35, 0.7, curve: Curves.easeOut),
      ),
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(w * 0.05, h * 0.032, w * 0.04, h * 0.022),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Close button — top right
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: onClose,
              child: Container(
                padding: EdgeInsets.all(w * 0.022),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(w * 0.025),
                ),
                child: Icon(
                  HugeIcons.strokeRoundedCancelCircle,
                  size: (w * 0.048).clamp(18.0, 22.0),
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),

          SizedBox(height: h * 0.016),

          // Avatar + name/email row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Avatar — bouncy scale in
              ScaleTransition(
                scale: avatarScale,
                child: CircleAvatar(
                  radius: w * 0.07,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    initials,
                    style: TextStyle(
                      fontFamily: 'Mukta',
                      fontSize: (w * 0.048).clamp(16.0, 22.0),
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              SizedBox(width: w * 0.038),

              // Name → email → verification badge
              Expanded(
                child: FadeTransition(
                  opacity: textFade,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name
                      Text(
                        name,
                        style: TextStyle(
                          fontFamily: 'Mukta',
                          fontSize: (w * 0.042).clamp(14.0, 18.0),
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          height: 1.15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      // Email
                      if (email.isNotEmpty) ...[
                        SizedBox(height: h * 0.003),
                        Text(
                          email,
                          style: TextStyle(
                            fontFamily: 'Mukta',
                            fontSize: (w * 0.028).clamp(10.0, 12.0),
                            color: AppColors.textSecondary,
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],

                      SizedBox(height: h * 0.007),

                      // Verification status chip
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: w * 0.025,
                          vertical: h * 0.004,
                        ),
                        decoration: BoxDecoration(
                          color: isVerified
                              ? const Color(0xFF38A169).withValues(alpha: 0.12)
                              : const Color(0xFFDD6B20).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(w * 0.04),
                          border: Border.all(
                            color: isVerified
                                ? const Color(0xFF38A169).withValues(alpha: 0.35)
                                : const Color(0xFFDD6B20).withValues(alpha: 0.35),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isVerified
                                  ? HugeIcons.strokeRoundedCheckmarkBadge01
                                  : HugeIcons.strokeRoundedAlert01,
                              size: (w * 0.032).clamp(11.0, 14.0),
                              color: isVerified
                                  ? const Color(0xFF38A169)
                                  : const Color(0xFFDD6B20),
                            ),
                            SizedBox(width: w * 0.014),
                            Text(
                              isVerified ? 'Verified' : 'Not Verified',
                              style: TextStyle(
                                fontFamily: 'Mukta',
                                fontSize: (w * 0.028).clamp(10.0, 12.0),
                                fontWeight: FontWeight.w600,
                                color: isVerified
                                    ? const Color(0xFF38A169)
                                    : const Color(0xFFDD6B20),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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

// ─────────────────────────────────────────────────────────────────────────────
// Drawer tile — staggered slide + fade entry, ripple on tap
// ─────────────────────────────────────────────────────────────────────────────

class _DrawerTile extends StatelessWidget {
  final _TileData item;
  final int index;
  final AnimationController ctrl;
  final double w;
  final double h;
  final VoidCallback onTap;

  const _DrawerTile({
    required this.item,
    required this.index,
    required this.ctrl,
    required this.w,
    required this.h,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final start = (0.3 + index * 0.07).clamp(0.0, 1.0);
    final end = (start + 0.3).clamp(0.0, 1.0);

    final fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: ctrl,
        curve: Interval(start, end, curve: Curves.easeOut),
      ),
    );

    final slideAnim = Tween<Offset>(
      begin: const Offset(-0.15, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: ctrl,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
      ),
    );

    return SlideTransition(
      position: slideAnim,
      child: FadeTransition(
        opacity: fadeAnim,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            splashColor: item.color.withValues(alpha: 0.08),
            highlightColor: item.color.withValues(alpha: 0.04),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: w * 0.048,
                vertical: h * 0.014,
              ),
              child: Row(
                children: [
                  // Icon box
                  Container(
                    padding: EdgeInsets.all(w * 0.022),
                    decoration: BoxDecoration(
                      color: item.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(w * 0.025),
                    ),
                    child: Icon(
                      item.icon,
                      size: (w * 0.052).clamp(18.0, 24.0),
                      color: item.color,
                    ),
                  ),
                  SizedBox(width: w * 0.038),
                  // Label
                  Expanded(
                    child: Text(
                      item.label,
                      style: TextStyle(
                        fontFamily: 'Mukta',
                        fontSize: (w * 0.038).clamp(13.0, 16.0),
                        fontWeight: FontWeight.w500,
                        color: item.isDestructive
                            ? item.color
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  // Arrow — hidden for destructive items
                  if (!item.isDestructive)
                    Icon(
                      HugeIcons.strokeRoundedArrowRight01,
                      size: (w * 0.04).clamp(14.0, 18.0),
                      color: AppColors.textHint,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
