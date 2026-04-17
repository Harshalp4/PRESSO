import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Firebase ──────────────────────────────────────────────────────────────
  try {
    await _initFirebase();
  } catch (e) {
    debugPrint('[main] Firebase init skipped: $e');
  }

  // ── System UI ─────────────────────────────────────────────────────────────
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(
    const ProviderScope(
      child: PressoApp(),
    ),
  );
}

/// Tries to initialise Firebase Core and request FCM permissions.
/// Wrapped in try/catch so the app still boots without a valid google-services
/// file (useful during early dev / CI).
Future<void> _initFirebase() async {
  await _tryFirebaseInit();
}

Future<void> _tryFirebaseInit() async {
  try {
    final firebase = await _FirebaseHelper.init();
    if (!firebase) return;
    await _FirebaseHelper.setupFcm();
  } catch (e) {
    debugPrint('[Firebase] init error: $e');
  }
}

// ── Firebase helpers ──────────────────────────────────────────────────────────

class _FirebaseHelper {
  static bool _initialized = false;

  static Future<bool> init() async {
    if (_initialized) return true;
    try {
      const skipFirebase =
          bool.fromEnvironment('SKIP_FIREBASE', defaultValue: false);
      if (skipFirebase) {
        debugPrint('[Firebase] SKIP_FIREBASE is set, skipping init');
        return false;
      }
      await Firebase.initializeApp();
      _initialized = true;
      debugPrint('[Firebase] initialized successfully');
      return true;
    } catch (e) {
      debugPrint('[Firebase] initializeApp failed: $e');
      return false;
    }
  }

  static Future<void> setupFcm() async {
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      final token = await messaging.getToken();
      if (token != null) {
        debugPrint('[FCM] Token: ${token.substring(0, 10)}...');
      }
    } catch (e) {
      debugPrint('[FCM] setup failed: $e');
    }
  }
}

// ── Root widget ────────────────────────────────────────────────────────────────

class PressoApp extends ConsumerWidget {
  const PressoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Presso',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
