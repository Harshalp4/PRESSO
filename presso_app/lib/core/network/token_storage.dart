import 'dart:io' show Platform;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Platform-aware token storage.
/// Uses SharedPreferences on macOS (keychain has entitlement issues in dev)
/// and FlutterSecureStorage on iOS/Android.
class TokenStorage {
  static final TokenStorage _instance = TokenStorage._();
  factory TokenStorage() => _instance;
  TokenStorage._();

  final bool _usePlainStorage = Platform.isMacOS;

  final FlutterSecureStorage _secure = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  Future<String?> read(String key) async {
    if (_usePlainStorage) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('_ts_$key');
    }
    return _secure.read(key: key);
  }

  Future<void> write(String key, String value) async {
    if (_usePlainStorage) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('_ts_$key', value);
      return;
    }
    await _secure.write(key: key, value: value);
  }

  Future<void> delete(String key) async {
    if (_usePlainStorage) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('_ts_$key');
      return;
    }
    await _secure.delete(key: key);
  }
}
