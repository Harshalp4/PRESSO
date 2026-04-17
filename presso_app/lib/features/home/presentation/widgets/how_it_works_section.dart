import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

class HowItWorksSection extends StatelessWidget {
  const HowItWorksSection({super.key});

  @override
  Widget build(BuildContext context) {
    const steps = [
      _HowItWorksStep(
        number: '1',
        title: 'Schedule Pickup',
        description: 'Choose a convenient slot and we\'ll come to your door.',
        icon: Icons.schedule_rounded,
        color: AppColors.primary,
      ),
      _HowItWorksStep(
        number: '2',
        title: 'We Clean & Press',
        description: 'Your clothes are washed, dried, and perfectly pressed.',
        icon: Icons.local_laundry_service_outlined,
        color: AppColors.purple,
      ),
      _HowItWorksStep(
        number: '3',
        title: 'Delivery to Door',
        description: 'Fresh, folded clothes delivered back within 24–48 hours.',
        icon: Icons.local_shipping_outlined,
        color: AppColors.green,
      ),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How it works',
            style: AppTextStyles.heading3.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          ...steps.asMap().entries.map((entry) {
            final index = entry.key;
            final step = entry.value;
            return Column(
              children: [
                _StepRow(step: step),
                if (index < steps.length - 1) ...[
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(left: 20),
                    child: Container(
                      width: 1.5,
                      height: 16,
                      color: AppColors.border,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _HowItWorksStep {
  final String number;
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const _HowItWorksStep({
    required this.number,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}

class _StepRow extends StatelessWidget {
  final _HowItWorksStep step;

  const _StepRow({required this.step});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Number circle
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: step.color.withOpacity(0.12),
            shape: BoxShape.circle,
            border: Border.all(
              color: step.color.withOpacity(0.3),
              width: 0.8,
            ),
          ),
          child: Center(
            child: Text(
              step.number,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: step.color,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Text
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(step.icon, size: 14, color: step.color),
                  const SizedBox(width: 5),
                  Text(
                    step.title,
                    style: AppTextStyles.body.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                step.description,
                style: AppTextStyles.bodySmall.copyWith(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
