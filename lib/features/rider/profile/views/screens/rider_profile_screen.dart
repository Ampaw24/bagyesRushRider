import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:delivery_boy/constant/app_theme.dart';
import 'package:delivery_boy/core/di/service_locator.dart';
import 'package:delivery_boy/core/router/app_routes.dart';
import 'package:delivery_boy/core/services/user_session_manager.dart';
import 'package:delivery_boy/features/rider/auth/models/rider_user_model.dart';
import 'package:delivery_boy/features/rider/auth/viewmodels/rider_auth_viewmodel.dart';
import 'package:delivery_boy/features/rider/dashboard/views/screens/rider_dashboard_screen.dart';
import 'package:delivery_boy/features/rider/profile/providers/rider_document_completion_providers.dart';
import 'package:delivery_boy/features/rider/profile/providers/rider_me_profile_providers.dart';
import 'package:hugeicons/hugeicons.dart';

class RiderProfileScreen extends ConsumerWidget {
  const RiderProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final w = MediaQuery.sizeOf(context).width;
    final navClearance = MediaQuery.paddingOf(context).bottom;

    final session = sl<UserSessionManager>();
    final profile = ref.watch(riderMeProfileProvider).profile;
    final kycStatus = ref.watch(riderKycStatusProvider);
    final docStatus = ref.watch(riderDocumentCompletionProvider).valueOrNull;

    final docCount = docStatus?.values.where((uploaded) => uploaded).length ?? 0;
    final docTotal = docStatus?.length ?? 0;
    final isComplete = docStatus != null && docCount == docTotal;

    final displayName = (session.displayName ?? '').trim();
    final name = displayName.isNotEmpty ? displayName : 'Rider';
    final initials = name
        .split(' ')
        .where((s) => s.isNotEmpty)
        .map((s) => s[0])
        .take(2)
        .join()
        .toUpperCase();

    void showLogoutDialog() {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Log Out',
            style: TextStyle(fontFamily: 'Mukta', fontWeight: FontWeight.w700),
          ),
          content: const Text(
            'Are you sure you want to log out?',
            style: TextStyle(fontFamily: 'Mukta'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(fontFamily: 'Mukta')),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await ref.read(riderAuthProvider.notifier).logout();
                if (!context.mounted) return;
                context.go(AppRoutes.login);
              },
              child: const Text(
                'Log Out',
                style: TextStyle(
                  fontFamily: 'Mukta',
                  color: AppColors.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: SafeArea(
        child: Column(
          children: [
            // ── Fixed header — stays put while the sections below scroll ──
            _Header(
              w: w,
              name: name,
              phone: session.phone ?? '',
              email: session.email,
              initials: initials,
              selfieUrl: profile?.photoUrl,
              kycStatus: kycStatus,
              docCount: docCount,
              docTotal: docTotal,
              isComplete: isComplete,
              onEdit: () => context.push(AppRoutes.editProfile),
              onTapDocuments: () => context.push(AppRoutes.documentUpload),
            ),

            // ── Scrollable sections ─────────────────────────────────────
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      w * 0.05,
                      w * 0.06,
                      w * 0.05,
                      navClearance + w * 0.1,
                    ),
                    child: Column(
                      children: [
                        _SectionCard(
                          label: 'Account',
                          w: w,
                          tiles: [
                            _ProfileTile(
                              icon: HugeIcons.strokeRoundedFileUpload,
                              label: 'Documents',
                              trailing: _CountBadge(
                                count: docCount,
                                total: docTotal,
                                isComplete: isComplete,
                              ),
                              onTap: () =>
                                  context.push(AppRoutes.documentUpload),
                              w: w,
                            ),
                            _ProfileTile(
                              icon: HugeIcons.strokeRoundedUserEdit01,
                              label: 'Edit Profile',
                              onTap: () =>
                                  context.push(AppRoutes.editProfile),
                              w: w,
                            ),
                            _ProfileTile(
                              icon: HugeIcons.strokeRoundedNotification01,
                              label: 'Notifications',
                              onTap: () =>
                                  context.push(AppRoutes.notifications),
                              w: w,
                            ),
                            _ProfileTile(
                              icon: HugeIcons.strokeRoundedSettings01,
                              label: 'Settings',
                              onTap: () => context.push(AppRoutes.settings),
                              w: w,
                            ),
                          ],
                        ),
                        SizedBox(height: w * 0.05),
                        _SectionCard(
                          label: 'Support',
                          w: w,
                          tiles: [
                            _ProfileTile(
                              icon: HugeIcons.strokeRoundedHeadphones,
                              label: 'Help & Support',
                              onTap: () {},
                              w: w,
                            ),
                          ],
                        ),
                        SizedBox(height: w * 0.07),
                        _LogoutButton(w: w, onTap: showLogoutDialog),
                      ],
                    ),
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

// ─── Header ─────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final double w;
  final String name;
  final String phone;
  final String? email;
  final String initials;
  final String? selfieUrl;
  final KycStatus? kycStatus;
  final int docCount;
  final int docTotal;
  final bool isComplete;
  final VoidCallback onEdit;
  final VoidCallback onTapDocuments;

  const _Header({
    required this.w,
    required this.name,
    required this.phone,
    this.email,
    required this.initials,
    this.selfieUrl,
    this.kycStatus,
    required this.docCount,
    required this.docTotal,
    required this.isComplete,
    required this.onEdit,
    required this.onTapDocuments,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(w * 0.05, w * 0.04, w * 0.05, w * 0.06),
      color: AppColors.scaffold,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Profile',
                style: TextStyle(
                  fontFamily: 'Mukta',
                  fontSize: w * 0.06,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              GestureDetector(
                onTap: onEdit,
                child: Container(
                  padding: EdgeInsets.all(w * 0.024),
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceVariant,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    HugeIcons.strokeRoundedPencilEdit02,
                    color: AppColors.textPrimary,
                    size: w * 0.045,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: w * 0.06),
          GestureDetector(
            onTap: onEdit,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: EdgeInsets.all(w * 0.01),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.18),
                      width: w * 0.008,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: w * 0.13,
                    backgroundColor: AppColors.primary,
                    backgroundImage:
                        (selfieUrl != null && selfieUrl!.isNotEmpty)
                            ? NetworkImage(selfieUrl!)
                            : null,
                    child: (selfieUrl != null && selfieUrl!.isNotEmpty)
                        ? null
                        : Text(
                            initials,
                            style: TextStyle(
                              fontFamily: 'Mukta',
                              color: Colors.white,
                              fontSize: w * 0.085,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: EdgeInsets.all(w * 0.015),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.scaffold, width: 2),
                    ),
                    child: Icon(
                      HugeIcons.strokeRoundedCamera01,
                      color: Colors.white,
                      size: w * 0.032,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: w * 0.035),
          Text(
            name,
            style: TextStyle(
              fontFamily: 'Mukta',
              fontSize: w * 0.05,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          if (phone.isNotEmpty || (email != null && email!.isNotEmpty)) ...[
            SizedBox(height: w * 0.006),
            Text(
              phone.isNotEmpty ? phone : email!,
              style: TextStyle(
                fontFamily: 'Mukta',
                fontSize: w * 0.033,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          SizedBox(height: w * 0.03),
          _KycBadge(status: kycStatus),
          if (!isComplete) ...[
            SizedBox(height: w * 0.05),
            _CompletionBar(
              w: w,
              count: docCount,
              total: docTotal,
              onTap: onTapDocuments,
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Completion progress ────────────────────────────────────────────────────

class _CompletionBar extends StatelessWidget {
  final double w;
  final int count;
  final int total;
  final VoidCallback onTap;

  const _CompletionBar({
    required this.w,
    required this.count,
    required this.total,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : count / total;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(w * 0.04),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(w * 0.04),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(w * 0.04),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Complete your profile',
                    style: TextStyle(
                      fontFamily: 'Mukta',
                      fontSize: w * 0.034,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$count/$total',
                        style: TextStyle(
                          fontFamily: 'Mukta',
                          fontSize: w * 0.032,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      SizedBox(width: w * 0.01),
                      Icon(
                        HugeIcons.strokeRoundedArrowRight01,
                        size: w * 0.036,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: w * 0.025),
              ClipRRect(
                borderRadius: BorderRadius.circular(w * 0.02),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: w * 0.016,
                  backgroundColor: AppColors.border,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── KYC badge ──────────────────────────────────────────────────────────────

class _KycBadge extends StatelessWidget {
  final KycStatus? status;
  const _KycBadge({this.status});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final (label, color) = switch (status) {
      KycStatus.approved => ('Verified', AppColors.success),
      KycStatus.pendingReview => ('Under Review', AppColors.warning),
      KycStatus.rejected => ('Rejected', AppColors.error),
      _ => ('Not Verified', AppColors.textHint),
    };

    return Container(
      padding: EdgeInsets.symmetric(horizontal: w * 0.028, vertical: w * 0.014),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(w * 0.05),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: w * 0.018,
            height: w * 0.018,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(width: w * 0.017),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Mukta',
              fontSize: w * 0.03,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section card ───────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String? label;
  final double w;
  final List<Widget> tiles;

  const _SectionCard({this.label, required this.w, required this.tiles});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Padding(
            padding: EdgeInsets.only(bottom: w * 0.025, left: w * 0.01),
            child: Text(
              label!,
              style: TextStyle(
                fontFamily: 'Mukta',
                fontSize: w * 0.032,
                fontWeight: FontWeight.w700,
                color: AppColors.textHint,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: w * 0.03),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(w * 0.045),
            border: Border.all(color: AppColors.border, width: 0.7),
          ),
          child: Column(
            children: [
              for (int i = 0; i < tiles.length; i++) ...[
                tiles[i],
                if (i != tiles.length - 1)
                  const Divider(height: 1, color: AppColors.divider),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final double w;
  final Widget? trailing;

  const _ProfileTile({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.w,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(w * 0.03),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: w * 0.03),
          child: Row(
            children: [
              Container(
                width: w * 0.1,
                height: w * 0.1,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(w * 0.026),
                ),
                child: Icon(icon, color: AppColors.primary, size: w * 0.05),
              ),
              SizedBox(width: w * 0.035),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Mukta',
                    fontSize: w * 0.037,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (trailing != null) ...[
                trailing!,
                SizedBox(width: w * 0.02),
              ],
              Container(
                width: w * 0.07,
                height: w * 0.07,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.surfaceVariant,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  HugeIcons.strokeRoundedArrowRight01,
                  color: AppColors.textSecondary,
                  size: w * 0.038,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final int count;
  final int total;
  final bool isComplete;

  const _CountBadge({
    required this.count,
    required this.total,
    required this.isComplete,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: w * 0.02, vertical: w * 0.008),
      decoration: BoxDecoration(
        color: isComplete
            ? AppColors.success.withValues(alpha: 0.1)
            : AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(w * 0.05),
      ),
      child: Text(
        '$count/$total',
        style: TextStyle(
          fontFamily: 'Mukta',
          fontSize: w * 0.03,
          fontWeight: FontWeight.w600,
          color: isComplete ? AppColors.success : AppColors.warning,
        ),
      ),
    );
  }
}

// ─── Log out ────────────────────────────────────────────────────────────────

class _LogoutButton extends StatelessWidget {
  final double w;
  final VoidCallback onTap;

  const _LogoutButton({required this.w, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(w * 0.03),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: w * 0.03),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                HugeIcons.strokeRoundedLogout01,
                color: AppColors.error,
                size: w * 0.045,
              ),
              SizedBox(width: w * 0.02),
              Text(
                'Log Out',
                style: TextStyle(
                  fontFamily: 'Mukta',
                  fontSize: w * 0.038,
                  fontWeight: FontWeight.w700,
                  color: AppColors.error,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
