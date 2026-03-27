import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:delivery_boy/constant/app_theme.dart';

class AppPasswordField extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final void Function(String)? onChanged;
  final String? Function(String?)? validator;
  final TextInputAction textInputAction;
  final FocusNode? focusNode;

  const AppPasswordField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.onChanged,
    this.validator,
    this.textInputAction = TextInputAction.next,
    this.focusNode,
  });

  @override
  State<AppPasswordField> createState() => _AppPasswordFieldState();
}

class _AppPasswordFieldState extends State<AppPasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── External label ──────────────────────────────────────
        Text(
          widget.label,
          style: TextStyle(
            fontFamily: 'Mukta',
            fontSize: (w * 0.033).clamp(11.0, 14.0),
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            letterSpacing: 0.1,
          ),
        ),
        SizedBox(height: h * 0.010),

        // ── Password input ──────────────────────────────────────
        TextFormField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          obscureText: _obscure,
          enableSuggestions: false,
          autocorrect: false,
          textInputAction: widget.textInputAction,
          onChanged: widget.onChanged,
          validator: widget.validator,
          style: TextStyle(
            fontFamily: 'Mukta',
            fontSize: (w * 0.038).clamp(13.0, 16.0),
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: widget.hint,
            prefixIcon: Icon(
              HugeIcons.strokeRoundedLock,
              size: 22,
              color: Colors.grey.shade400,
            ),
            suffixIcon: GestureDetector(
              onTap: () => setState(() => _obscure = !_obscure),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: w * 0.03),
                child: Icon(
                  _obscure
                      ? HugeIcons.strokeRoundedViewOff
                      : HugeIcons.strokeRoundedEye,
                  size: 22,
                  color: Colors.grey.shade400,
                ),
              ),
            ),
            hintStyle: TextStyle(
              fontFamily: 'Mukta',
              fontSize: (w * 0.036).clamp(12.0, 15.0),
              color: AppColors.textHint,
            ),
            filled: true,
            fillColor: const Color(0xFFF8F9FB),
            contentPadding: EdgeInsets.only(
              left: 0,
              right: w * 0.04,
              top: h * 0.022,
              bottom: h * 0.022,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.border, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.error, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.error, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
