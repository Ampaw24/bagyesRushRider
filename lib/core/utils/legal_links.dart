import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:delivery_boy/core/utils/app_logger.dart';
import 'package:delivery_boy/core/widgets/custom_dialogs.dart';

/// The rider-facing legal pages hosted on the BagyesRUSH website.
enum LegalDocument {
  privacyPolicy(
    'Privacy Policy',
    'https://bagyesrushdelivery.com/privacy-policy',
  ),
  riderAgreement(
    'Rider Agreement',
    'https://bagyesrushdelivery.com/rider-agreement',
  ),
  termsConditions(
    'Terms & Conditions',
    'https://bagyesrushdelivery.com/terms-conditions',
  );

  const LegalDocument(this.title, this.url);

  final String title;
  final String url;
}

/// Opens [LegalDocument]s inside the app — Safari View Controller on iOS,
/// Chrome Custom Tabs on Android — so the rider reads them without being
/// sent out to a separate browser app, and returns with one tap.
class LegalLinks {
  const LegalLinks._();

  static Future<void> open(BuildContext context, LegalDocument doc) async {
    final uri = Uri.parse(doc.url);
    var opened = false;
    try {
      opened = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
      // Rare devices without an in-app browser (no Custom Tabs provider):
      // the external browser is still better than nothing.
      if (!opened) {
        opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e, s) {
      appLogger.e('[LegalLinks] failed to open ${doc.url}',
          error: e, stackTrace: s);
    }

    if (!opened && context.mounted) {
      CustomDialog.showError(
        context: context,
        title: "Couldn't Open ${doc.title}",
        subtitle: 'Please check your connection and try again.',
      );
    }
  }
}
