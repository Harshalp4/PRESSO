// Photo capture screen — offline-first.
//
// Captured photos are copied into the app documents dir and pushed onto the
// PhotoUploadQueue (see photo_upload_queue.dart). Uploads run in a serial
// background processor that retries on connectivity. The rider is NOT
// blocked on upload — they can take all their photos and hit Continue, and
// the queue will finish uploading in the background while they move through
// the rest of the pickup flow.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:presso_operations/core/constants/app_colors.dart';
import 'package:presso_operations/features/rider/data/photo_upload_queue.dart';

class PhotoCaptureScreen extends ConsumerStatefulWidget {
  final String assignmentId;

  const PhotoCaptureScreen({super.key, required this.assignmentId});

  @override
  ConsumerState<PhotoCaptureScreen> createState() => _PhotoCaptureScreenState();
}

class _PhotoCaptureScreenState extends ConsumerState<PhotoCaptureScreen> {
  final ImagePicker _picker = ImagePicker();

  static const int _maxPhotos = 9;

  Future<void> _capturePhoto() async {
    try {
      final XFile? photo =
          await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
      if (photo == null) return;

      await ref
          .read(photoUploadQueueProvider.notifier)
          .enqueue(widget.assignmentId, File(photo.path));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to capture photo: $e'),
            backgroundColor: AppColors.red,
          ),
        );
      }
    }
  }

  void _retry(String id) {
    ref.read(photoUploadQueueProvider.notifier).retry(id);
  }

  @override
  Widget build(BuildContext context) {
    final allQueued = ref.watch(photoUploadQueueProvider);
    final queued = allQueued
        .where((p) => p.assignmentId == widget.assignmentId)
        .toList();
    final uploadedCount =
        queued.where((p) => p.status == QueuedPhotoStatus.uploaded).length;
    final pendingCount = queued
        .where((p) =>
            p.status == QueuedPhotoStatus.pending ||
            p.status == QueuedPhotoStatus.uploading)
        .length;
    final failedCount =
        queued.where((p) => p.status == QueuedPhotoStatus.failed).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF64748B)),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Photograph Items',
          style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '${queued.length}/$_maxPhotos',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildInstructionCard(),
          if (queued.isNotEmpty)
            _buildStatusBanner(
              uploaded: uploadedCount,
              pending: pendingCount,
              failed: failedCount,
              total: queued.length,
            ),
          Expanded(child: _buildPhotoGrid(queued)),
          _buildContinueButton(queued.length, pendingCount, failedCount),
        ],
      ),
    );
  }

  Widget _buildInstructionCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.camera_alt_outlined,
              color: AppColors.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Photograph all garments',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Photos upload in the background — you can continue even if '
                  "you're offline. We'll retry until they land.",
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBanner({
    required int uploaded,
    required int pending,
    required int failed,
    required int total,
  }) {
    final progress = total == 0 ? 0.0 : uploaded / total;
    String label;
    Color color;
    if (failed > 0 && pending == 0) {
      label = '$failed failed · tap a photo to retry';
      color = AppColors.red;
    } else if (pending > 0) {
      label = '$uploaded of $total uploaded · $pending queued';
      color = AppColors.primary;
    } else {
      label = 'All $total photos uploaded';
      color = AppColors.green;
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: color, fontSize: 12),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.surfaceLight,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildPhotoGrid(List<QueuedPhoto> queued) {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount:
          (queued.length < _maxPhotos) ? queued.length + 1 : queued.length,
      itemBuilder: (context, index) {
        if (index == queued.length && queued.length < _maxPhotos) {
          return _buildCameraSlot();
        }
        return _buildPhotoThumbnail(queued[index], index);
      },
    );
  }

  Widget _buildCameraSlot() {
    return GestureDetector(
      onTap: _capturePhoto,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.4),
            width: 1.5,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.camera_alt,
              color: AppColors.primary.withOpacity(0.7),
              size: 32,
            ),
            const SizedBox(height: 6),
            Text(
              'Tap to capture',
              style: TextStyle(
                color: AppColors.primary.withOpacity(0.7),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoThumbnail(QueuedPhoto photo, int index) {
    Color borderColor;
    Color badgeColor;
    IconData badgeIcon;
    switch (photo.status) {
      case QueuedPhotoStatus.uploaded:
        borderColor = AppColors.green.withOpacity(0.6);
        badgeColor = AppColors.green;
        badgeIcon = Icons.check;
        break;
      case QueuedPhotoStatus.uploading:
        borderColor = AppColors.primary.withOpacity(0.6);
        badgeColor = AppColors.primary;
        badgeIcon = Icons.cloud_upload;
        break;
      case QueuedPhotoStatus.failed:
        borderColor = AppColors.red.withOpacity(0.6);
        badgeColor = AppColors.red;
        badgeIcon = Icons.refresh;
        break;
      case QueuedPhotoStatus.pending:
        borderColor = AppColors.amber.withOpacity(0.6);
        badgeColor = AppColors.amber;
        badgeIcon = Icons.schedule;
        break;
    }

    return GestureDetector(
      onTap: photo.status == QueuedPhotoStatus.failed
          ? () => _retry(photo.id)
          : null,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: Image.file(
                File(photo.localPath),
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (_, _, _) => Container(
                  color: AppColors.surfaceLight,
                  child: Icon(Icons.broken_image,
                      color: AppColors.textSecondary),
                ),
              ),
            ),
          ),
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: badgeColor,
                shape: BoxShape.circle,
              ),
              child: Icon(badgeIcon, color: Colors.white, size: 14),
            ),
          ),
          Positioned(
            bottom: 6,
            left: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueButton(int total, int pending, int failed) {
    // Allow Continue as soon as there is at least 1 captured photo — uploads
    // run in the background via the queue, the rider shouldn't wait.
    final canContinue = total > 0;
    String label;
    if (total == 0) {
      label = 'Take at least 1 photo';
    } else if (pending > 0) {
      label = 'Continue ($pending uploading)';
    } else if (failed > 0) {
      label = 'Continue ($failed will retry)';
    } else {
      label = 'Continue';
    }
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: canContinue
                ? () {
                    context.push(
                      '/rider/job/${widget.assignmentId}/garment-confirm',
                      extra: total,
                    );
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.primary.withOpacity(0.3),
              disabledForegroundColor: Colors.white.withOpacity(0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              label,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }
}
