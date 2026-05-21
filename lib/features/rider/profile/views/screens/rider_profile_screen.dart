import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:delivery_boy/constant/app_theme.dart';
import 'package:delivery_boy/core/router/app_routes.dart';
import 'package:delivery_boy/features/rider/auth/models/rider_user_model.dart';
import 'package:delivery_boy/features/rider/profile/providers/rider_profile_providers.dart';
import 'package:hugeicons/hugeicons.dart';

// iOS-style grouped background, used by Grab / DoorDash Dasher
const _kBg = Color(0xFFF2F2F7);

List<Color> _kycRingColors(KycStatus? status) {
  switch (status) {
    case KycStatus.approved:
      return [AppColors.success, Color(0xFF66BB6A), AppColors.success];
    case KycStatus.pendingReview:
      return [Colors.orange, Colors.amber, Colors.orange];
    case KycStatus.rejected:
      return [AppColors.error, Colors.redAccent, AppColors.error];
    default:
      return [Color(0xFFE0E0E0), Color(0xFFBDBDBD), Color(0xFFE0E0E0)];
  }
}

class RiderProfileScreen extends ConsumerWidget {
  const RiderProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(riderProfileProvider);
    final user = state.user;

    final docCount = [
      user?.selfie,
      user?.licenceFront,
      user?.licenceBack,
      user?.motorInsurance,
      user?.roadWorthy,
    ].where((v) => v != null && v.isNotEmpty).length;
    final completePct = docCount / 5.0;
    final isComplete = user?.isProfileComplete ?? false;

    void showLogoutDialog() {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Log Out',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          content: const Text('Are you sure you want to log out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await ref.read(riderProfileProvider.notifier).logout();
                if (!context.mounted) return;
                context.go(AppRoutes.login);
              },
              child: const Text(
                'Log Out',
                style: TextStyle(
                    color: AppColors.error, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      );
    }

    final bottomPad = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: _kBg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── App bar ──────────────────────────────────────────────────────
          SliverAppBar(
            automaticallyImplyLeading: false,
            backgroundColor: _kBg,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            pinned: true,
            title: const Text(
              'Profile',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),

          SliverPadding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, bottomPad + 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Identity card ───────────────────────────────────────
                _SectionCard(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                    child: Column(
                      children: [
                        // Avatar with KYC-status ring + online dot
                        GestureDetector(
                          onTap: () => context.push(AppRoutes.editProfile),
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              // Outer KYC status ring
                              Container(
                                width: 96,
                                height: 96,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: SweepGradient(
                                    colors: _kycRingColors(user?.kycStatus),
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(3),
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                    ),
                                    child: ClipOval(
                                      child: user?.selfie != null &&
                                              user!.selfie!.isNotEmpty
                                          ? Image.network(
                                              user.selfie!,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => Icon(
                                                  HugeIcons.strokeRoundedUser,
                                                  size: 42,
                                                  color: Colors.grey.shade400),
                                            )
                                          : Icon(HugeIcons.strokeRoundedUser,
                                              size: 42,
                                              color: Colors.grey.shade400),
                                    ),
                                  ),
                                ),
                              ),
                              // Online / offline dot
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: (user?.queue ?? false)
                                      ? AppColors.success
                                      : Colors.grey.shade400,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.white, width: 2.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Name
                        Text(
                          user?.name ?? 'Rider',
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Phone
                        Text(
                          user?.phone ?? '',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (user?.email != null &&
                            user!.email!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            user.email!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),
                        // KYC badge + edit button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _KycBadge(status: user?.kycStatus),
                            const SizedBox(width: 10),
                            GestureDetector(
                              onTap: () =>
                                  context.push(AppRoutes.editProfile),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _kBg,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'Edit Profile',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Info strip ──────────────────────────────────────────
                const SizedBox(height: 12),
                _InfoStrip(
                  docCount: docCount,
                  isOnline: user?.queue ?? false,
                  numberPlate: user?.numberPlate,
                ),

                // ── Completion nudge ────────────────────────────────────
                if (!isComplete) ...[
                  const SizedBox(height: 12),
                  _CompletionBanner(
                    docCount: docCount,
                    completePct: completePct,
                    onTap: () => context.push(AppRoutes.documentUpload),
                  ),
                ],

                // ── Account section ─────────────────────────────────────
                const SizedBox(height: 24),
                _SectionHeader(label: 'Account'),
                const SizedBox(height: 8),
                _SectionCard(
                  child: Column(
                    children: [
                      _Tile(
                        icon: HugeIcons.strokeRoundedEdit01,
                        color: AppColors.primary,
                        title: 'Edit Profile',
                        onTap: () => context.push(AppRoutes.editProfile),
                      ),
                      _Tile(
                        icon: HugeIcons.strokeRoundedFileUpload,
                        color: Colors.orange,
                        title: 'Documents',
                        trailing: _DocsBadge(isComplete: isComplete),
                        onTap: () => context.push(AppRoutes.documentUpload),
                      ),
                      _Tile(
                        icon: HugeIcons.strokeRoundedNotification01,
                        color: Colors.blue,
                        title: 'Notifications',
                        onTap: () =>
                            context.push(AppRoutes.notifications),
                      ),
                      _Tile(
                        icon: HugeIcons.strokeRoundedSettings01,
                        color: Colors.grey.shade600,
                        title: 'Settings',
                        onTap: () => context.push(AppRoutes.settings),
                        last: true,
                      ),
                    ],
                  ),
                ),

                // ── More section ────────────────────────────────────────
                const SizedBox(height: 24),
                _SectionHeader(label: 'More'),
                const SizedBox(height: 8),
                _SectionCard(
                  child: Column(
                    children: [
                      _Tile(
                        icon: HugeIcons.strokeRoundedHeadphones,
                        color: Colors.teal,
                        title: 'Support',
                        onTap: () {},
                      ),
                      _Tile(
                        icon: HugeIcons.strokeRoundedLogout01,
                        color: AppColors.error,
                        title: 'Log Out',
                        titleColor: AppColors.error,
                        onTap: showLogoutDialog,
                        last: true,
                      ),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared widgets ─────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 6),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _KycBadge extends StatelessWidget {
  final KycStatus? status;
  const _KycBadge({this.status});

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = switch (status) {
      KycStatus.approved => ('Verified', const Color(0xFFE6F4EA), AppColors.success),
      KycStatus.pendingReview => ('Under Review', const Color(0xFFFFF8E1), Colors.orange),
      KycStatus.rejected => ('Rejected', const Color(0xFFFFEBEE), AppColors.error),
      _ => ('Not Verified', const Color(0xFFF5F5F5), AppColors.textSecondary),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            status == KycStatus.approved
                ? HugeIcons.strokeRoundedCheckmarkCircle02
                : HugeIcons.strokeRoundedAlert02,
            size: 12,
            color: fg,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoStrip extends StatelessWidget {
  final int docCount;
  final bool isOnline;
  final String? numberPlate;

  const _InfoStrip({
    required this.docCount,
    required this.isOnline,
    this.numberPlate,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        children: [
          Expanded(
            child: _InfoTile(
              icon: HugeIcons.strokeRoundedFile01,
              value: '$docCount/5',
              label: 'Documents',
            ),
          ),
          const VerticalDivider(width: 1, color: Color(0xFFE5E5EA)),
          Expanded(
            child: _InfoTile(
              icon: HugeIcons.strokeRoundedCircle,
              value: isOnline ? 'Online' : 'Offline',
              label: 'Status',
              valueColor:
                  isOnline ? AppColors.success : AppColors.textSecondary,
            ),
          ),
          if (numberPlate != null && numberPlate!.isNotEmpty) ...[
            const VerticalDivider(width: 1, color: Color(0xFFE5E5EA)),
            Expanded(
              child: _InfoTile(
                icon: HugeIcons.strokeRoundedCar01,
                value: numberPlate!,
                label: 'Plate',
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color? valueColor;

  const _InfoTile({
    required this.icon,
    required this.value,
    required this.label,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompletionBanner extends StatelessWidget {
  final int docCount;
  final double completePct;
  final VoidCallback onTap;

  const _CompletionBanner({
    required this.docCount,
    required this.completePct,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.orange.shade100),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(HugeIcons.strokeRoundedAlert02,
                  size: 20, color: Colors.orange.shade700),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Complete your profile',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: completePct,
                      minHeight: 4,
                      backgroundColor: Colors.grey.shade100,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.orange.shade600),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$docCount of 5 documents uploaded',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(HugeIcons.strokeRoundedArrowRight01,
                size: 18, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}

class _DocsBadge extends StatelessWidget {
  final bool isComplete;
  const _DocsBadge({required this.isComplete});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isComplete
            ? const Color(0xFFE6F4EA)
            : Colors.orange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        isComplete ? 'Complete' : 'Pending',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isComplete ? AppColors.success : Colors.orange,
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final Color? titleColor;
  final Widget? trailing;
  final VoidCallback onTap;
  final bool last;

  const _Tile({
    required this.icon,
    required this.color,
    required this.title,
    required this.onTap,
    this.titleColor,
    this.trailing,
    this.last = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(icon, color: color, size: 19),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: titleColor ?? AppColors.textPrimary,
                    ),
                  ),
                ),
                trailing ??
                    Icon(
                      HugeIcons.strokeRoundedArrowRight01,
                      size: 18,
                      color: Colors.grey.shade400,
                    ),
              ],
            ),
          ),
        ),
        if (!last)
          Divider(height: 1, indent: 66, color: const Color(0xFFF2F2F7)),
      ],
    );
  }
}
