import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../providers/home_provider.dart';

class SuvicharCard extends ConsumerWidget {
  const SuvicharCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messageAsync = ref.watch(dailyMessageProvider);

    return messageAsync.when(
      loading: () => _SuvicharShimmer(),
      error: (_, __) => _SuvicharContent(
        hindiText: fallbackSuvichars[DateTime.now().day % fallbackSuvichars.length].hindiText,
        englishText: fallbackSuvichars[DateTime.now().day % fallbackSuvichars.length].englishText,
      ),
      data: (message) => _SuvicharContent(
        hindiText: message.hindiText,
        englishText: message.englishText,
      ),
    );
  }
}

class _SuvicharContent extends StatelessWidget {
  final String hindiText;
  final String englishText;

  const _SuvicharContent({
    required this.hindiText,
    required this.englishText,
  });

  @override
  Widget build(BuildContext context) {
    final today = DateFormat('d MMM').format(DateTime.now());

    return GestureDetector(
      onTap: () => _shareThought(hindiText, englishText),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.5),
            width: 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                const Text(
                  '✨ Today\'s thought · AI generated',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary,
                    letterSpacing: 0.2,
                  ),
                ),
                const Spacer(),
                Text(
                  today,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Hindi text
            Text(
              hindiText,
              style: const TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: AppColors.textPrimary,
                height: 1.6,
                letterSpacing: 0.1,
              ),
            ),
            if (englishText.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                englishText,
                style: const TextStyle(
                  fontSize: 9,
                  color: AppColors.textSecondary,
                  height: 1.5,
                  letterSpacing: 0.1,
                ),
              ),
            ],
            const SizedBox(height: 10),
            // Tap to share hint
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(
                  Icons.share_outlined,
                  size: 13,
                  color: AppColors.textHint,
                ),
                const SizedBox(width: 4),
                Text(
                  'Tap to share',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textHint,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _shareThought(String hindi, String english) {
    final text = '✨ Thought of the day:\n\n$hindi\n\n$english\n\n— via Presso App';
    Share.share(text);
  }
}

class _SuvicharShimmer extends StatefulWidget {
  @override
  State<_SuvicharShimmer> createState() => _SuvicharShimmerState();
}

class _SuvicharShimmerState extends State<_SuvicharShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.5),
              width: 0.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _shimmerBox(width: 200, height: 12),
              const SizedBox(height: 12),
              _shimmerBox(width: double.infinity, height: 11),
              const SizedBox(height: 5),
              _shimmerBox(width: double.infinity, height: 11),
              const SizedBox(height: 5),
              _shimmerBox(width: 180, height: 11),
              const SizedBox(height: 8),
              _shimmerBox(width: 120, height: 9),
            ],
          ),
        );
      },
    );
  }

  Widget _shimmerBox({required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        gradient: LinearGradient(
          begin: Alignment(_animation.value - 1, 0),
          end: Alignment(_animation.value, 0),
          colors: const [
            AppColors.surfaceLight,
            Color(0xFF2A3A4A),
            AppColors.surfaceLight,
          ],
        ),
      ),
    );
  }
}
