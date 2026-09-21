import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:delivery_boy/constant/app_theme.dart';

/// Prominent, large tappable quick-reply tiles — a two-column grid rather
/// than a scrollable pill row, matching the customer/vendor app's own chat
/// UI. Rendered straight from the conversation's server-supplied
/// `quick_replies`, never a local list.
class RiderQuickActionsGrid extends StatelessWidget {
  const RiderQuickActionsGrid({
    super.key,
    required this.replies,
    required this.onSelected,
  });

  final List<String> replies;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    if (replies.isEmpty) return const SizedBox.shrink();
    final w = MediaQuery.sizeOf(context).width;

    return Padding(
      padding: EdgeInsets.fromLTRB(w * 0.04, w * 0.02, w * 0.04, w * 0.015),
      child: Wrap(
        spacing: w * 0.025,
        runSpacing: w * 0.025,
        children: [
          for (final reply in replies)
            _QuickActionTile(
              width: (w - w * 0.08 - w * 0.025) / 2,
              label: reply,
              onTap: () => onSelected(reply),
            ),
        ],
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({
    required this.width,
    required this.label,
    required this.onTap,
  });

  final double width;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return SizedBox(
      width: width,
      child: Material(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(w * 0.035),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(w * 0.035),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: w * 0.03, vertical: w * 0.03),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(w * 0.035),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(w * 0.017),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedBubbleChat,
                    color: AppColors.primary,
                    size: w * 0.036,
                  ),
                ),
                SizedBox(width: w * 0.022),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: w * 0.031,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
