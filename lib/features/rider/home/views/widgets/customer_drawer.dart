import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:delivery_boy/constant/app_theme.dart';
import 'package:delivery_boy/core/di/service_locator.dart';
import 'package:delivery_boy/core/router/app_routes.dart';
import 'package:delivery_boy/core/services/user_session_manager.dart';
import 'package:delivery_boy/core/utils/legal_links.dart';
import 'package:delivery_boy/features/rider/shared_widgets/rider_avatar.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data model
// ─────────────────────────────────────────────────────────────────────────────

class _TileData {
  final IconData icon;
  final String label;

  /// Set only for the destructive actions (warning / error). Every other
  /// item takes the brand colour — the same scheme as the customer and
  /// vendor drawers.
  final Color? color;
  final int badgeCount;

  const _TileData({
    required this.icon,
    required this.label,
    this.color,
    this.badgeCount = 0,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// CustomerDrawer — Stack-overlay animated side drawer
// ─────────────────────────────────────────────────────────────────────────────

class CustomerDrawer extends StatefulWidget {
  final VoidCallback onClose;
  final VoidCallback onOrders;
  final VoidCallback onWallet;
  final VoidCallback onProfile;
  final VoidCallback onLogout;
  final VoidCallback onDeleteAccount;

  /// Supplied by the parent, which already watches the rider profile —
  /// verification state lives on `GET /rider/me`, not in the session.
  final bool isVerified;

  /// From `riderAvatarUrlProvider`; initials are shown when null.
  final String? photoUrl;

  /// Unread notifications, badged on the Notifications item.
  final int notificationBadgeCount;

  const CustomerDrawer({
    super.key,
    required this.onClose,
    required this.onOrders,
    required this.onWallet,
    required this.onProfile,
    required this.onLogout,
    required this.onDeleteAccount,
    this.isVerified = false,
    this.photoUrl,
    this.notificationBadgeCount = 0,
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
        _close().then((_) => widget.onProfile());
      case 'My Orders':
        _close().then((_) => widget.onOrders());
      case 'Notifications':
        _close().then((_) { if (mounted) context.push(AppRoutes.notifications); });
      case 'Wallet':
        _close().then((_) => widget.onWallet());
      case 'Transactions':
        _close().then((_) { if (mounted) context.push(AppRoutes.walletTransactions); });
      case 'Privacy Policy':
        _openLegal(LegalDocument.privacyPolicy);
      case 'Rider Agreement':
        _openLegal(LegalDocument.riderAgreement);
      case 'Terms & Conditions':
        _openLegal(LegalDocument.termsConditions);
      case 'Delete Account':
        _close().then((_) => widget.onDeleteAccount());
      case 'Logout':
        _close().then((_) => widget.onLogout());
      default:
        _close();
    }
  }

  /// Opens the page before closing the drawer: the in-app browser sits on
  /// top of the app, and the drawer's context must still be mounted to show
  /// an error if the page can't be opened.
  Future<void> _openLegal(LegalDocument doc) async {
    await LegalLinks.open(context, doc);
    await _close();
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
      const _TileData(icon: HugeIcons.strokeRoundedUser, label: 'My Profile'),
      const _TileData(
          icon: HugeIcons.strokeRoundedDeliveryBox01, label: 'My Orders'),
      _TileData(
        icon: HugeIcons.strokeRoundedNotification01,
        label: 'Notifications',
        badgeCount: widget.notificationBadgeCount,
      ),
      const _TileData(icon: HugeIcons.strokeRoundedWallet01, label: 'Wallet'),
      const _TileData(
          icon: HugeIcons.strokeRoundedTransactionHistory,
          label: 'Transactions'),
      const _TileData(
          icon: HugeIcons.strokeRoundedShieldKey, label: 'Privacy Policy'),
      const _TileData(
          icon: HugeIcons.strokeRoundedAgreement01, label: 'Rider Agreement'),
      const _TileData(
          icon: HugeIcons.strokeRoundedLegalDocument01,
          label: 'Terms & Conditions'),
      const _TileData(
          icon: HugeIcons.strokeRoundedHelpCircle, label: 'Help & Support'),
    ];

    const bottomItems = <_TileData>[
      _TileData(
        icon: HugeIcons.strokeRoundedDelete02,
        label: 'Delete Account',
        color: AppColors.warning,
      ),
      _TileData(
        icon: HugeIcons.strokeRoundedLogout01,
        label: 'Logout',
        color: AppColors.error,
      ),
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
              // Inset like the customer/vendor drawer's SafeArea + margin.
              // Inside the dashboard, viewPadding.bottom already includes
              // the floating nav bar, so the panel ends just above it.
              Positioned(
                left: 0,
                top: viewPadding.top + h * 0.02,
                bottom: viewPadding.bottom + h * 0.02,
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
                            photoUrl: widget.photoUrl,
                            isVerified: isVerified,
                            onClose: _close,
                            w: w,
                            h: h,
                          ),

                          Padding(
                            padding:
                                EdgeInsets.symmetric(horizontal: w * 0.05),
                            child: const Divider(
                              color: AppColors.divider,
                              height: 1,
                            ),
                          ),

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

                          Padding(
                            padding:
                                EdgeInsets.symmetric(horizontal: w * 0.05),
                            child: const Divider(
                              color: AppColors.divider,
                              height: 1,
                            ),
                          ),

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
  final String? photoUrl;
  final bool isVerified;
  final VoidCallback onClose;
  final double w;
  final double h;

  const _DrawerHeader({
    required this.ctrl,
    required this.name,
    required this.email,
    required this.initials,
    this.photoUrl,
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
                  HugeIcons.strokeRoundedCancel01,
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
                child: RiderAvatar(
                  radius: w * 0.07,
                  imageUrl: photoUrl,
                  placeholder: Text(
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
                      // Name, with the verified tick
                      Row(
                        children: [
                          Flexible(
                            child: Text(
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
                          ),
                          if (isVerified) ...[
                            SizedBox(width: w * 0.012),
                            Icon(
                              HugeIcons.strokeRoundedCheckmarkBadge01,
                              size: (w * 0.045).clamp(16.0, 20.0),
                              color: AppColors.info,
                              semanticLabel: 'Verified',
                            ),
                          ],
                        ],
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

    final iconColor = item.color ?? AppColors.primary;
    final labelColor = item.color ?? AppColors.textPrimary;

    return SlideTransition(
      position: slideAnim,
      child: FadeTransition(
        opacity: fadeAnim,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            splashColor: iconColor.withValues(alpha: 0.08),
            highlightColor: iconColor.withValues(alpha: 0.04),
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
                      color: iconColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(w * 0.025),
                    ),
                    child: Icon(
                      item.icon,
                      size: (w * 0.052).clamp(18.0, 24.0),
                      color: iconColor,
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
                        color: labelColor,
                      ),
                    ),
                  ),
                  if (item.badgeCount > 0) ...[
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: w * 0.02,
                        vertical: w * 0.004,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(w * 0.03),
                      ),
                      child: Text(
                        '${item.badgeCount}',
                        semanticsLabel: '${item.badgeCount} unread',
                        style: TextStyle(
                          fontFamily: 'Mukta',
                          fontSize: (w * 0.028).clamp(10.0, 12.0),
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(width: w * 0.02),
                  ],
                  // Arrow — hidden for the destructive actions
                  if (item.color == null)
                    Icon(
                      HugeIcons.strokeRoundedArrowRight01,
                      size: (w * 0.04).clamp(14.0, 18.0),
                      color: AppColors.primary,
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
