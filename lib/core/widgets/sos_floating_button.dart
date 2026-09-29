import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:delivery_boy/constant/app_theme.dart';
import 'package:delivery_boy/core/widgets/custom_dialogs.dart';

/// A persistent SOS floating button shown during active deliveries.
class SosFloatingButton extends StatelessWidget {
  const SosFloatingButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => _callEmergency(context),
      backgroundColor: AppColors.error,
      foregroundColor: Colors.white,
      tooltip: 'SOS Emergency',
      child: const Icon(HugeIcons.strokeRoundedAlert02, size: 28),
    );
  }

  void _callEmergency(BuildContext context) {
    CustomDialog.showConfirmation(
      context: context,
      title: 'SOS Emergency',
      subtitle: 'Are you sure you want to call emergency services?',
      confirmText: 'Call Now',
      isDestructive: true,
      icon: HugeIcons.strokeRoundedAlert02,
      onConfirm: () async {
        final uri = Uri.parse('tel:911');
        if (await canLaunchUrl(uri)) await launchUrl(uri);
      },
    );
  }
}
