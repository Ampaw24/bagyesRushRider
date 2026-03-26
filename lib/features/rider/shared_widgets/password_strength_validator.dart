import 'package:flutter/material.dart';
import 'package:delivery_boy/constant/app_theme.dart';

enum PasswordStrength { weak, medium, strong }

/// Evaluates password strength based on 4 criteria.
/// Returns: weak (0-1), medium (2-3), strong (4).
PasswordStrength evaluatePasswordStrength(String password) {
  int score = 0;
  if (password.length >= 8) score++;
  if (password.contains(RegExp(r'[A-Z]'))) score++;
  if (password.contains(RegExp(r'[0-9]'))) score++;
  if (password.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-]'))) score++;
  if (score <= 1) return PasswordStrength.weak;
  if (score <= 3) return PasswordStrength.medium;
  return PasswordStrength.strong;
}

/// Displays a real-time password strength indicator and animated checklist.
/// Pure stateless widget — driven by [password] parameter from parent setState.
class PasswordStrengthValidator extends StatelessWidget {
  final String password;

  const PasswordStrengthValidator({super.key, required this.password});

  @override
  Widget build(BuildContext context) {
    if (password.isEmpty) return const SizedBox.shrink();

    final strength = evaluatePasswordStrength(password);
    final hasMin8 = password.length >= 8;
    final hasUpper = password.contains(RegExp(r'[A-Z]'));
    final hasNumber = password.contains(RegExp(r'[0-9]'));
    final hasSpecial =
        password.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>_\-]'));

    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          // Strength bar
          Row(
            children: [
              _StrengthSegment(
                active: strength == PasswordStrength.weak ||
                    strength == PasswordStrength.medium ||
                    strength == PasswordStrength.strong,
                color: AppColors.error,
              ),
              const SizedBox(width: 4),
              _StrengthSegment(
                active: strength == PasswordStrength.medium ||
                    strength == PasswordStrength.strong,
                color: AppColors.warning,
              ),
              const SizedBox(width: 4),
              _StrengthSegment(
                active: strength == PasswordStrength.strong,
                color: AppColors.success,
              ),
              const SizedBox(width: 10),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Text(
                  _strengthLabel(strength),
                  key: ValueKey(strength),
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _strengthColor(strength),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Checklist
          _CheckItem(met: hasMin8, label: 'Minimum 8 characters'),
          _CheckItem(met: hasUpper, label: 'One uppercase letter'),
          _CheckItem(met: hasNumber, label: 'One number'),
          _CheckItem(met: hasSpecial, label: 'One special character'),
        ],
      ),
    );
  }

  String _strengthLabel(PasswordStrength s) {
    switch (s) {
      case PasswordStrength.weak:
        return 'Weak';
      case PasswordStrength.medium:
        return 'Medium';
      case PasswordStrength.strong:
        return 'Strong';
    }
  }

  Color _strengthColor(PasswordStrength s) {
    switch (s) {
      case PasswordStrength.weak:
        return AppColors.error;
      case PasswordStrength.medium:
        return AppColors.warning;
      case PasswordStrength.strong:
        return AppColors.success;
    }
  }
}

class _StrengthSegment extends StatelessWidget {
  final bool active;
  final Color color;

  const _StrengthSegment({required this.active, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 4,
        decoration: BoxDecoration(
          color: active ? color : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _CheckItem extends StatelessWidget {
  final bool met;
  final String label;

  const _CheckItem({required this.met, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, anim) =>
                ScaleTransition(scale: anim, child: child),
            child: Icon(
              met ? Icons.check_circle_rounded : Icons.circle_outlined,
              key: ValueKey(met),
              size: 16,
              color: met ? AppColors.success : Colors.grey.shade400,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 12,
              color: met ? AppColors.textPrimary : Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}
