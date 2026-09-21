import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:delivery_boy/constant/app_theme.dart';

/// Help & Support — lets the rider reach the support team via email,
/// WhatsApp, or a direct call, each opening the respective app. Ported
/// from the customer/vendor app's `HelpSupportView`.
class RiderHelpSupportScreen extends StatelessWidget {
  const RiderHelpSupportScreen({super.key});

  static const String supportEmail = 'support@bagyesrush.com';
  static const String supportPhone = '+233 54 879 0987';
  static const String supportWhatsapp = '+233 54 879 0987';

  Future<void> _launch(
    BuildContext context,
    Uri uri, {
    required String failureMessage,
  }) async {
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(failureMessage)));
    }
  }

  void _openEmail(BuildContext context) {
    _launch(
      context,
      Uri(
          scheme: 'mailto',
          path: supportEmail,
          query: 'subject=Support Request'),
      failureMessage: 'No email app found on this device.',
    );
  }

  void _openWhatsapp(BuildContext context) {
    final digits = supportWhatsapp.replaceAll(RegExp(r'[^0-9]'), '');
    _launch(
      context,
      Uri.parse('https://wa.me/$digits'),
      failureMessage: 'WhatsApp is not installed on this device.',
    );
  }

  void _openCall(BuildContext context) {
    _launch(
      context,
      Uri(scheme: 'tel', path: supportPhone.replaceAll(' ', '')),
      failureMessage: 'Unable to start a call on this device.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(title: const Text('Help & Support')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(w * 0.055, w * 0.02, w * 0.055, w * 0.08),
        children: [
          Center(
            child: Container(
              width: w * 0.2,
              height: w * 0.2,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedCustomerService01,
                color: AppColors.primary,
                size: w * 0.09,
              ),
            ),
          ),
          SizedBox(height: w * 0.05),
          Text(
            "We're here to help",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: w * 0.05,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: w * 0.02),
          Text(
            'Reach out through any channel below to lodge a report or get '
            'support from our team.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: w * 0.035,
                color: AppColors.textSecondary,
                height: 1.4),
          ),
          SizedBox(height: w * 0.08),
          _SupportTile(
            icon: HugeIcons.strokeRoundedMail01,
            iconColor: AppColors.secondary,
            title: 'Email',
            subtitle: supportEmail,
            onTap: () => _openEmail(context),
          ),
          SizedBox(height: w * 0.035),
          _SupportTile(
            icon: HugeIcons.strokeRoundedWhatsapp,
            iconColor: const Color(0xFF25D366),
            title: 'WhatsApp',
            subtitle: supportWhatsapp,
            onTap: () => _openWhatsapp(context),
          ),
          SizedBox(height: w * 0.035),
          _SupportTile(
            icon: HugeIcons.strokeRoundedCall02,
            iconColor: AppColors.primary,
            title: 'Call Support',
            subtitle: supportPhone,
            onTap: () => _openCall(context),
          ),
        ],
      ),
    );
  }
}

class _SupportTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SupportTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;

    return Material(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(w * 0.04),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(w * 0.04),
        splashColor: iconColor.withValues(alpha: 0.08),
        highlightColor: iconColor.withValues(alpha: 0.04),
        child: Container(
          padding: EdgeInsets.all(w * 0.04),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(w * 0.04),
            border: Border.all(color: AppColors.border, width: 0.5),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(w * 0.03),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(w * 0.03),
                ),
                child: HugeIcon(icon: icon, color: iconColor, size: w * 0.06),
              ),
              SizedBox(width: w * 0.04),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: w * 0.038,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: w * 0.006),
                    Text(
                      subtitle,
                      style: TextStyle(
                          fontSize: w * 0.032, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              HugeIcon(
                icon: HugeIcons.strokeRoundedArrowRight01,
                color: AppColors.textHint,
                size: w * 0.038,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
