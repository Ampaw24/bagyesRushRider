import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:delivery_boy/constant/app_theme.dart';
import 'package:delivery_boy/core/router/app_routes.dart';
import 'package:delivery_boy/core/widgets/app_gradient_button.dart';
import 'package:delivery_boy/core/widgets/status_badge.dart';
import 'package:delivery_boy/features/rider/profile/providers/rider_profile_providers.dart';
import 'package:hugeicons/hugeicons.dart';

enum _DocStatus { pending, uploading, uploaded, failed }

class _DocConfig {
  final String key;
  final String label;
  final IconData icon;
  const _DocConfig(this.key, this.label, this.icon);
}

const _docs = [
  _DocConfig('selfie', 'Profile Selfie', HugeIcons.strokeRoundedFaceId),
  _DocConfig('licenceFront', "Driver's Licence — Front", HugeIcons.strokeRoundedCreditCard),
  _DocConfig('licenceBack', "Driver's Licence — Back", HugeIcons.strokeRoundedCreditCardNotAccept),
  _DocConfig('motorIssurance', 'Motor Insurance', HugeIcons.strokeRoundedShield01),
  _DocConfig('roadWorthy', 'Roadworthy Certificate', HugeIcons.strokeRoundedCheckmarkBadge01),
];

class RiderDocumentUploadScreen extends ConsumerStatefulWidget {
  const RiderDocumentUploadScreen({super.key});

  @override
  ConsumerState<RiderDocumentUploadScreen> createState() =>
      _RiderDocumentUploadScreenState();
}

class _RiderDocumentUploadScreenState
    extends ConsumerState<RiderDocumentUploadScreen> {
  final Map<String, _DocStatus> _statuses = {
    for (final d in _docs) d.key: _DocStatus.pending,
  };
  final Map<String, File?> _files = {
    for (final d in _docs) d.key: null,
  };

  @override
  void initState() {
    super.initState();
    // Pre-fill status for already-uploaded docs
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncFromUser());
  }

  void _syncFromUser() {
    final user = ref.read(riderProfileProvider).user;
    if (user == null) return;
    final map = user.toJson();
    setState(() {
      for (final doc in _docs) {
        final val = map[doc.key];
        if (val != null && val.toString().isNotEmpty) {
          _statuses[doc.key] = _DocStatus.uploaded;
        }
      }
    });
  }

  int get _uploadedCount =>
      _statuses.values.where((s) => s == _DocStatus.uploaded).length;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(riderProfileProvider).user;
    final isComplete = user?.isProfileComplete ?? false;

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Upload Documents',
          style: TextStyle(
            fontFamily: 'Roboto',
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: Column(
        children: [
          // ── Progress header ────────────────────────────────────────────────
          Container(
            color: AppColors.primary,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_uploadedCount of ${_docs.length} documents uploaded',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                    fontFamily: 'Roboto',
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _uploadedCount / _docs.length,
                    backgroundColor: Colors.white.withValues(alpha: 0.3),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Colors.white),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),

          // ── Document cards ─────────────────────────────────────────────────
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: _docs.length,
              itemBuilder: (_, i) => _buildDocCard(_docs[i]),
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: AppGradientButton(
          label: isComplete
              ? 'Continue to Dashboard'
              : 'Upload all documents to continue',
          onPressed: isComplete
              ? () {
                  HapticFeedback.lightImpact();
                  context.go(AppRoutes.dashboard);
                }
              : null,
        ),
      ),
    );
  }

  Widget _buildDocCard(_DocConfig doc) {
    final status = _statuses[doc.key]!;
    final localFile = _files[doc.key];
    final isUploading = status == _DocStatus.uploading;

    final borderColor = switch (status) {
      _DocStatus.uploaded => AppColors.success,
      _DocStatus.uploading => AppColors.primary,
      _DocStatus.failed => AppColors.error,
      _DocStatus.pending => Colors.grey.shade300,
    };

    final badge = switch (status) {
      _DocStatus.uploaded =>
        StatusBadge(label: 'Uploaded', color: AppColors.success),
      _DocStatus.uploading =>
        StatusBadge(label: 'Uploading...', color: AppColors.primary),
      _DocStatus.failed =>
        StatusBadge(label: 'Failed', color: AppColors.error),
      _DocStatus.pending =>
        StatusBadge(label: 'Pending', color: Colors.grey.shade400),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: borderColor, width: 4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: borderColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(doc.icon, color: borderColor, size: 22),
            ),
            const SizedBox(width: 12),

            // Label + badge
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doc.label,
                    style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  badge,
                ],
              ),
            ),

            // Preview thumbnail or pick button
            const SizedBox(width: 8),
            GestureDetector(
              onTap: isUploading ? null : () => _pick(doc),
              child: isUploading
                  ? const SizedBox(
                      width: 44,
                      height: 44,
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    )
                  : localFile != null || status == _DocStatus.uploaded
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: localFile != null
                              ? Image.file(localFile,
                                  width: 44, height: 44, fit: BoxFit.cover)
                              : Container(
                                  width: 44,
                                  height: 44,
                                  color: AppColors.success
                                      .withValues(alpha: 0.1),
                                  child: const Icon(HugeIcons.strokeRoundedCheckmarkCircle01,
                                      color: AppColors.success),
                                ),
                        )
                      : DottedBorder(
                          borderType: BorderType.RRect,
                          radius: const Radius.circular(8),
                          color: Colors.grey.shade400,
                          strokeWidth: 1.5,
                          dashPattern: const [4, 3],
                          child: Container(
                            width: 44,
                            height: 44,
                            alignment: Alignment.center,
                            child: Icon(HugeIcons.strokeRoundedCameraAdd01,
                                color: Colors.grey.shade500, size: 20),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pick(_DocConfig doc) async {
    final file = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (file == null || !mounted) return;

    final f = File(file.path);
    setState(() {
      _files[doc.key] = f;
      _statuses[doc.key] = _DocStatus.uploading;
    });

    final userId = ref.read(riderProfileProvider).user?.id ?? '';
    final filename = f.path.split('/').last;
    final formData = FormData.fromMap({
      'id': userId,
      doc.key: await MultipartFile.fromFile(f.path, filename: filename),
    });

    final ok = await ref.read(riderProfileProvider.notifier).uploadDoc(formData);

    if (mounted) {
      setState(() {
        _statuses[doc.key] =
            ok ? _DocStatus.uploaded : _DocStatus.failed;
      });
      if (ok) HapticFeedback.lightImpact();
    }
  }
}
