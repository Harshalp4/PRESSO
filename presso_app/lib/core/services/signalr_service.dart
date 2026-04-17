import 'dart:developer' as dev;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signalr_netcore/signalr_client.dart';
import 'package:presso_app/core/constants/api_constants.dart';

typedef NotificationCallback = void Function(Map<String, dynamic> notification);

class SignalRService {
  HubConnection? _hub;
  final List<NotificationCallback> _listeners = [];
  bool _isConnecting = false;

  Future<void> connect(String token) async {
    if (_hub != null || _isConnecting) return;
    _isConnecting = true;

    try {
      final hubUrl = '${ApiConstants.baseUrl}/hubs/notifications?access_token=$token';

      _hub = HubConnectionBuilder()
          .withUrl(hubUrl)
          .withAutomaticReconnect()
          .build();

      _hub!.on('ReceiveNotification', (arguments) {
        if (arguments == null || arguments.isEmpty) return;
        final data = arguments[0];
        if (data is Map<String, dynamic>) {
          for (final cb in _listeners) {
            cb(data);
          }
        }
      });

      await _hub!.start();
      dev.log('[SignalR] Connected to notification hub', name: 'SIGNALR');
    } catch (e) {
      dev.log('[SignalR] Connection failed: $e', name: 'SIGNALR');
      _hub = null;
    } finally {
      _isConnecting = false;
    }
  }

  void onNotification(NotificationCallback callback) {
    _listeners.add(callback);
  }

  void removeListener(NotificationCallback callback) {
    _listeners.remove(callback);
  }

  Future<void> disconnect() async {
    try {
      await _hub?.stop();
    } catch (_) {}
    _hub = null;
    _listeners.clear();
  }

  bool get isConnected => _hub?.state == HubConnectionState.Connected;
}

final signalRServiceProvider = Provider<SignalRService>((ref) {
  final service = SignalRService();
  ref.onDispose(() => service.disconnect());
  return service;
});
