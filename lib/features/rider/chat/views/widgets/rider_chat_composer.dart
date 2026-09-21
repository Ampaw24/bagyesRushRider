import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:delivery_boy/constant/app_theme.dart';

/// The message input bar — owns its own [TextEditingController] so the
/// parent view only needs [onSend] (called with the trimmed body, already
/// cleared from the field) and [onTyping] (fired on every keystroke, for the
/// throttled `typing` signal). Enforces the API's 2000-char cap directly on
/// the field so a send never round-trips a 422 for length.
class RiderChatComposer extends StatefulWidget {
  const RiderChatComposer({
    super.key,
    required this.onSend,
    required this.onTyping,
    this.enabled = true,
  });

  final ValueChanged<String> onSend;
  final VoidCallback onTyping;
  final bool enabled;

  @override
  State<RiderChatComposer> createState() => _RiderChatComposerState();
}

class _RiderChatComposerState extends State<RiderChatComposer> {
  final _controller = TextEditingController();
  bool _hasText = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSend(text);
    _controller.clear();
    setState(() => _hasText = false);
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    if (!widget.enabled) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: w * 0.05, vertical: w * 0.04),
        decoration: const BoxDecoration(
          color: AppColors.surfaceVariant,
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: Text(
          'This conversation is closed.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: w * 0.033, color: AppColors.textSecondary),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.fromLTRB(w * 0.03, w * 0.025, w * 0.03, w * 0.025),
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                constraints: BoxConstraints(maxHeight: w * 0.32),
                padding: EdgeInsets.symmetric(horizontal: w * 0.04),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(w * 0.06),
                ),
                child: TextField(
                  controller: _controller,
                  minLines: 1,
                  maxLines: 5,
                  maxLength: 2000,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (value) {
                    widget.onTyping();
                    final hasText = value.trim().isNotEmpty;
                    if (hasText != _hasText) setState(() => _hasText = hasText);
                  },
                  style: TextStyle(fontSize: w * 0.037, color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    hintText: 'Type a message…',
                    hintStyle: TextStyle(color: AppColors.textHint),
                    border: InputBorder.none,
                    counterText: '',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
            SizedBox(width: w * 0.025),
            GestureDetector(
              onTap: _hasText ? _handleSend : null,
              child: Container(
                width: w * 0.105,
                height: w * 0.105,
                decoration: BoxDecoration(
                  color: _hasText ? AppColors.primary : AppColors.border,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedArrowUp01,
                  color: Colors.white,
                  size: w * 0.05,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
