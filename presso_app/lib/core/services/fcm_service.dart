import 'dart:developer' as dev;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef FcmNotificationCallback = void Function(RemoteMessage message);

class FcmService {
  final List<FcmNotificationCallback> _foregroundListeners = [];
  String? _currentToken;
  bool _initialized = false;

  String? get currentToken => _currentToken;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    try {
      // Request permission
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      dev.log('[FCM] Permission: ${settings.authorizationStatus}', name: 'FCM');

      // Get token
      _currentToken = await FirebaseMessaging.instance.getToken();
      dev.log('[FCM] Token: ${_currentToken?.substring(0, 10) ?? "null"}...', name: 'FCM');

      // Listen for token refresh
      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        _currentToken = newToken;
        dev.log('[FCM] Token refreshed', name: 'FCM');
      });

      // Foreground messages
      FirebaseMessaging.onMessage.listen((message) {
        dev.log('[FCM] Foreground message: ${message.notification?.title}', name: 'FCM');
        for (final cb in _foregroundListeners) {
          cb(message);
        }
      });

      // App opened from notification
      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        dev.log('[FCM] Opened from notification: ${message.data}', name: 'FCM');
        // Navigation would be handled by the listener
        for (final cb in _foregroundListeners) {
          cb(message);
        }
      });
    } catch (e) {
      dev.log('[FCM] Init failed: $e', name: 'FCM');
    }
  }

  void onMessage(FcmNotificationCallback callback) {
    _foregroundListeners.add(callback);
  }

  void removeListener(FcmNotificationCallback callback) {
    _foregroundListeners.remove(callback);
  }
}

final fcmServiceProvider = Provider<FcmService>((ref) {
  return FcmService();
});
