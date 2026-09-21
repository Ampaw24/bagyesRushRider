import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:delivery_boy/constant/app_theme.dart';

const _maxPhotos = 5;

/// Last step — description + optional photo evidence, with a read-only
/// summary of who/what is being reported.
class RiderReportDetailsStep extends StatelessWidget {
  final String targetName;
  final String targetSubtitle;
  final String description;
  final ValueChanged<String> onDescriptionChanged;
  final List<File> photos;
  final bool isPickingPhotos;
  final VoidCallback onAddPhotos;
  final ValueChanged<int> onRemovePhoto;

  const RiderReportDetailsStep({
    super.key,
    required this.targetName,
    required this.targetSubtitle,
    required this.description,
    required this.onDescriptionChanged,
    required this.photos,
    required this.isPickingPhotos,
    required this.onAddPhotos,
    required this.onRemovePhoto,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    final canAddMore = photos.length < _maxPhotos;

    return ListView(
      padding: EdgeInsets.fromLTRB(w * 0.05, w * 0.03, w * 0.05, w * 0.06),
      children: [
        Text(
          'Add the details',
          style: TextStyle(
            fontSize: w * 0.052,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: w * 0.015),
        Text(
          'A clear description helps our team resolve this faster.',
          style: TextStyle(fontSize: w * 0.034, color: AppColors.textSecondary),
        ),
        SizedBox(height: w * 0.05),
        Container(
          padding: EdgeInsets.all(w * 0.035),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(w * 0.035),
            border: Border.all(color: AppColors.border, width: 0.7),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(w * 0.03),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedFlag02,
                  color: AppColors.primary,
                  size: w * 0.05,
                ),
              ),
              SizedBox(width: w * 0.03),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      targetName,
                      style: TextStyle(
                        fontSize: w * 0.038,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (targetSubtitle.isNotEmpty) ...[
                      SizedBox(height: w * 0.006),
                      Text(
                        targetSubtitle,
                        style: TextStyle(
                            fontSize: w * 0.031,
                            color: AppColors.textSecondary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: w * 0.06),
        Text(
          'Description',
          style: TextStyle(
            fontSize: w * 0.036,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: w * 0.02),
        TextFormField(
          initialValue: description,
          maxLines: 5,
          onChanged: onDescriptionChanged,
          decoration: const InputDecoration(hintText: 'Tell us what happened…'),
        ),
        SizedBox(height: w * 0.01),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '${description.trim().length < 10 ? "Minimum 10 characters · " : ""}${description.length} chars',
            style: TextStyle(fontSize: w * 0.028, color: AppColors.textHint),
          ),
        ),
        SizedBox(height: w * 0.06),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Photo Evidence (optional)',
              style: TextStyle(
                fontSize: w * 0.038,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            if (photos.isNotEmpty)
              Text(
                '${photos.length}/$_maxPhotos',
                style: TextStyle(
                  fontSize: w * 0.032,
                  fontWeight: FontWeight.w600,
                  color: photos.length == _maxPhotos
                      ? AppColors.primary
                      : AppColors.textHint,
                ),
              ),
          ],
        ),
        SizedBox(height: w * 0.03),
        if (photos.isEmpty)
          _EmptyPhotoSlot(isPicking: isPickingPhotos, onTap: onAddPhotos, w: w)
        else
          _PhotoGrid(
            photos: photos,
            canAddMore: canAddMore,
            isPicking: isPickingPhotos,
            onAdd: onAddPhotos,
            onRemove: onRemovePhoto,
            w: w,
          ),
        SizedBox(height: w * 0.025),
        Container(
          padding:
              EdgeInsets.symmetric(horizontal: w * 0.04, vertical: w * 0.03),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(w * 0.025),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedInformationCircle,
                color: AppColors.textSecondary,
                size: w * 0.04,
              ),
              SizedBox(width: w * 0.025),
              Expanded(
                child: Text(
                  'Max $_maxPhotos photos',
                  style: TextStyle(
                      fontSize: w * 0.03,
                      color: AppColors.textSecondary,
                      height: 1.45),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyPhotoSlot extends StatelessWidget {
  final bool isPicking;
  final VoidCallback onTap;
  final double w;

  const _EmptyPhotoSlot(
      {required this.isPicking, required this.onTap, required this.w});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isPicking ? null : onTap,
      child: Container(
        height: w * 0.34,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(w * 0.04),
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        child: isPicking
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary))
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(w * 0.035),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedCamera01,
                      color: AppColors.primary,
                      size: w * 0.07,
                    ),
                  ),
                  SizedBox(height: w * 0.03),
                  Text(
                    'Tap to add photos',
                    style: TextStyle(
                      fontSize: w * 0.036,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _PhotoGrid extends StatelessWidget {
  final List<File> photos;
  final bool canAddMore;
  final bool isPicking;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;
  final double w;

  const _PhotoGrid({
    required this.photos,
    required this.canAddMore,
    required this.isPicking,
    required this.onAdd,
    required this.onRemove,
    required this.w,
  });

  @override
  Widget build(BuildContext context) {
    final tileSize = (w - w * 0.1 - w * 0.03 * 2) / 3;

    return Wrap(
      spacing: w * 0.03,
      runSpacing: w * 0.03,
      children: [
        for (int i = 0; i < photos.length; i++)
          _PhotoThumbnail(
              file: photos[i],
              index: i,
              size: tileSize,
              onRemove: onRemove,
              w: w),
        if (canAddMore)
          GestureDetector(
            onTap: isPicking ? null : onAdd,
            child: Container(
              width: tileSize,
              height: tileSize,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(w * 0.03),
                border: Border.all(color: AppColors.border),
              ),
              child: isPicking
                  ? const Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : HugeIcon(
                      icon: HugeIcons.strokeRoundedCamera01,
                      color: AppColors.primary,
                      size: w * 0.06,
                    ),
            ),
          ),
      ],
    );
  }
}

class _PhotoThumbnail extends StatelessWidget {
  final File file;
  final int index;
  final double size;
  final ValueChanged<int> onRemove;
  final double w;

  const _PhotoThumbnail({
    required this.file,
    required this.index,
    required this.size,
    required this.onRemove,
    required this.w,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(w * 0.03),
            child:
                Image.file(file, width: size, height: size, fit: BoxFit.cover),
          ),
          Positioned(
            top: -(w * 0.015),
            right: -(w * 0.015),
            child: GestureDetector(
              onTap: () => onRemove(index),
              child: Container(
                width: w * 0.065,
                height: w * 0.065,
                decoration: BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Icon(Icons.close_rounded,
                    color: Colors.white, size: w * 0.035),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
