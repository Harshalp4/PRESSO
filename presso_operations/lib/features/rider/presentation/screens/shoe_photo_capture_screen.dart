import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:presso_operations/core/constants/app_colors.dart';
import 'package:presso_operations/features/rider/data/rider_repository.dart';
import 'package:presso_operations/features/rider/domain/models/job_model.dart';

class ShoePhotoCaptureScreen extends ConsumerStatefulWidget {
  final String assignmentId;
  final List<ShoeItemModel> shoeItems;

  const ShoePhotoCaptureScreen({
    super.key,
    required this.assignmentId,
    required this.shoeItems,
  });

  @override
  ConsumerState<ShoePhotoCaptureScreen> createState() =>
      _ShoePhotoCaptureScreenState();
}

class _ShoePhotoCaptureScreenState
    extends ConsumerState<ShoePhotoCaptureScreen> {
  final ImagePicker _picker = ImagePicker();

  int _currentBagIndex = 0;
  bool _isUploading = false;

  // Per-bag photo storage: bagIndex -> { 'front': File?, 'back': File? }
  late List<Map<String, File?>> _bagPhotos;
  late List<Map<String, bool>> _bagUploadStatus;

  @override
  void initState() {
    super.initState();
    _bagPhotos = List.generate(
      widget.shoeItems.length,
      (_) => {'front': null, 'back': null},
    );
    _bagUploadStatus = List.generate(
      widget.shoeItems.length,
      (_) => {'front': false, 'back': false},
    );
  }

  ShoeItemModel get _currentItem => widget.shoeItems[_currentBagIndex];
  bool get _isLastBag => _currentBagIndex == widget.shoeItems.length - 1;

  int get _currentBagPhotoCount {
    final photos = _bagPhotos[_currentBagIndex];
    int count = 0;
    if (photos['front'] != null) count++;
    if (photos['back'] != null) count++;
    return count;
  }

  bool get _currentBagHasMinPhotos => _currentBagPhotoCount >= 1;

  bool get _currentBagIsUploaded {
    final status = _bagUploadStatus[_currentBagIndex];
    final photos = _bagPhotos[_currentBagIndex];
    if (photos['front'] != null && status['front'] != true) return false;
    if (photos['back'] != null && status['back'] != true) return false;
    return _currentBagHasMinPhotos;
  }

  Future<void> _capturePhoto(String slot) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      if (photo == null) return;

      final file = File(photo.path);
      setState(() {
        _bagPhotos[_currentBagIndex][slot] = file;
        _bagUploadStatus[_currentBagIndex][slot] = false;
      });

      await _uploadPhoto(file, slot);
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

  Future<void> _uploadPhoto(File file, String slot) async {
    setState(() => _isUploading = true);
    try {
      await ref.read(riderRepositoryProvider).uploadShoePhotos(
            widget.assignmentId,
            _currentItem.id,
            [file],
          );
      if (mounted) {
        setState(() {
          _bagUploadStatus[_currentBagIndex][slot] = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Failed to upload photo. Tap to retry.'),
            backgroundColor: AppColors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => _uploadPhoto(file, slot),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _nextBag() {
    if (_currentBagIndex < widget.shoeItems.length - 1) {
      setState(() => _currentBagIndex++);
    }
  }

  void _previousBag() {
    if (_currentBagIndex > 0) {
      setState(() => _currentBagIndex--);
    }
  }

  void _onContinue() {
    context.push('/rider/job/${widget.assignmentId}/garment-confirm');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF64748B)),
          onPressed: () {
            if (_currentBagIndex > 0) {
              _previousBag();
            } else {
              context.pop();
            }
          },
        ),
        title: const Text(
          'Shoe Photos',
          style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                'Bag ${_currentBagIndex + 1} of ${widget.shoeItems.length}',
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
          _buildBagProgressIndicator(),
          _buildBagInfoCard(),
          _buildInstructionCard(),
          Expanded(child: _buildPhotoSlots()),
          _buildActionButton(),
        ],
      ),
    );
  }

  Widget _buildBagProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: List.generate(widget.shoeItems.length, (index) {
          final isCompleted = _bagPhotos[index].values.any((f) => f != null) &&
              _bagUploadStatus[index].entries
                  .where((e) => _bagPhotos[index][e.key] != null)
                  .every((e) => e.value);
          final isCurrent = index == _currentBagIndex;

          return Expanded(
            child: Container(
              margin: EdgeInsets.only(
                right: index < widget.shoeItems.length - 1 ? 6 : 0,
              ),
              height: 4,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                color: isCompleted
                    ? AppColors.green
                    : isCurrent
                        ? AppColors.primary
                        : AppColors.surfaceLight,
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBagInfoCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.shopping_bag_outlined,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentItem.bagLabel ?? 'Bag ${_currentBagIndex + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _currentItem.shoeType ?? 'Shoe',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _currentBagHasMinPhotos
                  ? AppColors.green.withOpacity(0.15)
                  : AppColors.amber.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$_currentBagPhotoCount/2',
              style: TextStyle(
                color:
                    _currentBagHasMinPhotos ? AppColors.green : AppColors.amber,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
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
                Text(
                  'Photograph shoes front & back',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Capture clear photos of the front and back. At least 1 photo is required per bag.',
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

  Widget _buildPhotoSlots() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildPhotoSlot(
              slot: 'front',
              label: 'Front',
              icon: Icons.flip_to_front,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: _buildPhotoSlot(
              slot: 'back',
              label: 'Back',
              icon: Icons.flip_to_back,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoSlot({
    required String slot,
    required String label,
    required IconData icon,
  }) {
    final file = _bagPhotos[_currentBagIndex][slot];
    final isUploaded = _bagUploadStatus[_currentBagIndex][slot] == true;

    if (file != null) {
      return _buildCapturedSlot(file, slot, label, isUploaded);
    }
    return _buildEmptySlot(slot, label, icon);
  }

  Widget _buildEmptySlot(String slot, String label, IconData icon) {
    return GestureDetector(
      onTap: () => _capturePhoto(slot),
      child: AspectRatio(
        aspectRatio: 3 / 4,
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
              Icon(icon, color: AppColors.primary.withOpacity(0.7), size: 36),
              const SizedBox(height: 10),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tap to capture',
                style: TextStyle(
                  color: AppColors.primary.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCapturedSlot(
      File file, String slot, String label, bool isUploaded) {
    return GestureDetector(
      onTap: () => _capturePhoto(slot),
      child: AspectRatio(
        aspectRatio: 3 / 4,
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isUploaded
                      ? AppColors.green.withOpacity(0.5)
                      : AppColors.amber.withOpacity(0.5),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: Image.file(
                  file,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
              ),
            ),
            // Upload status badge
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isUploaded ? AppColors.green : AppColors.amber,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isUploaded ? Icons.check : Icons.upload,
                  color: Colors.white,
                  size: 14,
                ),
              ),
            ),
            // Label badge
            Positioned(
              bottom: 8,
              left: 8,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            // Retake hint
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh, color: Colors.white70, size: 12),
                    SizedBox(width: 3),
                    Text(
                      'Retake',
                      style: TextStyle(color: Colors.white70, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    final canProceed = _currentBagHasMinPhotos && !_isUploading;
    final buttonLabel = _isUploading
        ? 'Uploading...'
        : !_currentBagHasMinPhotos
            ? 'Take at least 1 photo'
            : _isLastBag
                ? 'Continue'
                : 'Next Bag';

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: canProceed
                ? () {
                    if (_isLastBag) {
                      _onContinue();
                    } else {
                      _nextBag();
                    }
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  buttonLabel,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
                if (canProceed && !_isLastBag) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, size: 20),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
