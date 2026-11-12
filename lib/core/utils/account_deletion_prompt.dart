import 'package:flutter/widgets.dart';

import 'package:gopady_rider/core/utils/legal_links.dart';
import 'package:gopady_rider/core/widgets/custom_dialogs.dart';

/// Warns the rider, then opens the account-deletion page on the GoPady
/// website, where the deletion itself happens. Shared by the drawer's and
/// Settings' "Delete Account" entries.
///
/// [open] exists for tests; the app always uses [LegalLinks.open].
Future<void> confirmAccountDeletion(
  BuildContext context, {
  Future<void> Function(BuildContext, LegalDocument) open = LegalLinks.open,
}) =>
    CustomDialog.showConfirmation(
      context: context,
      title: 'Delete Account',
      subtitle: "You'll finish on the GoPady website, where you confirm "
          'with your phone number. Deleting your account is permanent: your '
          'delivery history and personal data cannot be recovered.',
      confirmText: 'Continue',
      cancelText: 'Cancel',
      onConfirm: () => open(context, LegalDocument.deleteAccount),
    );
