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

// ── Thin helper that isolates Firebase imports ─────────────────────────────────

class _FirebaseHelper {
  static bool _initialized = false;

  static Future<bool> init() async {
    if (_initialized) return true;
    try {
      final firebaseCore = _FirebaseCore();
      await firebaseCore.initializeApp();
      _initialized = true;
      return true;
    } catch (e) {
      debugPrint('[Firebase] initializeApp failed: $e');
      return false;
    }
  }

  static Future<void> setupFcm() async {
    try {
      final fcm = _FcmHelper();
      await fcm.requestPermission();
      final token = await fcm.getToken();
      if (token != null) {
        debugPrint('[FCM] Token: ${token.substring(0, 10)}...');
      }
    } catch (e) {
      debugPrint('[FCM] setup failed: $e');
    }
  }
}

class _FirebaseCore {
  Future<void> initializeApp() async {
    const skipFirebase =
        bool.fromEnvironment('SKIP_FIREBASE', defaultValue: false);
    if (skipFirebase) {
      throw Exception('SKIP_FIREBASE is set');
    }
    await _doFirebaseInit();
  }
}

Future<void> _doFirebaseInit() async {
  try {
    final init = _getFirebaseInitializer();
    await init();
  } catch (e) {
    rethrow;
  }
}

typedef _AsyncVoidFn = Future<void> Function();

_AsyncVoidFn _getFirebaseInitializer() {
  return () async {
    // Replace with real Firebase init once firebase_options.dart is generated:
    // import 'package:firebase_core/firebase_core.dart';
    // import 'firebase_options.dart';
    // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    debugPrint('[Firebase] initializeApp placeholder — configure firebase_options.dart');
  };
}

class _FcmHelper {
  Future<void> requestPermission() async {
    // Uncomment when Firebase is configured:
    // import 'package:firebase_messaging/firebase_messaging.dart';
    // final messaging = FirebaseMessaging.instance;
    // await messaging.requestPermission(alert: true, badge: true, sound: true);
    debugPrint('[FCM] requestPermission placeholder');
  }

  Future<String?> getToken() async {
    // Uncomment when Firebase is configured:
    // import 'package:firebase_messaging/firebase_messaging.dart';
    // return FirebaseMessaging.instance.getToken();
    debugPrint('[FCM] getToken placeholder');
    return null;
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
