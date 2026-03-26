import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:delivery_boy/constant/app_theme.dart';

class AppDatePickerField extends StatefulWidget {
  final String label;
  final DateTime? initialDate;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final void Function(DateTime)? onDateSelected;
  final String? Function(String?)? validator;
  final IconData? prefixIcon;

  const AppDatePickerField({
    super.key,
    required this.label,
    this.initialDate,
    this.firstDate,
    this.lastDate,
    this.onDateSelected,
    this.validator,
    this.prefixIcon,
  });

  @override
  State<AppDatePickerField> createState() => _AppDatePickerFieldState();
}

class _AppDatePickerFieldState extends State<AppDatePickerField> {
  final _ctrl = TextEditingController();
  DateTime? _selected;

  @override
  void initState() {
    super.initState();
    if (widget.initialDate != null) {
      _selected = widget.initialDate;
      _ctrl.text = _format(widget.initialDate!);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String _format(DateTime d) => DateFormat('dd MMM yyyy').format(d);

  Future<void> _pick() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selected ?? widget.initialDate ?? now,
      firstDate: widget.firstDate ?? DateTime(1900),
      lastDate: widget.lastDate ?? now,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _selected = picked;
        _ctrl.text = _format(picked);
      });
      widget.onDateSelected?.call(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _ctrl,
      readOnly: true,
      onTap: _pick,
      validator: widget.validator ??
          (v) {
            if (v == null || v.isEmpty) return 'Please select a date';
            return null;
          },
      style: const TextStyle(
        fontFamily: 'Roboto',
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: 'DD MMM YYYY',
        prefixIcon: Icon(
          widget.prefixIcon ?? Icons.calendar_today_outlined,
          size: 20,
          color: Colors.grey.shade400,
        ),
        suffixIcon: Icon(Icons.keyboard_arrow_down_rounded,
            size: 20, color: Colors.grey.shade400),
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
