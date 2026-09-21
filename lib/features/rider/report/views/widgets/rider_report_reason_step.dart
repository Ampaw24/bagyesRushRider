import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:delivery_boy/constant/app_theme.dart';
import 'package:delivery_boy/features/rider/report/models/rider_report_model.dart';

/// Step 3 (or 2, when the order-link step is skipped for `general`) —
/// "What went wrong?"
class RiderReportReasonStep extends StatelessWidget {
  final List<RiderReportReasonOption> reasons;
  final String? selectedCode;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onRetry;
  final ValueChanged<RiderReportReasonOption> onSelect;

  const RiderReportReasonStep({
    super.key,
    required this.reasons,
    required this.selectedCode,
    required this.isLoading,
    required this.errorMessage,
    required this.onRetry,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return ListView(
      padding: EdgeInsets.fromLTRB(w * 0.05, w * 0.03, w * 0.05, w * 0.06),
      children: [
        Text(
          'What went wrong?',
          style: TextStyle(
            fontSize: w * 0.052,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: w * 0.015),
        Text(
          'Choose the reason that best matches what happened.',
          style: TextStyle(fontSize: w * 0.034, color: AppColors.textSecondary),
        ),
        SizedBox(height: w * 0.05),
        if (isLoading)
          Padding(
            padding: EdgeInsets.symmetric(vertical: w * 0.12),
            child: const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          )
        else if (errorMessage != null)
          Padding(
            padding: EdgeInsets.symmetric(vertical: w * 0.1),
            child: Column(
              children: [
                Text(
                  "Couldn't load reasons",
                  style: TextStyle(
                    fontSize: w * 0.04,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: w * 0.02),
                Text(
                  errorMessage!,
                  style: TextStyle(
                      fontSize: w * 0.032, color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: w * 0.04),
                ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
              ],
            ),
          )
        else if (reasons.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: w * 0.12),
            child: Center(
              child: Text(
                'No reasons available.',
                style: TextStyle(
                    fontSize: w * 0.036, color: AppColors.textSecondary),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: reasons.length,
            separatorBuilder: (context, i) => SizedBox(height: w * 0.03),
            itemBuilder: (context, i) {
              final reason = reasons[i];
              final isSelected = reason.code == selectedCode;
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(w * 0.035),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    onSelect(reason);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: EdgeInsets.symmetric(
                        horizontal: w * 0.04, vertical: w * 0.035),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.07)
                          : AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(w * 0.035),
                      border: Border.all(
                        color:
                            isSelected ? AppColors.primary : AppColors.border,
                        width: isSelected ? 1.6 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        _ReasonSelector(isSelected: isSelected, w: w),
                        SizedBox(width: w * 0.035),
                        Expanded(
                          child: Text(
                            reason.label,
                            style: TextStyle(
                              fontSize: w * 0.036,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

class _ReasonSelector extends StatelessWidget {
  final bool isSelected;
  final double w;

  const _ReasonSelector({required this.isSelected, required this.w});

  @override
  Widget build(BuildContext context) {
    final size = w * 0.055;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected ? AppColors.primary : Colors.transparent,
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.border,
          width: 1.6,
        ),
      ),
      alignment: Alignment.center,
      child: isSelected
          ? Icon(Icons.check, size: size * 0.62, color: Colors.white)
          : null,
    );
  }
}
