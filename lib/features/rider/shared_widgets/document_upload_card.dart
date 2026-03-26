import 'dart:io';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:delivery_boy/constant/app_theme.dart';
import 'package:delivery_boy/features/rider/kyc/viewmodels/kyc_viewmodel.dart';

/// A reusable card for uploading a single KYC document.
/// Shows different states: idle, uploading, done, failed.
class DocumentUploadCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final UploadState uploadState;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  const DocumentUploadCard({
    super.key,
    required this.label,
    required this.icon,
    required this.uploadState,
    required this.onTap,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return switch (uploadState.progress) {
      UploadProgress.idle => _IdleCard(
          label: label,
          icon: icon,
          onTap: onTap,
        ),
      UploadProgress.uploading => _UploadingCard(label: label),
      UploadProgress.done => _DoneCard(
          label: label,
          localPath: uploadState.localPath,
          onReplace: onTap,
          onRemove: onRemove,
        ),
      UploadProgress.failed => _FailedCard(
          label: label,
          error: uploadState.errorMessage,
          onRetry: onTap,
        ),
    };
  }
}

// ── Idle ──────────────────────────────────────────────────────────────────

class _IdleCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _IdleCard({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: DottedBorder(
        borderType: BorderType.RRect,
        radius: const Radius.circular(12),
        color: Colors.grey.shade300,
        strokeWidth: 1.5,
        dashPattern: const [6, 4],
        child: Container(
          height: 90,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 22, color: AppColors.primary),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                'Tap to upload',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 11,
                  color: Colors.grey.shade400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Uploading ─────────────────────────────────────────────────────────────

class _UploadingCard extends StatelessWidget {
  final String label;

  const _UploadingCard({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor:
                  AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Uploading $label…',
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Done ──────────────────────────────────────────────────────────────────

class _DoneCard extends StatelessWidget {
  final String label;
  final String? localPath;
  final VoidCallback onReplace;
  final VoidCallback? onRemove;

  const _DoneCard({
    required this.label,
    required this.localPath,
    required this.onReplace,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.success.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(10),
              bottomLeft: Radius.circular(10),
            ),
            child: SizedBox(
              width: 80,
              height: 90,
              child: localPath != null
                  ? _SafeFileImage(path: localPath!)
                  : const Icon(Icons.image_outlined,
                      color: AppColors.success),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        color: AppColors.success, size: 16),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        label,
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.success,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _ActionChip(
                        label: 'Replace', color: AppColors.primary,
                        onTap: onReplace),
                    if (onRemove != null) ...[
                      const SizedBox(width: 6),
                      _ActionChip(
                          label: 'Remove', color: AppColors.error,
                          onTap: () => _confirmRemove(context)),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  void _confirmRemove(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove document?',
            style: TextStyle(
                fontFamily: 'Roboto', fontWeight: FontWeight.w700)),
        content: Text('Remove the uploaded $label?',
            style: const TextStyle(fontFamily: 'Roboto')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(fontFamily: 'Roboto')),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onRemove?.call();
            },
            child: const Text('Remove',
                style: TextStyle(
                    fontFamily: 'Roboto', color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

// ── Failed ────────────────────────────────────────────────────────────────

class _FailedCard extends StatelessWidget {
  final String label;
  final String? error;
  final VoidCallback onRetry;

  const _FailedCard({
    required this.label,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onRetry,
      child: Container(
        height: 90,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.error.withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: AppColors.error, size: 24),
            const SizedBox(height: 4),
            Text(
              error ?? 'Upload failed',
              style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 12,
                  color: AppColors.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Tap to retry',
              style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 11,
                  color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────

class _ActionChip extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionChip(
      {required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color),
        ),
      ),
    );
  }
}

/// Safely renders a file image, showing a placeholder if the file doesn't exist.
class _SafeFileImage extends StatelessWidget {
  final String path;

  const _SafeFileImage({required this.path});

  @override
  Widget build(BuildContext context) {
    final file = File(path);
    if (!file.existsSync()) {
      return Container(
        color: Colors.grey.shade200,
        child: const Icon(Icons.image_outlined, color: Colors.grey),
      );
    }
    return Image.file(file, fit: BoxFit.cover);
  }
}
