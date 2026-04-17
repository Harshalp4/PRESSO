import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/providers/app_config_provider.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    final config = ref.watch(appConfigProvider);
    final goldT = config.loyaltyGoldThreshold;
    final platT = config.loyaltyPlatinumThreshold;

    final initials = _getInitials(user?.name ?? user?.phone ?? '?');
    final coins = user?.coinBalance ?? 0;
    final coinRate = config.coinValueRupees; // from DB (default 0.1)
    final coinsValue = (coins * coinRate).toStringAsFixed(0);
    final isGold = coins >= goldT;
    final isPlatinum = coins >= platT;
    final tierName = isPlatinum ? 'PLATINUM' : (isGold ? 'GOLD' : 'SILVER');
    final tierColor = isPlatinum
        ? AppColors.primary
        : (isGold ? AppColors.amber : AppColors.textSecondary);
    final coinsToNext = isPlatinum ? 0 : (isGold ? platT - coins : goldT - coins);
    final nextTierName = isPlatinum ? '' : (isGold ? 'Platinum' : 'Gold');
    final tierProgress = isPlatinum
        ? 1.0
        : (isGold
            ? (coins - goldT) / (platT - goldT)
            : coins / goldT.toDouble());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Profile', style: AppTextStyles.heading2),
        actions: [
          TextButton(
            onPressed: () => _showEditDialog(context, ref),
            child: Text(
              'Edit',
              style: AppTextStyles.body.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            // ── Avatar + Name ──
            Center(
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.primaryDark, AppColors.purple],
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?.name ?? 'User',
                    style: AppTextStyles.heading2.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '+91${user?.phone ?? ''}',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Coins Card ──
            Container(
              padding: const EdgeInsets.all(16),
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
                      const Text('🪙', style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      const Text(
                        'Presso Coins',
                        style: AppTextStyles.heading3,
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: tierColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: tierColor.withOpacity(0.4), width: 0.8),
                        ),
                        child: Text(
                          tierName,
                          style: AppTextStyles.caption.copyWith(
                            color: tierColor,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$coins',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Text(
                          'coins',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          '≈ ₹$coinsValue',
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.green,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (!isPlatinum) ...[
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: tierProgress.clamp(0.0, 1.0),
                        backgroundColor: AppColors.border,
                        valueColor: AlwaysStoppedAnimation(tierColor),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$coinsToNext coins to $nextTierName',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Settings List ──
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                children: [
                  _SettingsTile(
                    icon: Icons.location_on_rounded,
                    iconColor: AppColors.primary,
                    label: 'Saved addresses',
                    trailingValue: '2 saved',
                    onTap: () => context.push('/profile/addresses'),
                  ),
                  const _Divider(),
                  _SettingsTile(
                    icon: Icons.school_rounded,
                    iconColor: AppColors.purple,
                    label: 'Student discount',
                    trailingValue: (user?.isStudentVerified ?? false)
                        ? 'Verified ✓'
                        : 'Verify',
                    trailingColor: (user?.isStudentVerified ?? false)
                        ? AppColors.green
                        : AppColors.primary,
                    onTap: () => context.push('/profile/student-verify'),
                  ),
                  const _Divider(),
                  _SettingsTile(
                    icon: Icons.notifications_rounded,
                    iconColor: AppColors.amber,
                    label: 'Notifications',
                    trailingValue: 'On',
                    onTap: () => context.push('/profile/notifications'),
                  ),
                  const _Divider(),
                  _SettingsTile(
                    icon: Icons.help_outline_rounded,
                    iconColor: AppColors.primary,
                    label: 'Help & Support',
                    onTap: () {},
                  ),
                  const _Divider(),
                  _SettingsTile(
                    icon: Icons.info_outline_rounded,
                    iconColor: AppColors.textSecondary,
                    label: 'About Presso',
                    trailingValue: 'v1.0',
                    onTap: () {},
                  ),
                  const _Divider(),
                  _SettingsTile(
                    icon: Icons.logout_rounded,
                    iconColor: AppColors.red,
                    label: 'Logout',
                    labelColor: AppColors.red,
                    onTap: () => _confirmLogout(context, ref),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  void _showEditDialog(BuildContext context, WidgetRef ref) {
    final user = ref.read(authProvider).user;
    final nameController = TextEditingController(text: user?.name ?? '');
    final emailController = TextEditingController(text: user?.email ?? '');

    showDialog(
      context: context,
      builder: (ctx) => _EditProfileDialog(
        nameController: nameController,
        emailController: emailController,
        onSave: (name, email) async {
          final success = await ref.read(authProvider.notifier).updateProfile(
            name: name.isNotEmpty ? name : null,
            email: email.isNotEmpty ? email : null,
          );
          if (ctx.mounted) Navigator.pop(ctx);
          if (!success && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to update profile'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
      ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Logout', style: AppTextStyles.heading3),
        content: Text(
          'Are you sure you want to logout?',
          style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/auth/phone');
            },
            child: Text(
              'Logout',
              style: AppTextStyles.button.copyWith(color: AppColors.red),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditProfileDialog extends StatefulWidget {
  final TextEditingController nameController;
  final TextEditingController emailController;
  final Future<void> Function(String name, String email) onSave;

  const _EditProfileDialog({
    required this.nameController,
    required this.emailController,
    required this.onSave,
  });

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: const Text('Edit Profile', style: AppTextStyles.heading3),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: widget.nameController,
            style: const TextStyle(color: AppColors.textPrimary),
            cursorColor: AppColors.primary,
            decoration: InputDecoration(
              labelText: 'Name',
              labelStyle: const TextStyle(color: AppColors.textSecondary),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: widget.emailController,
            style: const TextStyle(color: AppColors.textPrimary),
            cursorColor: AppColors.primary,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'Email',
              labelStyle: const TextStyle(color: AppColors.textSecondary),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _saving
              ? null
              : () async {
                  setState(() => _saving = true);
                  await widget.onSave(
                    widget.nameController.text.trim(),
                    widget.emailController.text.trim(),
                  );
                },
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  'Save',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final Color? labelColor;
  final String? trailingValue;
  final Color? trailingColor;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    this.labelColor,
    this.trailingValue,
    this.trailingColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.body.copyWith(
                    color: labelColor ?? AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (trailingValue != null) ...[
                Text(
                  trailingValue!,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: trailingColor ?? AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 4),
              ],
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textHint,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 0.5,
      margin: const EdgeInsets.only(left: 66),
      color: AppColors.divider,
    );
  }
}
