import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:delivery_boy/features/rider/kyc/models/kyc_section.dart';
import 'package:delivery_boy/features/rider/kyc/providers/kyc_providers.dart';
import 'package:delivery_boy/features/rider/kyc/views/widgets/kyc_document_field.dart';
import 'package:delivery_boy/features/rider/kyc/views/widgets/kyc_section_form_mixin.dart';
import 'package:delivery_boy/features/rider/kyc/views/widgets/kyc_section_layout.dart';
import 'package:delivery_boy/features/rider/profile/models/rider_me_profile_model.dart';
import 'package:delivery_boy/features/rider/shared_widgets/app_select_field.dart';
import 'package:delivery_boy/features/rider/shared_widgets/app_text_field.dart';

enum _IdType {
  ghanaCard('ghana_card', 'Ghana Card', ['ghana_card_front', 'ghana_card_back']),
  passport('passport', 'Passport', ['passport_bio_page']);

  const _IdType(this.apiValue, this.label, this.documents);

  final String apiValue;
  final String label;
  final List<String> documents;

  static _IdType from(String? value) =>
      values.firstWhere((t) => t.apiValue == value, orElse: () => ghanaCard);
}

/// `GHA-123456789-0`.
final _ghanaCardPattern = RegExp(r'^GHA-\d{9}-\d$');

class IdentitySection extends ConsumerStatefulWidget {
  const IdentitySection({super.key, required this.profile});

  final RiderMeProfileModel profile;

  @override
  ConsumerState<IdentitySection> createState() => _IdentitySectionState();
}

class _IdentitySectionState extends ConsumerState<IdentitySection>
    with KycSectionFormMixin {
  @override
  KycSection get section => KycSection.identity;

  late _IdType _idType = _IdType.from(widget.profile.idType);
  late final _numberCtrl = TextEditingController(text: widget.profile.idNumber);

  @override
  void dispose() {
    _numberCtrl.dispose();
    super.dispose();
  }

  /// The chosen ID's documents, plus any other identity document the
  /// server requires.
  List<String> _documents(RiderMeProfileModel profile) {
    final otherTypes = _IdType.values
        .where((t) => t != _idType)
        .expand((t) => t.documents)
        .toSet();
    final serverRequired = profile.documents.entries
        .where((e) =>
            e.value.required &&
            KycSection.forDocument(e.key) == section &&
            !otherTypes.contains(e.key))
        .map((e) => e.key);
    return {..._idType.documents, ...serverRequired}.toList();
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = ref.watch(kycActionsProvider.select((s) => s.isSaving));

    return Form(
      key: formKey,
      child: KycSectionLayout(
        section: section,
        primaryLabel: 'Save & continue',
        isBusy: isSaving,
        onPrimary: _save,
        children: [
          AppSelectField<_IdType>(
            label: 'ID type',
            value: _idType,
            options: _IdType.values,
            labelBuilder: (t) => t.label,
            prefixIcon: HugeIcons.strokeRoundedIdentityCard,
            onChanged: (t) {
              clearServerError('id_type');
              if (t != null) setState(() => _idType = t);
            },
            validator: (_) => serverError('id_type'),
          ),
          AppTextField(
            label: '${_idType.label} number',
            hint: _idType == _IdType.ghanaCard ? 'GHA-000000000-0' : null,
            prefixIcon: HugeIcons.strokeRoundedIdVerified,
            controller: _numberCtrl,
            textCapitalization: TextCapitalization.characters,
            textInputAction: TextInputAction.done,
            inputFormatters: [_UpperCaseFormatter()],
            onChanged: (_) => clearServerError('id_number'),
            validator: _validateNumber,
          ),
          KycSubheading(
            'Photos of your ${_idType.label}',
            caption: 'Uploaded as soon as you pick them.',
          ),
          for (final slug in _documents(widget.profile))
            KycDocumentField(slug: slug),
        ],
      ),
    );
  }

  String? _validateNumber(String? value) {
    final server = serverError('id_number');
    if (server != null) return server;
    final number = (value ?? '').trim();
    if (number.isEmpty) return 'Enter your ${_idType.label} number';
    if (_idType == _IdType.ghanaCard && !_ghanaCardPattern.hasMatch(number)) {
      return 'Use the format GHA-000000000-0';
    }
    if (_idType == _IdType.passport && number.length < 6) {
      return 'Enter the full passport number';
    }
    return null;
  }

  void _save() => submit(
        () => ref.read(kycActionsProvider.notifier).saveProfile({
          'id_type': _idType.apiValue,
          'id_number': _numberCtrl.text.trim(),
        }),
      );
}

class _UpperCaseFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) =>
      newValue.copyWith(text: newValue.text.toUpperCase());
}
