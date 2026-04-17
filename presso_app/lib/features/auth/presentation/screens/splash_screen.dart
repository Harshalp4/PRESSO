import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:presso_app/core/constants/app_colors.dart';
import 'package:presso_app/features/auth/presentation/providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _logoScaleController;
  late final AnimationController _textFadeController;
  late final AnimationController _taglineFadeController;

  late final Animation<double> _logoScaleAnim;
  late final Animation<double> _textFadeAnim;
  late final Animation<double> _taglineFadeAnim;

  @override
  void initState() {
    super.initState();

    // Logo scale: 0.5 → 1.0, 600ms easeOut
    _logoScaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _logoScaleAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _logoScaleController, curve: Curves.easeOut),
    );

    // "Presso" text fades in after 400ms delay
    _textFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _textFadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textFadeController, curve: Curves.easeIn),
    );

    // Tagline fades in after 600ms delay
    _taglineFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _taglineFadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _taglineFadeController, curve: Curves.easeIn),
    );

    _runAnimations();
    _initializeAuth();
  }

  Future<void> _runAnimations() async {
    if (!mounted) return;
    _logoScaleController.forward();
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    _textFadeController.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    _taglineFadeController.forward();
  }

  Future<void> _initializeAuth() async {
    // Wait for animations to complete before deciding navigation
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;

    try {
      // Validate stored JWT against the API
      final authNotifier = ref.read(authProvider.notifier);
      await authNotifier.initialize();

      if (!mounted) return;

      final authState = ref.read(authProvider);

      if (authState.isAuthenticated) {
        // User has valid JWT — check if profile is complete
        if (authState.needsProfileSetup) {
          context.go('/auth/setup');
        } else {
          context.go('/home');
        }
      } else {
        context.go('/onboarding');
      }
    } catch (_) {
      if (!mounted) return;
      context.go('/onboarding');
    }
  }

  @override
  void dispose() {
    _logoScaleController.dispose();
    _textFadeController.dispose();
    _taglineFadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Center content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated logo
                ScaleTransition(
                  scale: _logoScaleAnim,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'P',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -1,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // "Presso" brand name
                FadeTransition(
                  opacity: _textFadeAnim,
                  child: const Text(
                    'Presso',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Tagline
                FadeTransition(
                  opacity: _taglineFadeAnim,
                  child: const Text(
                    'Fresh laundry, doorstep delivery',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.normal,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom progress indicator
          Positioned(
            bottom: 60,
            left: 80,
            right: 80,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: const LinearProgressIndicator(
                backgroundColor: AppColors.surfaceLight,
                valueColor:
                    AlwaysStoppedAnimation<Color>(AppColors.primary),
                minHeight: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
