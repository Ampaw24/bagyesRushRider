import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// A persistent SOS floating button shown during active deliveries.
class SosFloatingButton extends StatelessWidget {
  const SosFloatingButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => _callEmergency(context),
      backgroundColor: Colors.red.shade600,
      foregroundColor: Colors.white,
      tooltip: 'SOS Emergency',
      child: const Icon(Icons.sos_rounded, size: 28),
    );
  }

  Future<void> _callEmergency(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('SOS Emergency'),
        content: const Text('Are you sure you want to call emergency services?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Call Now', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final uri = Uri.parse('tel:911');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    }
  }
}
