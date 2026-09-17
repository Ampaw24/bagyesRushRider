import 'package:flutter/material.dart';
import 'package:delivery_boy/constant/app_theme.dart';
import 'package:delivery_boy/core/widgets/app_gradient_button.dart';
import 'package:delivery_boy/core/widgets/drag_handle.dart';

/// One reusable free-text reason sheet for the order-lifecycle "reason"
/// fields — offer decline, release, unreachable (all nullable) and
/// stop-fail (required, min 5 chars) — instead of a copy-pasted dialog per
/// call site.
///
/// Show with `showModalBottomSheet(isScrollControlled: true, backgroundColor:
/// Colors.transparent, builder: (_) => ReasonInputSheet(...))`.
class ReasonInputSheet extends StatefulWidget {
  final String title;
  final String hint;
  final String submitLabel;
  final bool requireNonEmpty;

  /// Called with the trimmed reason (may be empty when [requireNonEmpty] is
  /// false). Return true on success to close the sheet.
  final Future<bool> Function(String reason) onSubmit;

  const ReasonInputSheet({
    super.key,
    required this.title,
    this.hint = 'Enter reason here...',
    required this.submitLabel,
    this.requireNonEmpty = false,
    required this.onSubmit,
  });

  @override
  State<ReasonInputSheet> createState() => _ReasonInputSheetState();
}

class _ReasonInputSheetState extends State<ReasonInputSheet> {
  String _reason = '';
  bool _submitting = false;
  String? _error;

  bool get _canSubmit =>
      !_submitting && (!widget.requireNonEmpty || _reason.trim().isNotEmpty);

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    final ok = await widget.onSubmit(_reason.trim());
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _submitting = false;
        _error = 'Could not submit — try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const DragHandle(),
            Text(
              widget.title,
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              onChanged: (v) => setState(() => _reason = v),
              maxLines: 3,
              enabled: !_submitting,
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle:
                    TextStyle(color: Colors.grey.shade400, fontFamily: 'Roboto'),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 12,
                  color: AppColors.error,
                ),
              ),
            ],
            const SizedBox(height: 16),
            AppGradientButton(
              label: widget.submitLabel,
              isLoading: _submitting,
              onPressed: _canSubmit ? _submit : null,
            ),
          ],
        ),
      ),
    );
  }
}
