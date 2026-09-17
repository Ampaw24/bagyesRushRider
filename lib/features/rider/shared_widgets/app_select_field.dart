import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:delivery_boy/constant/app_theme.dart';
import 'package:hugeicons/hugeicons.dart';

/// A modern select field styled to match [AppTextField] — external label
/// above a filled rounded box — instead of Material's default
/// `DropdownButtonFormField`, whose `labelText` floats and sits on the
/// border line.
///
/// Tapping opens an animated bottom-sheet picker rather than the plain
/// overlay menu a stock dropdown shows.
class AppSelectField<T> extends StatelessWidget {
  final String label;
  final String? hint;
  final String? sheetTitle;
  final IconData? prefixIcon;
  final T? value;
  final List<T> options;
  final String Function(T option) labelBuilder;
  final ValueChanged<T?> onChanged;
  final String? Function(T? value)? validator;
  final bool enabled;
  final String? disabledHint;

  const AppSelectField({
    super.key,
    required this.label,
    required this.options,
    required this.labelBuilder,
    required this.onChanged,
    this.hint,
    this.sheetTitle,
    this.prefixIcon,
    this.value,
    this.validator,
    this.enabled = true,
    this.disabledHint,
  });

  Future<void> _openPicker(
    BuildContext context,
    FormFieldState<T> state,
  ) async {
    if (!enabled || options.isEmpty) return;
    HapticFeedback.selectionClick();
    final selected = await showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SelectSheet<T>(
        title: sheetTitle ?? label,
        options: options,
        labelBuilder: labelBuilder,
        selected: state.value,
      ),
    );
    if (selected != null) {
      state.didChange(selected);
      onChanged(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Mukta',
            fontSize: (w * 0.033).clamp(11.0, 14.0),
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            letterSpacing: 0.1,
          ),
        ),
        SizedBox(height: w * 0.014),
        FormField<T>(
          initialValue: value,
          validator: validator,
          builder: (state) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SelectTile<T>(
                  value: state.value,
                  hint: enabled ? hint : (disabledHint ?? hint),
                  prefixIcon: prefixIcon,
                  labelBuilder: labelBuilder,
                  hasError: state.hasError,
                  enabled: enabled,
                  onTap: () => _openPicker(context, state),
                ),
                if (state.hasError)
                  Padding(
                    padding: EdgeInsets.only(top: w * 0.015, left: w * 0.01),
                    child: Text(
                      state.errorText!,
                      style: TextStyle(
                        fontFamily: 'Mukta',
                        fontSize: (w * 0.03).clamp(10.5, 12.5),
                        color: AppColors.error,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

// ── Closed-state tile with an animated chevron ───────────────────────────────

class _SelectTile<T> extends StatefulWidget {
  final T? value;
  final String? hint;
  final IconData? prefixIcon;
  final String Function(T) labelBuilder;
  final bool hasError;
  final bool enabled;
  final VoidCallback onTap;

  const _SelectTile({
    required this.value,
    required this.hint,
    required this.prefixIcon,
    required this.labelBuilder,
    required this.hasError,
    required this.onTap,
    this.enabled = true,
  });

  @override
  State<_SelectTile<T>> createState() => _SelectTileState<T>();
}

class _SelectTileState<T> extends State<_SelectTile<T>> {
  bool _open = false;

  Future<void> _handleTap() async {
    if (!widget.enabled) return;
    setState(() => _open = true);
    widget.onTap();
    // The sheet is modal, so onTap's awaited push blocks until it closes —
    // by the time control returns here the sheet is already gone.
    if (mounted) setState(() => _open = false);
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final hasValue = widget.value != null;
    final borderColor = widget.hasError
        ? AppColors.error
        : (_open ? AppColors.primary : AppColors.border);
    final iconColor = widget.enabled ? Colors.grey.shade400 : Colors.grey.shade300;

    return InkWell(
      borderRadius: BorderRadius.circular(w * 0.032),
      onTap: widget.enabled ? _handleTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.symmetric(
          horizontal: w * 0.036,
          vertical: w * 0.032,
        ),
        decoration: BoxDecoration(
          color: widget.enabled ? const Color(0xFFF8F9FB) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(w * 0.032),
          border: Border.all(
            color: widget.enabled ? borderColor : AppColors.border,
            width: _open || widget.hasError ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            if (widget.prefixIcon != null) ...[
              Icon(widget.prefixIcon, size: 20, color: iconColor),
              SizedBox(width: w * 0.026),
            ],
            Expanded(
              child: Text(
                hasValue ? widget.labelBuilder(widget.value as T) : (widget.hint ?? ''),
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Mukta',
                  fontSize: (w * 0.038).clamp(13.0, 16.0),
                  fontWeight: FontWeight.w500,
                  color: hasValue ? AppColors.textPrimary : AppColors.textHint,
                ),
              ),
            ),
            AnimatedRotation(
              turns: _open ? 0.5 : 0,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              child: Icon(
                HugeIcons.strokeRoundedArrowDown01,
                size: 20,
                color: _open ? AppColors.primary : iconColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Bottom-sheet picker ───────────────────────────────────────────────────────

class _SelectSheet<T> extends StatelessWidget {
  final String title;
  final List<T> options;
  final String Function(T) labelBuilder;
  final T? selected;

  const _SelectSheet({
    required this.title,
    required this.options,
    required this.labelBuilder,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final w = mq.size.width;
    final maxHeight = mq.size.height * 0.65;

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(w * 0.06),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: mq.size.height * 0.014),
              Container(
                width: w * 0.11,
                height: mq.size.height * 0.005,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  w * 0.06,
                  mq.size.height * 0.02,
                  w * 0.06,
                  mq.size.height * 0.012,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Mukta',
                      fontSize: (w * 0.05).clamp(17.0, 21.0),
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.symmetric(
                    horizontal: w * 0.04,
                    vertical: mq.size.height * 0.008,
                  ),
                  itemCount: options.length,
                  separatorBuilder: (_, __) =>
                      SizedBox(height: mq.size.height * 0.004),
                  itemBuilder: (context, index) {
                    final option = options[index];
                    final isSelected = option == selected;
                    return _SelectOptionTile(
                      label: labelBuilder(option),
                      isSelected: isSelected,
                      onTap: () => Navigator.of(context).pop(option),
                    );
                  },
                ),
              ),
              SizedBox(height: mq.size.height * 0.012),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectOptionTile extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SelectOptionTile({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;

    return InkWell(
      borderRadius: BorderRadius.circular(w * 0.03),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: EdgeInsets.symmetric(
          horizontal: w * 0.04,
          vertical: w * 0.032,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(w * 0.03),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'Mukta',
                  fontSize: (w * 0.04).clamp(14.0, 16.0),
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
            ),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 160),
              opacity: isSelected ? 1 : 0,
              child: const Icon(
                HugeIcons.strokeRoundedCheckmarkCircle01,
                size: 20,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
