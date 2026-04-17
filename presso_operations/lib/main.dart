import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/app_colors.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/presso_ui.dart';
import 'features/rider/data/photo_upload_queue.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Allow both portrait and landscape so the app is usable on phones as well
  // as tablets (operations staff at facilities often use iPads).
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(
    const ProviderScope(
      child: PressoOperationsApp(),
    ),
  );
}

class PressoOperationsApp extends ConsumerWidget {
  const PressoOperationsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    // Keep the photo upload queue alive for the lifetime of the app so
    // background retries continue working even when the rider is off the
    // PhotoCaptureScreen.
    ref.watch(photoUploadQueueProvider);

    // Operations app is locked to the light Presso theme to match the
    // official mobile wireframes (Presso_Mobile_Wireframes.html).
    // Dark theme is intentionally NOT used for rider/facility — if the
    // device is in dark mode the app still renders light.
    AppColors.setBrightness(Brightness.light);

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    return MaterialApp.router(
      title: 'Presso Operations',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      themeMode: ThemeMode.light,
      routerConfig: router,
      // Global responsive frame: caps the whole app (including AppBar and
      // bottom nav) to a phone-shaped column on tablets/desktops. The
      // wireframes are designed for a ~400px phone, so rather than have
      // every individual screen stretch edge-to-edge on iPad (which makes
      // forms, cards and buttons look broken), the entire UI is centered
      // inside a readable max-width column with a soft gutter background.
      builder: (context, child) {
        if (child == null) return const SizedBox.shrink();
        final width = MediaQuery.of(context).size.width;
        // Below the tablet breakpoint, phones fill the screen as usual.
        if (width < PressoBreakpoints.tablet) return child;
        final cap = PressoBreakpoints.bodyMaxWidth(context);
        return ColoredBox(
          color: const Color(0xFFE2E8F0), // soft slate gutter
          child: Center(
            child: ClipRect(
              child: SizedBox(width: cap, child: child),
            ),
          ),
        );
      },
    );
  }
}
