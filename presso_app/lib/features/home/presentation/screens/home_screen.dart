import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/token_storage.dart';
import '../../../../core/services/signalr_service.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import 'package:presso_app/features/auth/presentation/providers/auth_provider.dart';
import '../providers/home_provider.dart';
import 'package:presso_app/features/orders/presentation/providers/create_order_provider.dart';
import '../widgets/ai_greeting_card.dart';
import '../widgets/live_order_card.dart';
import '../widgets/services_strip.dart';
import '../widgets/quick_actions_row.dart';
import '../widgets/savings_strip.dart';
import '../widgets/loyalty_card.dart';
import '../widgets/offers_strip.dart';
import '../widgets/refer_banner.dart';
import '../widgets/how_it_works_section.dart';
import '../widgets/suvichar_card.dart';

// ─── GPS area name ───────────────────────────────────────────────────────────

final _gpsAreaProvider = FutureProvider<String?>((ref) async {
  try {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    if (permission == LocationPermission.deniedForever) return null;

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      ),
    );

    final placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );

    if (placemarks.isNotEmpty) {
      final p = placemarks.first;
      final parts = <String>[];
      if (p.subLocality != null && p.subLocality!.isNotEmpty) {
        parts.add(p.subLocality!);
      }
      if (p.locality != null && p.locality!.isNotEmpty) {
        parts.add(p.locality!);
      }
      if (parts.isNotEmpty) return parts.join(', ');
    }
  } catch (_) {}
  return null;
});

// ─── User name from SharedPreferences ─────────────────────────────────────────

final _userNameProvider = FutureProvider<String>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString('user_name') ?? '';
});

final _referralCodeProvider = Provider<String>((ref) {
  // Read from auth state directly — no SharedPreferences needed
  final authState = ref.watch(authProvider);
  final code = authState.user?.referralCode ?? '';
  return code.isNotEmpty ? code : 'PRESSO50';
});

// ─── Home screen ─────────────────────────────────────────────────────────────

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  // Cache the SignalR service so dispose() can remove the listener
  // without calling ref.read() (which throws after the widget is disposed).
  SignalRService? _signalRService;

  @override
  void initState() {
    super.initState();
    _connectSignalR();
  }

  Future<void> _connectSignalR() async {
    final storage = TokenStorage();
    final token = await storage.read('access_token');
    if (token == null || !mounted) return;

    final signalR = ref.read(signalRServiceProvider);
    _signalRService = signalR;
    await signalR.connect(token);
    if (!mounted) return;
    signalR.onNotification(_onSignalRNotification);
  }

  void _onSignalRNotification(Map<String, dynamic> notification) {
    if (!mounted) return;
    ref.invalidate(activeOrderProvider);
    ref.read(profileProvider.notifier).loadNotifications();

    final title = notification['title'] as String? ??
        notification['Title'] as String? ??
        'New notification';
    final body = notification['body'] as String? ??
        notification['Body'] as String? ??
        '';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            if (body.isNotEmpty)
              Text(body, style: const TextStyle(fontSize: 12)),
          ],
        ),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    // Use the cached reference — ref.read() is illegal after dispose.
    _signalRService?.removeListener(_onSignalRNotification);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(coinBalanceProvider);
    ref.watch(activeOrderProvider);
    final rawName = ref.watch(_userNameProvider).valueOrNull ?? '';
    final userName = rawName.isNotEmpty ? rawName.split(' ').first : 'there';
    final referralCode = ref.watch(_referralCodeProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              // ── App Bar ────────────────────────────────────────────────
              _HomeAppBar(userName: userName),

              // ── Cart banner (shows when draft has items) ───────────────
              _CartBanner(),

              // ── Scrollable content ─────────────────────────────────────
              Expanded(
                child: RefreshIndicator(
                  color: AppColors.primary,
                  backgroundColor: AppColors.surface,
                  onRefresh: () async {
                    ref.invalidate(_gpsAreaProvider);
                    ref.invalidate(activeOrderProvider);
                    ref.invalidate(coinBalanceProvider);
                    ref.invalidate(servicesListProvider);
                    ref.invalidate(userSavingsProvider);
                    ref.invalidate(dailyMessageProvider);
                    ref.invalidate(aiTipProvider);
                    await Future.delayed(const Duration(milliseconds: 600));
                  },
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),

                        // ── AI greeting / tip card ─────────────────────
                        const AiGreetingCard(),
                        const SizedBox(height: 12),

                        // ── Live order card (only if active) ───────────
                        const LiveOrderCard(),
                        _LiveOrderSpacer(),

                        // ── Services (horizontal scroll) ───────────────
                        const ServicesStrip(),
                        const SizedBox(height: 16),

                        // ── Quick Actions ──────────────────────────────
                        const QuickActionsRow(),
                        const SizedBox(height: 16),

                        // ── Savings strip ──────────────────────────────
                        const SavingsStrip(),
                        const SizedBox(height: 12),

                        // ── Loyalty / Coins card ───────────────────────
                        const LoyaltyCard(),
                        const SizedBox(height: 16),

                        // ── Offers ─────────────────────────────────────
                        // Temporarily hidden — flash-deal content is hard-
                        // coded demo data and confusing real users. Re-
                        // enable once the offers backend is wired up.
                        // const OffersStrip(),
                        // const SizedBox(height: 16),

                        // ── Refer a friend ─────────────────────────────
                        ReferBanner(referralCode: referralCode),
                        const SizedBox(height: 16),

                        // ── How it works ───────────────────────────────
                        const HowItWorksSection(),
                        const SizedBox(height: 16),

                        // Bottom padding (accounts for bottom nav bar)
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── App Bar — "Hi, Name! 👋" + coin badge + bell ──────────────────────────

class _HomeAppBar extends ConsumerWidget {
  final String userName;
  const _HomeAppBar({required this.userName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coinAsync = ref.watch(coinBalanceProvider);
    final notifCount = ref.watch(profileProvider).unreadCount;
    final coinBalance = coinAsync.valueOrNull?.balance ?? 0;

    // Build initials for avatar
    final fullName = ref.watch(authProvider).user?.name ?? userName;
    final initials = _buildInitials(fullName);

    // Get current GPS area name
    final gpsArea = ref.watch(_gpsAreaProvider);
    final areaName = gpsArea.valueOrNull;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.divider, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          // Location + greeting
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Area name row
                GestureDetector(
                  onTap: () => context.push('/profile/addresses'),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        color: AppColors.primary,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          areaName ?? 'Set your location',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppColors.textSecondary,
                        size: 18,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Hi, $userName! \u{1F44B}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Coin badge
          GestureDetector(
            onTap: () => context.push('/savings'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF9C3).withOpacity(0.5),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('\u{1F9E9}', style: TextStyle(fontSize: 13)),
                  const SizedBox(width: 4),
                  Text(
                    '$coinBalance',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFCA8A04),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 10),

          // Notification bell
          GestureDetector(
            onTap: () => context.push('/profile/notifications'),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Text('\u{1F514}', style: TextStyle(fontSize: 20)),
                if (notifCount > 0)
                  Positioned(
                    top: -4,
                    right: -4,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: AppColors.red,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.surface,
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          notifCount > 9 ? '9+' : notifCount.toString(),
                          style: const TextStyle(
                            fontSize: 7,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          // Profile avatar → opens profile/edit + logout
          GestureDetector(
            onTap: () => context.push('/profile'),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF0891B2), Color(0xFF0E7490)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0891B2).withOpacity(0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  initials,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _buildInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
}

// ─── Helper widget: conditional spacer after live order ──────────────────────

class _LiveOrderSpacer extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(activeOrderProvider);
    return orderAsync.maybeWhen(
      data: (order) =>
          order != null ? const SizedBox(height: 6) : const SizedBox.shrink(),
      orElse: () => const SizedBox.shrink(),
    );
  }
}

// ─── Cart banner — shows when user has items in draft order ──────────────────

class _CartBanner extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flowState = ref.watch(createOrderFlowProvider);
    final totalItems = flowState.totalItemCount;
    final subtotal = flowState.subtotal;
    final serviceCount = flowState.selectedServices.length;

    if (totalItems == 0 && serviceCount == 0) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => context.push('/order/garments'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(
                  Icons.shopping_bag_rounded,
                  color: Colors.white,
                  size: 24,
                ),
                if (totalItems > 0)
                  Positioned(
                    top: -6,
                    right: -8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        totalItems.toString(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    totalItems > 0
                        ? '$totalItems items \u{00B7} \u{20B9}${subtotal.toStringAsFixed(0)}'
                        : '$serviceCount service${serviceCount == 1 ? '' : 's'} selected',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    totalItems > 0 ? 'Continue your order' : 'Tap to add items',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
