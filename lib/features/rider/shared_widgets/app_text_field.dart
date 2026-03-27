import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:delivery_boy/constant/app_theme.dart';

class AppTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final String? helperText;
  final IconData? prefixIcon;
  final Widget? suffix;
  final TextEditingController? controller;
  final void Function(String)? onChanged;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final TextCapitalization textCapitalization;
  final int? maxLines;
  final int? maxLength;
  final bool enabled;
  final bool readOnly;
  final List<TextInputFormatter>? inputFormatters;
  final VoidCallback? onTap;
  final FocusNode? focusNode;
  final String? initialValue;

  const AppTextField({
    super.key,
    required this.label,
    this.hint,
    this.helperText,
    this.prefixIcon,
    this.suffix,
    this.controller,
    this.onChanged,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.textCapitalization = TextCapitalization.none,
    this.maxLines = 1,
    this.maxLength,
    this.enabled = true,
    this.readOnly = false,
    this.inputFormatters,
    this.onTap,
    this.focusNode,
    this.initialValue,
  });

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
          label,
          style: TextStyle(
            fontFamily: 'Mukta',
            fontSize: (w * 0.033).clamp(11.0, 14.0),
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            letterSpacing: 0.1,
          ),
        ),
        SizedBox(height: h * 0.010),

        // ── Input field ─────────────────────────────────────────
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          initialValue: initialValue,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          textCapitalization: textCapitalization,
          maxLines: maxLines,
          maxLength: maxLength,
          enabled: enabled,
          readOnly: readOnly,
          inputFormatters: inputFormatters,
          onChanged: onChanged,
          onTap: onTap,
          validator: validator,
          style: TextStyle(
            fontFamily: 'Mukta',
            fontSize: (w * 0.038).clamp(13.0, 16.0),
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            helperText: helperText,
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, size: 22, color: Colors.grey.shade400)
                : null,
            suffix: suffix,
            hintStyle: TextStyle(
              fontFamily: 'Mukta',
              fontSize: (w * 0.036).clamp(12.0, 15.0),
              color: AppColors.textHint,
            ),
            helperStyle: TextStyle(
              fontFamily: 'Mukta',
              fontSize: (w * 0.030).clamp(10.0, 13.0),
              color: AppColors.textSecondary,
            ),
            filled: true,
            fillColor: enabled
                ? const Color(0xFFF8F9FB)
                : Colors.grey.shade100,
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
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.border),
            ),
          ),
        ),
      ],
    );
  }
}
