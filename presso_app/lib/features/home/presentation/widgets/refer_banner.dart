import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

class ReferBanner extends StatefulWidget {
  final String referralCode;

  const ReferBanner({super.key, required this.referralCode});

  @override
  State<ReferBanner> createState() => _ReferBannerState();
}

class _ReferBannerState extends State<ReferBanner> {
  bool _copied = false;

  void _copyCode() {
    Clipboard.setData(ClipboardData(text: widget.referralCode));
    setState(() => _copied = true);
    Future.delayed(
      const Duration(seconds: 2),
      () => mounted ? setState(() => _copied = false) : null,
    );
  }

  void _shareCode() {
    final text = '''
Hey! I use Presso for laundry — it's amazing! 👕✨

Get fresh laundry delivered to your door.
Use my referral code and we both get ₹50 off!

Code: ${widget.referralCode}

Download Presso: https://presso.in/app
''';
    Share.share(text, subject: 'Try Presso Laundry — Get ₹50 off!');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.purple.withOpacity(0.3),
            AppColors.primaryDark.withOpacity(0.25),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.purple.withOpacity(0.35),
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          // Left content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('🎁', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 8),
                    Text(
                      'Invite friends',
                      style: AppTextStyles.heading3.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: 'Both of you get ',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const TextSpan(
                        text: '₹50',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.green,
                        ),
                      ),
                      TextSpan(
                        text: ' off on next order',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                // Referral code pill
                GestureDetector(
                  onTap: _copyCode,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.purpleLight.withOpacity(0.3),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.referralCode,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: _copied
                                ? AppColors.green
                                : AppColors.purpleLight,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          _copied
                              ? Icons.check_circle_outline_rounded
                              : Icons.copy_rounded,
                          size: 13,
                          color: _copied
                              ? AppColors.green
                              : AppColors.purpleLight,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Share button
          GestureDetector(
            onTap: _shareCode,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.purple,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.share_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Share',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
