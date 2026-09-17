import 'dart:io';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:delivery_boy/constant/app_theme.dart';
import 'package:delivery_boy/core/router/app_routes.dart';
import 'package:delivery_boy/core/widgets/app_gradient_button.dart';
import 'package:delivery_boy/features/rider/profile/data/rider_document_types.dart';
import 'package:delivery_boy/features/rider/profile/providers/rider_document_completion_providers.dart';
import 'package:delivery_boy/features/rider/profile/providers/rider_me_profile_providers.dart';
import 'package:delivery_boy/features/rider/profile/views/screens/rider_selfie_capture_screen.dart';
import 'package:hugeicons/hugeicons.dart';

enum _DocStatus { pending, uploading, uploaded, failed }

const _docs = riderDocumentTypes;

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
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncFromProfile());
  }

  Future<void> _syncFromProfile() async {
    final notifier = ref.read(riderMeProfileProvider.notifier);
    await notifier.load();
    if (!mounted) return;

    final profile = ref.read(riderMeProfileProvider).profile;
    if (profile == null) return;

    if (profile.photoUrl != null && profile.photoUrl!.isNotEmpty) {
      setState(() => _statuses['selfie'] = _DocStatus.uploaded);
    }

    for (final doc in _docs) {
      if (doc.key == 'selfie') continue;
      final result = await notifier.getDocument(doc.key);
      if (!mounted) return;
      if (result?.url != null && result!.url!.isNotEmpty) {
        setState(() => _statuses[doc.key] = _DocStatus.uploaded);
      }
    }
  }

  int get _uploadedCount =>
      _statuses.values.where((s) => s == _DocStatus.uploaded).length;

  @override
  Widget build(BuildContext context) {
    final isComplete = _uploadedCount == _docs.length;
    final w = MediaQuery.sizeOf(context).width;
    final h = MediaQuery.sizeOf(context).height;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(HugeIcons.strokeRoundedArrowLeft01,
              color: AppColors.textPrimary, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Upload Documents',
          style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                  w * 0.05, h * 0.02, w * 0.05, h * 0.005),
              child: _buildProgressCard(w),
            ),
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.fromLTRB(
                    w * 0.05, h * 0.012, w * 0.05, h * 0.16),
                itemCount: _docs.length,
                separatorBuilder: (_, __) => SizedBox(height: h * 0.014),
                itemBuilder: (_, i) => _buildDocCard(_docs[i], w),
              ),
            ),
          ],
        ),
      ),
      bottomSheet: Container(
        color: Colors.white,
        padding: EdgeInsets.fromLTRB(
            w * 0.05, h * 0.014, w * 0.05, bottomInset + h * 0.018),
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

  Widget _buildProgressCard(double w) {
    final total = _docs.length;
    final progress = total == 0 ? 0.0 : _uploadedCount / total;
    final allDone = _uploadedCount == total;
    final tint = allDone ? AppColors.success : AppColors.primary;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(w * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(w * 0.035),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Verification progress',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: (w * 0.036).clamp(13.0, 15.0),
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '$_uploadedCount/$total',
                style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: (w * 0.036).clamp(13.0, 15.0),
                  fontWeight: FontWeight.w700,
                  color: tint,
                ),
              ),
            ],
          ),
          SizedBox(height: w * 0.025),
          ClipRRect(
            borderRadius: BorderRadius.circular(w * 0.02),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: w * 0.016,
              backgroundColor: AppColors.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(tint),
            ),
          ),
          SizedBox(height: w * 0.022),
          Text(
            allDone
                ? 'All documents verified — you\'re ready to go!'
                : 'Upload clear photos to get verified and start accepting orders.',
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: (w * 0.032).clamp(11.5, 13.0),
              color: AppColors.textSecondary,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocCard(RiderDocumentType doc, double w) {
    final status = _statuses[doc.key]!;
    final localFile = _files[doc.key];
    final isUploading = status == _DocStatus.uploading;
    final isUploaded = status == _DocStatus.uploaded;
    final isFailed = status == _DocStatus.failed;

    final accent = switch (status) {
      _DocStatus.uploaded => AppColors.success,
      _DocStatus.uploading => AppColors.primary,
      _DocStatus.failed => AppColors.error,
      _DocStatus.pending => AppColors.textHint,
    };

    final statusIcon = switch (status) {
      _DocStatus.uploaded => HugeIcons.strokeRoundedCheckmarkCircle01,
      _DocStatus.uploading => HugeIcons.strokeRoundedRefresh,
      _DocStatus.failed => HugeIcons.strokeRoundedAlert01,
      _DocStatus.pending => HugeIcons.strokeRoundedCameraAdd01,
    };

    final statusText = switch (status) {
      _DocStatus.uploaded => 'Verified',
      _DocStatus.uploading => 'Uploading…',
      _DocStatus.failed => 'Upload failed — tap to retry',
      _DocStatus.pending => 'Tap to upload',
    };

    return GestureDetector(
      onTap: isUploading ? null : () => _pick(doc),
      child: Container(
        padding: EdgeInsets.all(w * 0.035),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(w * 0.035),
          border: Border.all(
            color: isUploaded || isFailed
                ? accent.withValues(alpha: 0.35)
                : AppColors.border,
            width: isUploaded || isFailed ? 1.2 : 1,
          ),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(w * 0.025),
              child: SizedBox(
                width: w * 0.16,
                height: w * 0.16,
                child: _buildDocVisual(doc, status, localFile, w),
              ),
            ),
            SizedBox(width: w * 0.035),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doc.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: (w * 0.037).clamp(13.0, 15.0),
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: w * 0.014),
                  Row(
                    children: [
                      Icon(statusIcon, size: w * 0.033, color: accent),
                      SizedBox(width: w * 0.014),
                      Expanded(
                        child: Text(
                          statusText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: (w * 0.031).clamp(11.0, 12.5),
                            fontWeight: FontWeight.w500,
                            color: accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: w * 0.02),
            Icon(HugeIcons.strokeRoundedArrowRight01,
                size: w * 0.045, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }

  Widget _buildDocVisual(
      RiderDocumentType doc, _DocStatus status, File? localFile, double w) {
    if (status == _DocStatus.uploading) {
      return Container(
        color: AppColors.primary.withValues(alpha: 0.06),
        alignment: Alignment.center,
        child: SizedBox(
          width: w * 0.055,
          height: w * 0.055,
          child: const CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.primary,
          ),
        ),
      );
    }

    if (localFile != null) {
      return Image.file(localFile, fit: BoxFit.cover);
    }

    if (status == _DocStatus.uploaded) {
      return Container(
        color: AppColors.success.withValues(alpha: 0.08),
        alignment: Alignment.center,
        child: Icon(HugeIcons.strokeRoundedCheckmarkCircle01,
            color: AppColors.success, size: w * 0.07),
      );
    }

    if (status == _DocStatus.failed) {
      return Container(
        color: AppColors.error.withValues(alpha: 0.08),
        alignment: Alignment.center,
        child: Icon(HugeIcons.strokeRoundedAlert01,
            color: AppColors.error, size: w * 0.065),
      );
    }

    return DottedBorder(
      borderType: BorderType.RRect,
      radius: Radius.circular(w * 0.025),
      color: AppColors.border,
      strokeWidth: 1.4,
      dashPattern: const [5, 3],
      child: Container(
        color: AppColors.surfaceVariant,
        alignment: Alignment.center,
        child: Icon(doc.icon, color: AppColors.textHint, size: w * 0.065),
      ),
    );
  }

  Future<void> _pick(RiderDocumentType doc) async {
    final File? f;
    if (doc.key == 'selfie') {
      f = await Navigator.of(context).push<File>(
        MaterialPageRoute(builder: (_) => const RiderSelfieCaptureScreen()),
      );
    } else {
      final file = await ImagePicker()
          .pickImage(source: ImageSource.gallery, imageQuality: 80);
      f = file == null ? null : File(file.path);
    }
    if (f == null || !mounted) return;

    setState(() {
      _files[doc.key] = f!;
      _statuses[doc.key] = _DocStatus.uploading;
    });

    final notifier = ref.read(riderMeProfileProvider.notifier);
    final ok = doc.key == 'selfie'
        ? await notifier.uploadPhoto(f.path)
        : (await notifier.uploadDocument(type: doc.key, filePath: f.path)) !=
            null;

    if (mounted) {
      setState(() {
        _statuses[doc.key] =
            ok ? _DocStatus.uploaded : _DocStatus.failed;
      });
      if (ok) {
        HapticFeedback.lightImpact();
        ref.read(riderDocumentCompletionProvider.notifier).refresh();
      }
    }
  }
}
