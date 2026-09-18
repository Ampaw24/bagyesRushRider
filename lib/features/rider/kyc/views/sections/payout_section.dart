import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:delivery_boy/core/errors/failures.dart';
import 'package:delivery_boy/features/rider/kyc/models/kyc_section.dart';
import 'package:delivery_boy/features/rider/kyc/providers/kyc_providers.dart';
import 'package:delivery_boy/features/rider/kyc/views/widgets/kyc_section_form_mixin.dart';
import 'package:delivery_boy/features/rider/kyc/views/widgets/kyc_section_layout.dart';
import 'package:delivery_boy/features/rider/profile/models/payout_provider_model.dart';
import 'package:delivery_boy/features/rider/profile/models/rider_me_profile_model.dart';
import 'package:delivery_boy/features/rider/shared_widgets/app_password_field.dart';
import 'package:delivery_boy/features/rider/shared_widgets/app_phone_field.dart';
import 'package:delivery_boy/features/rider/shared_widgets/app_select_field.dart';
import 'package:delivery_boy/features/rider/shared_widgets/app_text_field.dart';

enum _Method { mobileMoney, bank }

class PayoutSection extends ConsumerStatefulWidget {
  const PayoutSection({super.key, required this.profile});

  final RiderMeProfileModel profile;

  @override
  ConsumerState<PayoutSection> createState() => _PayoutSectionState();
}

class _PayoutSectionState extends ConsumerState<PayoutSection>
    with KycSectionFormMixin {
  @override
  KycSection get section => KycSection.payout;

  @override
  Set<String> get inlineErrorFields => {
        'payout_provider_id',
        'momo_provider_id',
        'account_number',
        'account_name',
        'mobile_money_number',
        'current_password',
      };

  late _Method _method = widget.profile.payout.payoutProviderId != null &&
          !widget.profile.payout.isMobileMoney
      ? _Method.bank
      : _Method.mobileMoney;
  late int? _providerId = _method == _Method.bank
      ? widget.profile.payout.payoutProviderId
      : widget.profile.payout.momoProviderId;

  late final _accountNameCtrl = TextEditingController(
    text: widget.profile.payout.accountName ?? widget.profile.fullName,
  );
  final _accountNumberCtrl = TextEditingController();
  final _momoDigitsCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  String _momoNumber = '+233';

  @override
  void dispose() {
    _accountNameCtrl.dispose();
    _accountNumberCtrl.dispose();
    _momoDigitsCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  bool get _isMomo => _method == _Method.mobileMoney;

  String get _providerKey => _isMomo ? 'momo_provider_id' : 'payout_provider_id';

  void _switchMethod(_Method method) {
    if (method == _method) return;
    setState(() {
      _method = method;
      _providerId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = ref.watch(kycActionsProvider.select((s) => s.isSaving));
    final providers = ref.watch(payoutProvidersProvider);
    final current = widget.profile.payout;

    final options = (providers.valueOrNull ?? const <PayoutProviderModel>[])
        .where((p) => p.isMobileMoney == _isMomo)
        .toList();
    PayoutProviderModel? selected;
    for (final p in options) {
      if (p.id == _providerId) selected = p;
    }

    return Form(
      key: formKey,
      child: KycSectionLayout(
        section: section,
        primaryLabel:
            current.isConfigured ? 'Update payout account' : 'Save & continue',
        isBusy: isSaving,
        onPrimary: _save,
        children: [
          if (current.isConfigured) _CurrentPayout(payout: current),
          _MethodToggle(value: _method, onChanged: _switchMethod),
          AppSelectField<PayoutProviderModel>(
            key: ValueKey('provider-$_method-${options.length}'),
            label: _isMomo ? 'Mobile money network' : 'Bank',
            hint: _isMomo ? 'Select network' : 'Select bank',
            value: selected,
            options: options,
            labelBuilder: (p) => p.name,
            prefixIcon: _isMomo
                ? HugeIcons.strokeRoundedSmartPhone01
                : HugeIcons.strokeRoundedBank,
            enabled: options.isNotEmpty,
            disabledHint: _providersHint(providers),
            onChanged: (p) {
              clearServerError(_providerKey);
              if (p != null) setState(() => _providerId = p.id);
            },
            validator: (p) =>
                serverError(_providerKey) ??
                (p == null ? 'Select a ${_isMomo ? 'network' : 'bank'}' : null),
          ),
          if (providers.hasError)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => ref.invalidate(payoutProvidersProvider),
                icon: const Icon(HugeIcons.strokeRoundedRefresh),
                label: const Text('Try loading providers again'),
              ),
            ),
          if (_isMomo)
            AppPhoneField(
              digitController: _momoDigitsCtrl,
              onChanged: (full) {
                clearServerError('mobile_money_number');
                _momoNumber = full;
              },
              validator: (_) =>
                  serverError('mobile_money_number') ?? _validateMomo(),
            )
          else
            AppTextField(
              label: 'Account number',
              prefixIcon: HugeIcons.strokeRoundedBank,
              controller: _accountNumberCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => clearServerError('account_number'),
              validator: (v) =>
                  serverError('account_number') ??
                  ((v ?? '').trim().length < 6
                      ? 'Enter the full account number'
                      : null),
            ),
          AppTextField(
            label: 'Account name',
            hint: 'Name registered on the account',
            prefixIcon: HugeIcons.strokeRoundedUser,
            controller: _accountNameCtrl,
            textCapitalization: TextCapitalization.words,
            onChanged: (_) => clearServerError('account_name'),
            validator: (v) =>
                serverError('account_name') ??
                ((v ?? '').trim().length < 3 ? 'Enter the account name' : null),
          ),
          AppPasswordField(
            label: 'Your password',
            hint: 'Confirms it’s you changing where you’re paid',
            controller: _passwordCtrl,
            textInputAction: TextInputAction.done,
            onChanged: (_) => clearServerError('current_password'),
            validator: (v) =>
                serverError('current_password') ??
                ((v ?? '').isEmpty ? 'Enter your password' : null),
          ),
        ],
      ),
    );
  }

  String _providersHint(AsyncValue<List<PayoutProviderModel>> providers) {
    if (providers.isLoading) return 'Loading providers…';
    final error = providers.error;
    if (error is Failure) return error.message;
    if (error != null) return "Couldn't load providers";
    return 'None available';
  }

  String? _validateMomo() {
    final digits = _momoDigitsCtrl.text.trim();
    if (digits.isEmpty) return 'Enter your mobile money number';
    if (digits.startsWith('0')) return 'Remove the leading zero';
    if (_momoNumber.startsWith('+233') && digits.length != 9) {
      return 'Ghana numbers have 9 digits after +233';
    }
    return null;
  }

  void _save() {
    final actions = ref.read(kycActionsProvider.notifier);
    final accountName = _accountNameCtrl.text.trim();
    final password = _passwordCtrl.text;
    submit(
      () => _isMomo
          ? actions.savePayout(
              currentPassword: password,
              accountName: accountName,
              momoProviderId: _providerId,
              mobileMoneyNumber: _momoNumber.trim(),
            )
          : actions.savePayout(
              currentPassword: password,
              accountName: accountName,
              payoutProviderId: _providerId,
              accountNumber: _accountNumberCtrl.text.trim(),
            ),
    );
  }
}

class _MethodToggle extends StatelessWidget {
  const _MethodToggle({required this.value, required this.onChanged});

  final _Method value;
  final ValueChanged<_Method> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<_Method>(
      showSelectedIcon: false,
      segments: const [
        ButtonSegment(
          value: _Method.mobileMoney,
          label: Text('Mobile money'),
          icon: Icon(HugeIcons.strokeRoundedSmartPhone01),
        ),
        ButtonSegment(
          value: _Method.bank,
          label: Text('Bank account'),
          icon: Icon(HugeIcons.strokeRoundedBank),
        ),
      ],
      selected: {value},
      onSelectionChanged: (s) => onChanged(s.first),
    );
  }
}

/// The account on file, masked as the API returns it.
class _CurrentPayout extends StatelessWidget {
  const _CurrentPayout({required this.payout});

  final RiderPayoutInfo payout;

  @override
  Widget build(BuildContext context) {
    final provider = payout.isMobileMoney
        ? (payout.momoProviderName ?? 'Mobile money')
        : (payout.bankName ?? 'Bank account');
    final last4 = payout.isMobileMoney
        ? payout.mobileMoneyNumberLast4
        : payout.accountNumberLast4;

    return KycInfoRow(
      icon: payout.isMobileMoney
          ? HugeIcons.strokeRoundedSmartPhone01
          : HugeIcons.strokeRoundedBank,
      label: 'Paid to',
      value: last4 == null ? provider : '$provider •••• $last4',
      note: [
        if (payout.accountName != null) payout.accountName!,
        'Fill in the form below to change it.',
      ].join(' · '),
    );
  }
}
