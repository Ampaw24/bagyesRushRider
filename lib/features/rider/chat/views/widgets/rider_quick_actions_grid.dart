import 'package:flutter/material.dart';

import 'package:delivery_boy/constant/app_theme.dart';

/// Server-supplied `quick_replies` as one horizontally scrolling row of
/// compact chips. A single line keeps the message history visible above
/// it — the earlier two-column tile grid grew with every reply and, with
/// the keyboard open, left almost no room for the conversation.
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

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.fromLTRB(w * 0.04, w * 0.02, w * 0.04, w * 0.01),
      child: Row(
        children: [
          for (final reply in replies)
            Padding(
              padding: EdgeInsets.only(right: w * 0.02),
              child: _QuickReplyChip(
                label: reply,
                onTap: () => onSelected(reply),
              ),
            ),
        ],
      ),
    );
  }
}

class _QuickReplyChip extends StatelessWidget {
  const _QuickReplyChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final shape = StadiumBorder(
      side: BorderSide(color: AppColors.primary.withValues(alpha: 0.35)),
    );

    return ConstrainedBox(
      // Long replies ellipsize rather than stretching one chip past the
      // screen edge.
      constraints: BoxConstraints(maxWidth: w * 0.7),
      child: Material(
        color: Colors.white,
        shape: shape,
        child: InkWell(
          onTap: onTap,
          customBorder: shape,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: w * 0.035,
              vertical: w * 0.022,
            ),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: (w * 0.033).clamp(12.0, 15.0),
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
