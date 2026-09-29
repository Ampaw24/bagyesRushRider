import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    HapticFeedback.lightImpact();
    widget.onSend(text);
    _controller.clear();
    setState(() => _hasText = false);
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    if (!widget.enabled) return _ClosedNotice(w: w);

    final buttonSize = (w * 0.12).clamp(48.0, 54.0);

    return Container(
      padding: EdgeInsets.fromLTRB(w * 0.03, w * 0.02, w * 0.03, w * 0.02),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                constraints: BoxConstraints(minHeight: buttonSize),
                padding: EdgeInsets.symmetric(horizontal: w * 0.04),
                alignment: Alignment.centerLeft,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(buttonSize / 2),
                  border: Border.all(color: AppColors.border),
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
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: (w * 0.038).clamp(14.0, 17.0),
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Message',
                    hintStyle: const TextStyle(color: AppColors.textHint),
                    border: InputBorder.none,
                    counterText: '',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: w * 0.028),
                  ),
                ),
              ),
            ),
            SizedBox(width: w * 0.02),
            Semantics(
              button: true,
              enabled: _hasText,
              label: 'Send message',
              child: AnimatedScale(
                scale: _hasText ? 1 : 0.88,
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: buttonSize,
                  height: buttonSize,
                  decoration: BoxDecoration(
                    color: _hasText ? AppColors.primary : AppColors.border,
                    shape: BoxShape.circle,
                  ),
                  child: Material(
                    type: MaterialType.transparency,
                    shape: const CircleBorder(),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: _hasText ? _handleSend : null,
                      child: Icon(
                        HugeIcons.strokeRoundedSent,
                        color: Colors.white,
                        size: buttonSize * 0.42,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClosedNotice extends StatelessWidget {
  const _ClosedNotice({required this.w});

  final double w;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: w * 0.05, vertical: w * 0.04),
      decoration: const BoxDecoration(
        color: AppColors.surfaceVariant,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              HugeIcons.strokeRoundedSquareLock02,
              size: (w * 0.04).clamp(14.0, 17.0),
              color: AppColors.textSecondary,
            ),
            SizedBox(width: w * 0.02),
            Flexible(
              child: Text(
                'This conversation is closed.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: (w * 0.033).clamp(12.0, 15.0),
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
