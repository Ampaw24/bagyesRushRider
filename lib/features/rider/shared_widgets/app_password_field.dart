import 'package:flutter/material.dart';
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
    return TextFormField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      obscureText: _obscure,
      enableSuggestions: false,
      autocorrect: false,
      textInputAction: widget.textInputAction,
      onChanged: widget.onChanged,
      validator: widget.validator,
      style: const TextStyle(
        fontFamily: 'Roboto',
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        prefixIcon: Icon(
          Icons.lock_outline_rounded,
          size: 20,
          color: Colors.grey.shade400,
        ),
        suffixIcon: GestureDetector(
          onTap: () => setState(() => _obscure = !_obscure),
          child: Icon(
            _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            size: 20,
            color: Colors.grey.shade400,
          ),
        ),
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
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
      ),
    );
  }
}
