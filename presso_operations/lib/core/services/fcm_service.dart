import 'dart:developer' as dev;

/// FCM service placeholder for the operations app.
/// Requires Firebase to be configured (google-services.json / GoogleService-Info.plist).
/// Once configured:
/// 1. Add firebase_core + firebase_messaging to pubspec.yaml
/// 2. Run `flutterfire configure`
/// 3. Initialize Firebase in main.dart
/// 4. Uncomment the real implementation below and send token via
///    PATCH /api/riders/me/fcm-token

class FcmService {
  String? _currentToken;

  String? get currentToken => _currentToken;

  Future<void> initialize() async {
    // TODO: Uncomment when Firebase is configured
    // final messaging = FirebaseMessaging.instance;
    // await messaging.requestPermission(alert: true, badge: true, sound: true);
    // _currentToken = await messaging.getToken();
    // messaging.onTokenRefresh.listen((token) => _currentToken = token);
    dev.log('[FCM] Operations FCM placeholder — configure Firebase first', name: 'FCM');
  }
}
