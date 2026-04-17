import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    await Future.delayed(const Duration(milliseconds: 1200));

    if (!mounted) return;

    await ref.read(authProvider.notifier).checkAuth();

    if (!mounted) return;

    final state = ref.read(authProvider);

    if (state.isAuthenticated) {
      _navigateByRole(state.role);
    } else {
      context.go('/login');
    }
  }

  void _navigateByRole(String? role) {
    switch (role) {
      case 'Rider':
        context.go('/rider/dashboard');
        break;
      case 'FacilityStaff':
        context.go('/facility/dashboard');
        break;
      default:
        context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Center(
                child: Text(
                  'P',
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w800,
                    color: AppColors.background,
                    letterSpacing: -1,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Presso Operations',
              style: AppTextStyles.heading2.copyWith(
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 40),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
