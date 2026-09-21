import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:delivery_boy/constant/app_theme.dart';
import 'package:delivery_boy/features/rider/chat/providers/rider_chat_list_providers.dart';
import 'package:delivery_boy/features/rider/chat/providers/rider_chat_thread_args.dart';
import 'package:delivery_boy/features/rider/chat/views/widgets/rider_chat_thread_sheet.dart';
import 'package:delivery_boy/features/rider/chat/views/widgets/rider_conversation_tile.dart';

/// The chat inbox — `GET /conversations`, filtered to threads whose order is
/// still in progress. Not a permanent archive: once an order is
/// delivered/cancelled its thread drops out of this list (see
/// `RiderChatListNotifier`).
class RiderChatListScreen extends ConsumerStatefulWidget {
  const RiderChatListScreen({super.key});

  @override
  ConsumerState<RiderChatListScreen> createState() => _RiderChatListScreenState();
}

class _RiderChatListScreenState extends ConsumerState<RiderChatListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(riderChatListProvider.notifier).load();
    });
  }

  Future<void> _openThread(RiderChatThreadArgs args) async {
    await RiderChatThreadSheet.show(context, args: args);
    // A reply sent from the thread changes this row's last-message/unread
    // state — reload the instant the sheet closes rather than waiting for a
    // manual pull-to-refresh.
    if (mounted) ref.read(riderChatListProvider.notifier).load();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final state = ref.watch(riderChatListProvider);
    final notifier = ref.read(riderChatListProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        title: const Text('Order Chats'),
        backgroundColor: AppColors.scaffold,
        elevation: 0,
      ),
      body: SafeArea(
        top: false,
        child: switch (state.status) {
          RiderChatListStatus.initial ||
          RiderChatListStatus.loading =>
            const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          RiderChatListStatus.error => _ErrorState(
              w: w,
              message: state.errorMessage ?? 'Something went wrong.',
              onRetry: notifier.load,
            ),
          RiderChatListStatus.loaded => state.conversations.isEmpty
              ? _EmptyState(w: w)
              : RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: notifier.load,
                  child: ListView.separated(
                    padding: EdgeInsets.fromLTRB(w * 0.05, w * 0.03, w * 0.05, w * 0.06),
                    itemCount: state.conversations.length,
                    separatorBuilder: (_, __) => SizedBox(height: w * 0.03),
                    itemBuilder: (context, index) {
                      final conversation = state.conversations[index];
                      return RiderConversationTile(
                        conversation: conversation,
                        onTap: () => _openThread(RiderChatThreadArgs(
                          conversationId: conversation.id,
                          peerName: conversation.counterpart?.name,
                        )),
                      );
                    },
                  ),
                ),
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.w});
  final double w;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: w * 0.1),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedBubbleChat,
              size: w * 0.16,
              color: AppColors.textHint,
            ),
            SizedBox(height: w * 0.04),
            Text(
              'No active order chats',
              style: TextStyle(
                fontSize: w * 0.044,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: w * 0.015),
            Text(
              "Chats with your customer show up here while you're on a delivery, and clear once it's complete.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: w * 0.033, color: AppColors.textSecondary, height: 1.4),
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
  final Future<void> Function() onRetry;

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
              "Couldn't load your messages",
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
