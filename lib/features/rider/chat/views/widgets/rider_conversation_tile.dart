import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:delivery_boy/constant/app_theme.dart';
import 'package:delivery_boy/features/rider/chat/models/rider_conversation_model.dart';

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) return '?';
  final first = parts.first[0];
  final second = parts.length > 1 && parts.last.isNotEmpty ? parts.last[0] : '';
  return (first + second).toUpperCase();
}

String riderConversationRelativeTime(DateTime? dt) {
  if (dt == null) return '';
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return 'Now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m';
  if (diff.inHours < 24) return '${diff.inHours}h';
  return '${diff.inDays}d';
}

/// One row in the conversation inbox — counterpart avatar (initials), name,
/// order context, last-message time and an unread badge.
class RiderConversationTile extends StatelessWidget {
  const RiderConversationTile({
    super.key,
    required this.conversation,
    required this.onTap,
  });

  final RiderConversationModel conversation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final counterpart = conversation.counterpart;
    final name = counterpart?.name ?? 'Customer';
    final hasUnread = conversation.unreadCount > 0;
    final avatarSize = w * 0.13;

    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(w * 0.04),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(w * 0.04),
        child: Container(
          padding: EdgeInsets.all(w * 0.035),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(w * 0.04),
            border: Border.all(color: AppColors.border, width: 0.7),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: avatarSize,
                    height: avatarSize,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _initials(name),
                      style: TextStyle(
                        fontSize: avatarSize * 0.36,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  if (!conversation.isOpen)
                    Positioned(
                      right: -w * 0.005,
                      bottom: -w * 0.005,
                      child: Container(
                        padding: EdgeInsets.all(w * 0.006),
                        decoration: const BoxDecoration(
                          color: AppColors.card,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.lock_outline_rounded,
                          size: w * 0.03,
                          color: AppColors.textHint,
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(width: w * 0.032),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: TextStyle(
                              fontSize: w * 0.038,
                              fontWeight: hasUnread ? FontWeight.w800 : FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: w * 0.02),
                        Text(
                          riderConversationRelativeTime(conversation.lastMessageAt),
                          style: TextStyle(
                            fontSize: w * 0.028,
                            color: hasUnread ? AppColors.primary : AppColors.textHint,
                            fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: w * 0.008),
                    if (conversation.order != null)
                      Text(
                        conversation.order!.statusLabel,
                        style: TextStyle(fontSize: w * 0.031, color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    SizedBox(height: w * 0.014),
                    Row(
                      children: [
                        if (counterpart != null) ...[
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: w * 0.02,
                              vertical: w * 0.006,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(w * 0.02),
                            ),
                            child: Text(
                              counterpart.roleLabel,
                              style: TextStyle(
                                fontSize: w * 0.026,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          const Spacer(),
                        ] else
                          const Spacer(),
                        if (hasUnread)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: w * 0.021,
                              vertical: w * 0.004,
                            ),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            constraints: BoxConstraints(minWidth: w * 0.052),
                            child: Text(
                              conversation.unreadCount > 99
                                  ? '99+'
                                  : '${conversation.unreadCount}',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: w * 0.027,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          )
                        else
                          HugeIcon(
                            icon: HugeIcons.strokeRoundedArrowRight01,
                            color: AppColors.textHint,
                            size: w * 0.036,
                          ),
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
