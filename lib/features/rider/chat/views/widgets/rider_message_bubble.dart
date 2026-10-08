import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:delivery_boy/constant/app_theme.dart';
import 'package:delivery_boy/features/rider/chat/models/rider_chat_message_model.dart';
import 'package:delivery_boy/features/rider/chat/views/widgets/rider_chat_avatar.dart';

String _formatTime(DateTime dt) {
  final local = dt.toLocal();
  final hour24 = local.hour;
  final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  final period = hour24 < 12 ? 'AM' : 'PM';
  return '$hour12:$minute $period';
}

/// A single chat bubble — right-aligned brand red for
/// [RiderChatMessageModel.isMine], left-aligned white otherwise.
///
/// Consecutive messages from one sender form a group: only the last in a
/// group gets the "tail" corner and the timestamp/ticks, and bubbles inside
/// a group sit closer together — the grouping modern messengers use to keep
/// a burst of short messages readable.
class RiderMessageBubble extends StatelessWidget {
  const RiderMessageBubble({
    super.key,
    required this.message,
    required this.peerName,
    this.peerPhotoUrl,
    this.isRead = false,
    this.onRetry,
    this.isFirstInGroup = true,
    this.isLastInGroup = true,
    this.animateIn = false,
  });

  final RiderChatMessageModel message;

  /// The other participant, shown as an avatar beside their last bubble in
  /// a group.
  final String peerName;
  final String? peerPhotoUrl;

  /// True once the peer's `conversation.read` timestamp is at/after this
  /// (own) message's `createdAt` — swaps the single tick for a double tick.
  final bool isRead;
  final VoidCallback? onRetry;
  final bool isFirstInGroup;
  final bool isLastInGroup;

  /// Fade/slide the bubble in — only for a message that just arrived.
  final bool animateIn;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final isMine = message.isMine;
    final failed = message.deliveryStatus == MessageDeliveryStatus.failed;
    final showMeta = isLastInGroup || failed;

    const big = Radius.circular(18);
    const small = Radius.circular(6);
    final radius = BorderRadius.only(
      topLeft: !isMine && !isFirstInGroup ? small : big,
      topRight: isMine && !isFirstInGroup ? small : big,
      bottomLeft: !isMine && !isLastInGroup ? small : (isMine ? big : small),
      bottomRight: isMine && !isLastInGroup ? small : (isMine ? small : big),
    );

    final foreground = isMine ? Colors.white : AppColors.textPrimary;
    final metaColor =
        isMine ? Colors.white.withValues(alpha: 0.8) : AppColors.textHint;

    Widget bubble = Container(
      constraints: BoxConstraints(maxWidth: w * 0.76),
      padding: EdgeInsets.fromLTRB(
        w * 0.035,
        w * 0.022,
        w * 0.035,
        showMeta ? w * 0.015 : w * 0.022,
      ),
      decoration: BoxDecoration(
        color: isMine
            ? AppColors.primary.withValues(alpha: failed ? 0.55 : 1)
            : Colors.white,
        borderRadius: radius,
        border: isMine ? null : Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            widthFactor: 1,
            child: Text(
              message.body,
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: (w * 0.038).clamp(14.0, 17.0),
                height: 1.35,
                color: foreground,
              ),
            ),
          ),
          if (showMeta) ...[
            SizedBox(height: w * 0.006),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(message.createdAt),
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: (w * 0.027).clamp(10.0, 12.0),
                    color: metaColor,
                  ),
                ),
                if (isMine && !failed) ...[
                  SizedBox(width: w * 0.01),
                  _DeliveryIcon(
                    status: message.deliveryStatus,
                    isRead: isRead,
                    color: metaColor,
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );

    if (failed && onRetry != null) {
      bubble = GestureDetector(onTap: onRetry, child: bubble);
    }

    final column = Column(
      crossAxisAlignment:
          isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        bubble,
        if (failed) _FailedNote(onRetry: onRetry),
      ],
    );

    Widget content = Padding(
      padding: EdgeInsets.only(top: isFirstInGroup ? w * 0.025 : w * 0.006),
      child: isMine ? column : _withPeerAvatar(w, column),
    );

    if (animateIn && !MediaQuery.of(context).disableAnimations) {
      content = TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        child: content,
        builder: (_, t, child) => Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * w * 0.03),
            child: child,
          ),
        ),
      );
    }

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: content,
    );
  }
}

extension on RiderMessageBubble {
  /// The avatar slot is always reserved so a group's bubbles line up; only
  /// the last bubble of the group fills it.
  Widget _withPeerAvatar(double w, Widget bubbleColumn) {
    final avatarSize = (w * 0.08).clamp(28.0, 36.0);
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        SizedBox.square(
          dimension: avatarSize,
          child: isLastInGroup
              ? RiderChatAvatar(
                  name: peerName,
                  photoUrl: peerPhotoUrl,
                  size: avatarSize,
                )
              : null,
        ),
        SizedBox(width: w * 0.02),
        Flexible(child: bubbleColumn),
      ],
    );
  }
}

class _FailedNote extends StatelessWidget {
  const _FailedNote({required this.onRetry});

  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return GestureDetector(
      onTap: onRetry,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.only(top: w * 0.012),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              HugeIcons.strokeRoundedAlertCircle,
              size: (w * 0.034).clamp(12.0, 15.0),
              color: AppColors.error,
            ),
            SizedBox(width: w * 0.01),
            Text(
              onRetry != null ? 'Not delivered · Tap to retry' : 'Not delivered',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: (w * 0.029).clamp(11.0, 13.0),
                fontWeight: FontWeight.w500,
                color: AppColors.error,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeliveryIcon extends StatelessWidget {
  const _DeliveryIcon({
    required this.status,
    required this.isRead,
    required this.color,
  });

  final MessageDeliveryStatus status;
  final bool isRead;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final size = (w * 0.035).clamp(12.0, 15.0);
    switch (status) {
      case MessageDeliveryStatus.sending:
        return Icon(HugeIcons.strokeRoundedClock01, size: size * 0.9, color: color);
      case MessageDeliveryStatus.sent:
        return Icon(
          isRead
              ? HugeIcons.strokeRoundedTickDouble02
              : HugeIcons.strokeRoundedTick02,
          size: size,
          color: isRead ? Colors.white : color,
        );
      case MessageDeliveryStatus.failed:
        return const SizedBox.shrink();
    }
  }
}
