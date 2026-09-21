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
            decoration: BoxDecoration(
              color: AppColors.scaffold,
              borderRadius: BorderRadius.vertical(top: Radius.circular(w * 0.06)),
            ),
            child: Column(
              children: [
                const DragHandle(),
                _SheetHeader(w: w, args: args, state: state),
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
                        onRetryMessage: notifier.retry,
                        onLoadOlder: notifier.loadOlderMessages,
                      ),
                  },
                ),
                if (state.status == RiderChatThreadStatus.loaded &&
                    state.conversation!.isOpen &&
                    state.conversation!.quickReplies.isNotEmpty)
                  RiderQuickActionsGrid(
                    replies: state.conversation!.quickReplies,
                    onSelected: notifier.sendMessage,
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

  @override
  Widget build(BuildContext context) {
    final conversation = state.conversation;
    final counterpart = conversation?.counterpart;
    final title = counterpart?.name ?? args.peerName ?? 'Chat';
    final order = conversation?.order;
    final peerTyping = state.peerTyping;
    final subtitleParts = <String>[
      if (counterpart != null) counterpart.roleLabel,
      if (order != null) order.orderNumber,
    ];
    final subtitle = peerTyping ? 'typing…' : subtitleParts.join(' · ');
    final phone = args.peerPhone;

    return Padding(
      padding: EdgeInsets.fromLTRB(w * 0.045, w * 0.01, w * 0.03, w * 0.03),
      child: Row(
        children: [
          Container(
            width: w * 0.11,
            height: w * 0.11,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              title.isNotEmpty ? title[0].toUpperCase() : '?',
              style: TextStyle(
                fontSize: w * 0.042,
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
                    fontSize: w * 0.042,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: w * 0.029,
                      fontStyle: peerTyping ? FontStyle.italic : FontStyle.normal,
                      color: peerTyping ? AppColors.primary : AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          if (phone != null && phone.trim().isNotEmpty)
            IconButton(
              onPressed: () => _callPhone(phone),
              icon: HugeIcon(
                icon: HugeIcons.strokeRoundedCall,
                color: AppColors.primary,
                size: w * 0.052,
              ),
            ),
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: Icon(Icons.close_rounded, color: AppColors.textHint, size: w * 0.06),
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
    required this.onRetryMessage,
    required this.onLoadOlder,
  });

  final double w;
  final ScrollController scrollController;
  final List<RiderChatMessageModel> messages;
  final bool isLoadingOlder;
  final DateTime? peerReadAt;
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

  @override
  Widget build(BuildContext context) {
    final w = widget.w;
    if (widget.messages.isEmpty) {
      return Center(
        child: Text(
          'Say hello 👋',
          style: TextStyle(fontSize: w * 0.036, color: AppColors.textHint),
        ),
      );
    }

    final descending = widget.messages.reversed.toList();
    final itemCount = descending.length + (widget.isLoadingOlder ? 1 : 0);

    return ListView.builder(
      controller: widget.scrollController,
      reverse: true,
      padding: EdgeInsets.symmetric(horizontal: w * 0.04, vertical: w * 0.03),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (index >= descending.length) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: w * 0.03),
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
              ),
            ),
          );
        }
        final message = descending[index];
        final peerReadAt = widget.peerReadAt;
        final isRead = message.isMine &&
            peerReadAt != null &&
            !message.createdAt.isAfter(peerReadAt);
        return RiderMessageBubble(
          message: message,
          isRead: isRead,
          onRetry: message.deliveryStatus == MessageDeliveryStatus.failed
              ? () => widget.onRetryMessage(message)
              : null,
        );
      },
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
