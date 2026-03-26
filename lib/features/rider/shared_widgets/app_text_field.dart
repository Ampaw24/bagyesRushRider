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
    return TextFormField(
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
      style: const TextStyle(
        fontFamily: 'Roboto',
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        helperText: helperText,
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, size: 20, color: Colors.grey.shade400)
            : null,
        suffix: suffix,
        labelStyle: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 14,
          color: Colors.grey.shade500,
        ),
        hintStyle: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 14,
          color: Colors.grey.shade400,
        ),
        helperStyle: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 12,
          color: Colors.grey.shade500,
        ),
        filled: true,
        fillColor: enabled ? Colors.grey.shade50 : Colors.grey.shade100,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
      ),
    );
  }
}
