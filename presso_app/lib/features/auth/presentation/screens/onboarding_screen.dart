import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:presso_app/core/constants/app_colors.dart';
import 'package:presso_app/core/widgets/presso_button.dart';

const _onboardingSeenKey = 'onboarding_seen';

class _OnboardingSlide {
  final IconData icon;
  final String title;
  final String body;

  const _OnboardingSlide({
    required this.icon,
    required this.title,
    required this.body,
  });
}

const _slides = [
  _OnboardingSlide(
    icon: Icons.local_shipping_outlined,
    title: 'Pickup from your door',
    body:
        'Schedule a slot. Our rider arrives at your address and picks up your laundry.',
  ),
  _OnboardingSlide(
    icon: Icons.camera_alt_outlined,
    title: 'Every garment photographed',
    body:
        'See proof of collection instantly. Your clothes are always safe and accounted for.',
  ),
  _OnboardingSlide(
    icon: Icons.auto_awesome_outlined,
    title: 'Fresh delivery + earn coins',
    body:
        'Delivered within 48 hours. Every order earns Presso Coins you can redeem later.',
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _markOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingSeenKey, true);
  }

  void _navigateToPhone() {
    _markOnboardingSeen();
    context.go('/auth/phone');
  }

  void _nextPage() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _navigateToPhone();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == _slides.length - 1;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Skip button ──
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _navigateToPhone,
                child: const Text(
                  'Skip',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ),
            ),

            // ── Slides ──
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return _SlideWidget(slide: slide);
                },
              ),
            ),

            // ── Page indicator ──
            AnimatedSmoothIndicator(
              activeIndex: _currentPage,
              count: _slides.length,
              effect: const ExpandingDotsEffect(
                dotColor: AppColors.surfaceLight,
                activeDotColor: AppColors.primary,
                dotWidth: 8,
                dotHeight: 6,
                spacing: 6,
                expansionFactor: 2.5,
              ),
            ),

            const SizedBox(height: 32),

            // ── CTA button ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: PressoButton(
                label: isLastPage ? 'Get Started →' : 'Next →',
                onPressed: _nextPage,
              ),
            ),

            const SizedBox(height: 12),

            // ── Skip text button ──
            TextButton(
              onPressed: _navigateToPhone,
              child: const Text(
                'Skip',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _SlideWidget extends StatelessWidget {
  final _OnboardingSlide slide;

  const _SlideWidget({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon container
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border, width: 0.8),
            ),
            alignment: Alignment.center,
            child: Icon(
              slide.icon,
              size: 44,
              color: AppColors.primary,
            ),
          ),

          const SizedBox(height: 36),

          // Title
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.3,
            ),
          ),

          const SizedBox(height: 12),

          // Body
          Text(
            slide.body,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
