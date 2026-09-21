import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:delivery_boy/constant/app_theme.dart';
import 'package:delivery_boy/features/rider/chat/models/rider_chat_message_model.dart';

String _formatTime(DateTime dt) {
  final local = dt.toLocal();
  final hour24 = local.hour;
  final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  final period = hour24 < 12 ? 'AM' : 'PM';
  return '$hour12:$minute $period';
}

/// A single chat bubble — right-aligned/primary for
/// [RiderChatMessageModel.isMine], left-aligned/neutral otherwise. Own
/// messages carry a small delivery indicator (sending/sent/failed) instead
/// of a sender label.
class RiderMessageBubble extends StatelessWidget {
  const RiderMessageBubble({
    super.key,
    required this.message,
    this.isRead = false,
    this.onRetry,
  });

  final RiderChatMessageModel message;

  /// True once the peer's `conversation.read` timestamp is at/after this
  /// (own) message's `createdAt` — swaps the sent tick for a read tick.
  final bool isRead;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final isMine = message.isMine;
    final failed = message.deliveryStatus == MessageDeliveryStatus.failed;

    final bubble = Container(
      constraints: BoxConstraints(maxWidth: w * 0.74),
      padding: EdgeInsets.symmetric(horizontal: w * 0.035, vertical: w * 0.024),
      decoration: BoxDecoration(
        color: failed
            ? AppColors.error.withValues(alpha: 0.08)
            : isMine
                ? AppColors.primary
                : AppColors.surfaceVariant,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(w * 0.04),
          topRight: Radius.circular(w * 0.04),
          bottomLeft: Radius.circular(isMine ? w * 0.04 : w * 0.01),
          bottomRight: Radius.circular(isMine ? w * 0.01 : w * 0.04),
        ),
        border: failed ? Border.all(color: AppColors.error, width: 0.8) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message.body,
            style: TextStyle(
              fontSize: w * 0.037,
              height: 1.32,
              color: isMine && !failed ? Colors.white : AppColors.textPrimary,
            ),
          ),
          SizedBox(height: w * 0.012),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatTime(message.createdAt),
                style: TextStyle(
                  fontSize: w * 0.026,
                  color: isMine && !failed
                      ? Colors.white.withValues(alpha: 0.75)
                      : AppColors.textHint,
                ),
              ),
              if (isMine) ...[
                SizedBox(width: w * 0.012),
                _DeliveryIcon(status: message.deliveryStatus, isRead: isRead, w: w),
              ],
            ],
          ),
        ],
      ),
    );

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: w * 0.008),
        child: failed && onRetry != null
            ? GestureDetector(onTap: onRetry, child: bubble)
            : bubble,
      ),
    );
  }
}

class _DeliveryIcon extends StatelessWidget {
  const _DeliveryIcon({required this.status, required this.isRead, required this.w});

  final MessageDeliveryStatus status;
  final bool isRead;
  final double w;

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case MessageDeliveryStatus.sending:
        return SizedBox(
          width: w * 0.03,
          height: w * 0.03,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            color: Colors.white.withValues(alpha: 0.85),
          ),
        );
      case MessageDeliveryStatus.sent:
        return HugeIcon(
          icon: isRead
              ? HugeIcons.strokeRoundedTickDouble01
              : HugeIcons.strokeRoundedCheckmarkCircle01,
          size: w * 0.032,
          color: Colors.white.withValues(alpha: isRead ? 1 : 0.85),
        );
      case MessageDeliveryStatus.failed:
        return HugeIcon(
          icon: HugeIcons.strokeRoundedAlertCircle,
          size: w * 0.032,
          color: AppColors.error,
        );
    }
  }
}
