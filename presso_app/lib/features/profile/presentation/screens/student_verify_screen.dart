import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/providers/app_config_provider.dart';
import '../../../../core/widgets/presso_button.dart';
import '../providers/profile_provider.dart';

class StudentVerifyScreen extends ConsumerStatefulWidget {
  const StudentVerifyScreen({super.key});

  @override
  ConsumerState<StudentVerifyScreen> createState() =>
      _StudentVerifyScreenState();
}

class _StudentVerifyScreenState extends ConsumerState<StudentVerifyScreen> {
  File? _selectedImage;
  final _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1200,
      );
      if (picked != null) {
        setState(() => _selectedImage = File(picked.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showPickerSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Select Photo', style: AppTextStyles.heading3),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.camera_alt_rounded,
                    color: AppColors.primary),
              ),
              title: const Text('Take a photo', style: AppTextStyles.body),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.purple.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child:
                    const Icon(Icons.photo_library_rounded, color: AppColors.purple),
              ),
              title: const Text('Choose from gallery', style: AppTextStyles.body),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a college ID photo first'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    await ref
        .read(profileProvider.notifier)
        .submitStudentVerification(_selectedImage!);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileProvider);
    final config = ref.watch(appConfigProvider);
    final discountPct = config.studentDiscountPercent;
    final submitted = state.studentVerifySubmitted;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Student Discount', style: AppTextStyles.heading2),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            // ── Benefits Section ──
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.purple.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.school_rounded,
                          color: AppColors.purple,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '$discountPct% off every order',
                        style: AppTextStyles.heading3.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Verified students get $discountPct% discount automatically applied on every order. One-time verification required.',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _BenefitRow(text: '$discountPct% off on all services'),
                  const SizedBox(height: 8),
                  _BenefitRow(text: 'Applied automatically at checkout'),
                  const SizedBox(height: 8),
                  _BenefitRow(text: 'Saves ≈ ₹15-30 per order'),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Upload Section ──
            if (!submitted) ...[
              Text(
                'UPLOAD COLLEGE ID',
                style: AppTextStyles.label.copyWith(
                  color: AppColors.textSecondary,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _showPickerSheet,
                child: Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _selectedImage != null
                          ? AppColors.green
                          : AppColors.border,
                      width: _selectedImage != null ? 1.5 : 0.8,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: _selectedImage != null
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.file(
                                _selectedImage!,
                                fit: BoxFit.cover,
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: GestureDetector(
                                  onTap: () =>
                                      setState(() => _selectedImage = null),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: AppColors.background.withOpacity(0.8),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close_rounded,
                                      color: AppColors.textPrimary,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : _UploadPlaceholder(),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Camera or gallery · JPG/PNG · max 5MB',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              PressoButton(
                label: 'Submit for Verification',
                onPressed: state.studentVerifyLoading ? null : _submit,
                isLoading: state.studentVerifyLoading,
              ),

              if (state.studentVerifyError != null) ...[
                const SizedBox(height: 12),
                Text(
                  state.studentVerifyError!,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.red,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ] else ...[
              // ── Under Review State ──
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: AppColors.green.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.green.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.hourglass_top_rounded,
                        color: AppColors.green,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Under review',
                      style: AppTextStyles.heading3.copyWith(
                        color: AppColors.green,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Expect decision within 24 hours.',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Data kept private.',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _BenefitRow extends StatelessWidget {
  final String text;

  const _BenefitRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '✓ ',
          style: TextStyle(
            color: AppColors.green,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _UploadPlaceholder extends StatelessWidget {
  const _UploadPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.border,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.add_a_photo_rounded,
            color: AppColors.textSecondary,
            size: 26,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Upload college ID photo',
          style: AppTextStyles.body.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Tap to select',
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textHint,
          ),
        ),
      ],
    );
  }
}
