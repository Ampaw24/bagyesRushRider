import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:delivery_boy/constant/app_theme.dart';
import 'package:delivery_boy/core/widgets/drag_handle.dart';
import 'package:delivery_boy/features/rider/chat/models/rider_chat_message_model.dart';
import 'package:delivery_boy/features/rider/chat/providers/rider_chat_thread_args.dart';
import 'package:delivery_boy/features/rider/chat/providers/rider_chat_thread_providers.dart';
import 'package:delivery_boy/features/rider/chat/views/widgets/rider_chat_composer.dart';
import 'package:delivery_boy/features/rider/chat/views/widgets/rider_chat_timeline.dart';
import 'package:delivery_boy/features/rider/chat/views/widgets/rider_message_bubble.dart';
import 'package:delivery_boy/features/rider/chat/views/widgets/rider_quick_actions_grid.dart';

/// Presents a conversation thread as a draggable bottom sheet over whatever
/// screen is already on-screen (the order detail sheet, the chat inbox, …)
/// instead of navigating to a new full page — the order context underneath
/// stays reachable by dragging the sheet down.
class RiderChatThreadSheet {
  RiderChatThreadSheet._();

  static Future<void> show(BuildContext context, {required RiderChatThreadArgs args}) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _RiderChatThreadSheetBody(args: args),
    );
  }
}

class _RiderChatThreadSheetBody extends ConsumerWidget {
  const _RiderChatThreadSheetBody({required this.args});

  final RiderChatThreadArgs args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final w = MediaQuery.sizeOf(context).width;
    final state = ref.watch(riderChatThreadProvider(args));
    final notifier = ref.read(riderChatThreadProvider(args).notifier);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.86,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              // Soft grey behind the thread so white peer bubbles read as
              // surfaces; header and composer stay white.
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.vertical(top: Radius.circular(w * 0.05)),
            ),
            child: Column(
              children: [
                ColoredBox(
                  color: Colors.white,
                  child: Column(
                    children: [
                      const DragHandle(),
                      _SheetHeader(w: w, args: args, state: state),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppColors.divider),
                Expanded(
                  child: switch (state.status) {
                    RiderChatThreadStatus.loading =>
                      const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                    RiderChatThreadStatus.error => _ErrorState(
                        w: w,
                        message: state.message ?? 'Something went wrong.',
                        onRetry: notifier.retryLoad,
                      ),
                    RiderChatThreadStatus.unavailable => _UnavailableState(
                        w: w,
                        message: state.message ?? 'Chat not available yet.',
                        onRetry: notifier.retryLoad,
                      ),
                    RiderChatThreadStatus.loaded => _MessageList(
                        w: w,
                        scrollController: scrollController,
                        messages: state.messages,
                        isLoadingOlder: state.isLoadingOlder,
                        peerReadAt: state.peerReadAt,
                        peerTyping: state.peerTyping,
                        onRetryMessage: notifier.retry,
                        onLoadOlder: notifier.loadOlderMessages,
                      ),
                  },
                ),
                if (state.status == RiderChatThreadStatus.loaded &&
                    state.conversation!.isOpen &&
                    state.conversation!.quickReplies.isNotEmpty)
                  ColoredBox(
                    color: AppColors.surfaceVariant,
                    child: RiderQuickActionsGrid(
                    replies: state.conversation!.quickReplies,
                    onSelected: notifier.sendMessage,
                    ),
                  ),
                RiderChatComposer(
                  enabled: state.status == RiderChatThreadStatus.loaded &&
                      state.conversation!.isOpen,
                  onSend: notifier.sendMessage,
                  onTyping: notifier.notifyTyping,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.w, required this.args, required this.state});

  final double w;
  final RiderChatThreadArgs args;
  final RiderChatThreadState state;

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    final letters = parts.take(2).map((p) => p[0].toUpperCase()).join();
    return letters.isEmpty ? '?' : letters;
  }

  @override
  Widget build(BuildContext context) {
    final conversation = state.conversation;
    final counterpart = conversation?.counterpart;
    final title = counterpart?.name ?? args.peerName ?? 'Chat';
    final order = conversation?.order;
    final peerTyping = state.peerTyping;
    final phone = args.peerPhone;
    final avatar = (w * 0.11).clamp(40.0, 48.0);

    return Padding(
      padding: EdgeInsets.fromLTRB(w * 0.045, 0, w * 0.03, w * 0.03),
      child: Row(
        children: [
          CircleAvatar(
            radius: avatar / 2,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            child: Text(
              _initials(title),
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: (w * 0.038).clamp(14.0, 17.0),
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
          SizedBox(width: w * 0.03),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: (w * 0.042).clamp(15.0, 18.0),
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: w * 0.006),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: peerTyping
                      ? Text(
                          'typing…',
                          key: const ValueKey('typing'),
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: (w * 0.031).clamp(12.0, 14.0),
                            fontWeight: FontWeight.w500,
                            color: AppColors.primary,
                          ),
                        )
                      : _HeaderMeta(
                          key: const ValueKey('meta'),
                          w: w,
                          role: counterpart?.roleLabel,
                          orderNumber: order?.orderNumber,
                        ),
                ),
              ],
            ),
          ),
          if (phone != null && phone.trim().isNotEmpty)
            _HeaderButton(
              icon: HugeIcons.strokeRoundedCall,
              tooltip: 'Call',
              color: AppColors.primary,
              onTap: () => _callPhone(phone),
            ),
          _HeaderButton(
            icon: HugeIcons.strokeRoundedCancel01,
            tooltip: 'Close',
            color: AppColors.textSecondary,
            onTap: () => Navigator.of(context).maybePop(),
          ),
        ],
      ),
    );
  }

  Future<void> _callPhone(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }
}

/// "Customer · [#ORD-123]" — the order number as a small chip so it reads
/// as context, not as part of the name.
class _HeaderMeta extends StatelessWidget {
  const _HeaderMeta({super.key, required this.w, this.role, this.orderNumber});

  final double w;
  final String? role;
  final String? orderNumber;

  @override
  Widget build(BuildContext context) {
    final fontSize = (w * 0.03).clamp(11.0, 13.0);
    return Wrap(
      spacing: w * 0.015,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (role != null && role!.isNotEmpty)
          Text(
            role!,
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: fontSize,
              color: AppColors.textSecondary,
            ),
          ),
        if (orderNumber != null && orderNumber!.isNotEmpty)
          Container(
            padding: EdgeInsets.symmetric(horizontal: w * 0.018, vertical: w * 0.004),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              orderNumber!,
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
      ],
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return Padding(
      padding: EdgeInsets.only(left: w * 0.015),
      child: IconButton.filledTonal(
        onPressed: onTap,
        tooltip: tooltip,
        style: IconButton.styleFrom(
          backgroundColor: AppColors.surfaceVariant,
          minimumSize: const Size.square(48),
        ),
        icon: Icon(icon, color: color, size: (w * 0.05).clamp(18.0, 22.0)),
      ),
    );
  }
}

/// Owns the scroll-position listener that triggers older-page pagination —
/// isolated into its own [State] so it attaches to [scrollController]
/// exactly once for the sheet's lifetime, regardless of how often the
/// parent rebuilds on provider changes. Disposal of [scrollController]
/// itself belongs to the enclosing [DraggableScrollableSheet], not here.
class _MessageList extends StatefulWidget {
  const _MessageList({
    required this.w,
    required this.scrollController,
    required this.messages,
    required this.isLoadingOlder,
    required this.peerReadAt,
    required this.peerTyping,
    required this.onRetryMessage,
    required this.onLoadOlder,
  });

  final double w;
  final ScrollController scrollController;
  final List<RiderChatMessageModel> messages;
  final bool isLoadingOlder;
  final DateTime? peerReadAt;
  final bool peerTyping;
  final ValueChanged<RiderChatMessageModel> onRetryMessage;
  final VoidCallback onLoadOlder;

  @override
  State<_MessageList> createState() => _MessageListState();
}

class _MessageListState extends State<_MessageList> {
  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    if (!widget.scrollController.hasClients) return;
    final position = widget.scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 240) {
      widget.onLoadOlder();
    }
  }

  /// Messages closer together than this, from the same sender and on the
  /// same day, are drawn as one group.
  static const _groupGap = Duration(minutes: 2);

  bool _sameGroup(RiderChatMessageModel a, RiderChatMessageModel b) =>
      a.isMine == b.isMine &&
      isSameDay(a.createdAt, b.createdAt) &&
      a.createdAt.difference(b.createdAt).abs() <= _groupGap;

  @override
  Widget build(BuildContext context) {
    final w = widget.w;
    if (widget.messages.isEmpty && !widget.peerTyping) {
      return _EmptyThread(w: w);
    }

    // The list is reversed (newest at the bottom, index 0), so for message i
    // the newer neighbour is i - 1 and the older one is i + 1.
    final descending = widget.messages.reversed.toList();
    final items = <Widget>[
      if (widget.peerTyping) const RiderTypingIndicator(key: ValueKey('typing')),
    ];
    final now = DateTime.now();

    for (var i = 0; i < descending.length; i++) {
      final message = descending[i];
      final newer = i > 0 ? descending[i - 1] : null;
      final older = i < descending.length - 1 ? descending[i + 1] : null;
      final peerReadAt = widget.peerReadAt;

      items.add(RiderMessageBubble(
        key: ValueKey(message.clientUuid ?? 'id-${message.id}'),
        message: message,
        isRead: message.isMine &&
            peerReadAt != null &&
            !message.createdAt.isAfter(peerReadAt),
        isFirstInGroup: older == null || !_sameGroup(message, older),
        isLastInGroup: newer == null || !_sameGroup(message, newer),
        // Only the newest bubble, and only if it just arrived — never on
        // history loads or when scrolling back through old pages.
        animateIn: i == 0 && now.difference(message.createdAt).inSeconds.abs() < 5,
        onRetry: message.deliveryStatus == MessageDeliveryStatus.failed
            ? () => widget.onRetryMessage(message)
            : null,
      ));

      if (older == null || !isSameDay(message.createdAt, older.createdAt)) {
        items.add(RiderChatDaySeparator(date: message.createdAt));
      }
    }

    if (widget.isLoadingOlder) {
      items.add(Padding(
        padding: EdgeInsets.symmetric(vertical: w * 0.03),
        child: const Center(
          child: SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
          ),
        ),
      ));
    }

    return ListView.builder(
      controller: widget.scrollController,
      reverse: true,
      padding: EdgeInsets.fromLTRB(w * 0.04, w * 0.02, w * 0.04, w * 0.03),
      itemCount: items.length,
      itemBuilder: (_, index) => items[index],
    );
  }
}

class _EmptyThread extends StatelessWidget {
  const _EmptyThread({required this.w});

  final double w;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: w * 0.12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: (w * 0.16).clamp(56.0, 72.0),
              height: (w * 0.16).clamp(56.0, 72.0),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                HugeIcons.strokeRoundedBubbleChat,
                size: (w * 0.07).clamp(24.0, 30.0),
                color: AppColors.primary,
              ),
            ),
            SizedBox(height: w * 0.04),
            Text(
              'No messages yet',
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: (w * 0.042).clamp(15.0, 18.0),
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: w * 0.015),
            Text(
              'Send a message or tap a quick reply to update the customer.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: (w * 0.033).clamp(12.0, 15.0),
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.w, required this.message, required this.onRetry});

  final double w;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: w * 0.1),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedAlertCircle,
              size: w * 0.14,
              color: AppColors.error,
            ),
            SizedBox(height: w * 0.04),
            Text(
              "Couldn't load this conversation",
              style: TextStyle(
                fontSize: w * 0.042,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: w * 0.015),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: w * 0.032, color: AppColors.textSecondary),
            ),
            SizedBox(height: w * 0.05),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

/// Shown instead of [_ErrorState] when the REST fetch behind this thread
/// returned a `ConversationUnavailableFailure` (422) or a 403 channel-auth
/// error — a state, not a broken thread. Unlike a real error this can
/// resolve itself while the sheet stays open, so the retry action reads as
/// "check again" rather than "retry".
class _UnavailableState extends StatelessWidget {
  const _UnavailableState({required this.w, required this.message, required this.onRetry});

  final double w;
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: w * 0.1),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedDeliveryBox01,
              size: w * 0.14,
              color: AppColors.textHint,
            ),
            SizedBox(height: w * 0.04),
            Text(
              'Chat not available yet',
              style: TextStyle(
                fontSize: w * 0.042,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: w * 0.015),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: w * 0.032, color: AppColors.textSecondary),
            ),
            SizedBox(height: w * 0.05),
            OutlinedButton(onPressed: onRetry, child: const Text('Check again')),
          ],
        ),
      ),
    );
  }
}
