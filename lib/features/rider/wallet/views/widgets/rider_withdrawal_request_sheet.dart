import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:delivery_boy/constant/app_theme.dart';
import 'package:delivery_boy/core/widgets/app_gradient_button.dart';
import 'package:delivery_boy/core/widgets/app_toast.dart';
import 'package:delivery_boy/core/widgets/drag_handle.dart';
import 'package:delivery_boy/features/rider/shared/rider_me_action_status.dart';
import 'package:delivery_boy/features/rider/wallet/providers/rider_me_wallet_providers.dart';

/// Amount-entry bottom sheet for `POST /rider/me/withdrawals`. All client
/// validation (rider-wallet-apis.md #4: `numeric, min:1, max:1000000`, plus
/// an available-balance check) runs before any network call so the common
/// failure case never reaches the server. A 422 on `errors.amount` is shown
/// inline on the field rather than as a toast.
class RiderWithdrawalRequestSheet {
  RiderWithdrawalRequestSheet._();

  static Future<void> show(
    BuildContext context, {
    required num availableBalance,
    required String currency,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RequestSheetBody(
        availableBalance: availableBalance,
        currency: currency,
      ),
    );
  }
}

class _RequestSheetBody extends ConsumerStatefulWidget {
  final num availableBalance;
  final String currency;

  const _RequestSheetBody({
    required this.availableBalance,
    required this.currency,
  });

  @override
  ConsumerState<_RequestSheetBody> createState() => _RequestSheetBodyState();
}

class _RequestSheetBodyState extends ConsumerState<_RequestSheetBody> {
  final _controller = TextEditingController();
  String? _localError;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String? _validate(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return 'Enter an amount';
    final amount = num.tryParse(trimmed);
    if (amount == null) return 'Enter a valid number';
    if (amount < 1) {
      return 'Minimum withdrawal is ${widget.currency} 1.00';
    }
    if (amount > 1000000) {
      return 'Maximum withdrawal is ${widget.currency} 1,000,000.00';
    }
    if (amount > widget.availableBalance) {
      return 'Amount exceeds your available balance';
    }
    return null;
  }

  void _onChanged(String _) {
    final state = ref.read(riderMeWalletProvider);
    if (_localError != null || state.actionFieldErrors != null) {
      setState(() => _localError = null);
      if (state.actionFieldErrors != null) {
        ref.read(riderMeWalletProvider.notifier).clearActionStatus();
      }
    }
  }

  Future<void> _submit() async {
    final error = _validate(_controller.text);
    setState(() => _localError = error);
    if (error != null) return;

    final amount = num.parse(_controller.text.trim());
    final success = await ref
        .read(riderMeWalletProvider.notifier)
        .requestWithdrawal(amount);
    if (!mounted) return;
    if (success) {
      Navigator.of(context).pop();
      AppToast.show(
        context,
        isSuccess: true,
        title: 'Withdrawal requested',
        subtitle: "We'll notify you once it's processed.",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final state = ref.watch(riderMeWalletProvider);
    final inProgress = state.actionStatus == RiderMeActionStatus.inProgress;
    final amountErrors = state.actionFieldErrors?['amount'];
    final serverFieldError = (amountErrors != null && amountErrors.isNotEmpty)
        ? amountErrors.first
        : null;
    final fieldError = _localError ?? serverFieldError;

    ref.listen(riderMeWalletProvider, (previous, next) {
      final isNewFailure = next.actionStatus == RiderMeActionStatus.error &&
          previous?.actionStatus != RiderMeActionStatus.error;
      final hasAmountFieldError =
          next.actionFieldErrors?.containsKey('amount') == true;
      if (isNewFailure && !hasAmountFieldError) {
        AppToast.show(
          context,
          isSuccess: false,
          title: 'Withdrawal failed',
          subtitle:
              next.actionMessage ?? 'Something went wrong. Please try again.',
        );
      }
    });

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        padding: EdgeInsets.fromLTRB(w * 0.05, 0, w * 0.05, w * 0.07),
        decoration: BoxDecoration(
          color: AppColors.scaffold,
          borderRadius: BorderRadius.vertical(top: Radius.circular(w * 0.06)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const DragHandle(),
            Text(
              'Withdraw funds',
              style: TextStyle(
                fontFamily: 'Mukta',
                fontSize: w * 0.05,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: w * 0.015),
            Text(
              'Available balance: ${widget.currency} ${widget.availableBalance.toStringAsFixed(2)}',
              style: TextStyle(
                fontFamily: 'Mukta',
                fontSize: w * 0.034,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: w * 0.05),
            TextField(
              controller: _controller,
              autofocus: true,
              enabled: !inProgress,
              onChanged: _onChanged,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              style: TextStyle(
                fontFamily: 'Mukta',
                fontSize: w * 0.042,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                labelText: 'Amount (${widget.currency})',
                errorText: fieldError,
                errorMaxLines: 2,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(w * 0.03),
                ),
              ),
            ),
            SizedBox(height: w * 0.06),
            AppGradientButton(
              label: 'Request withdrawal',
              isLoading: inProgress,
              onPressed: inProgress ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
