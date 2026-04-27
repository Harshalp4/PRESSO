import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../constants/api_constants.dart';
import '../config/env_config.dart';
import '../network/token_storage.dart';

class ErrorReporter {
  static final ErrorReporter _instance = ErrorReporter._();
  factory ErrorReporter() => _instance;
  ErrorReporter._();

  String? _appVersion;
  String? _platform;

  Future<void> init() async {
    try {
      final info = await PackageInfo.fromPlatform();
      _appVersion = '${info.version}+${info.buildNumber}';
    } catch (_) {
      _appVersion = 'unknown';
    }
    _platform = Platform.isAndroid ? 'android' : (Platform.isIOS ? 'ios' : 'other');
  }

  Future<void> report({
    required String error,
    String? stackTrace,
    String? screen,
    String severity = 'error',
  }) async {
    if (kDebugMode) {
      debugPrint('[ErrorReporter] $severity: $error');
      return; // Don't send in debug mode
    }

    try {
      final token = await TokenStorage().read('access_token');
      final dio = Dio(BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ));

      await dio.post('/api/error-logs', data: {
        'errorMessage': error.length > 2000 ? error.substring(0, 2000) : error,
        'stackTrace': stackTrace != null && stackTrace.length > 5000
            ? stackTrace.substring(0, 5000)
            : stackTrace,
        'screen': screen,
        'appVersion': _appVersion,
        'platform': _platform,
        'deviceInfo': '${Platform.operatingSystem} ${Platform.operatingSystemVersion}',
        'severity': severity,
      });
    } catch (_) {
      // Silently fail — don't cause more errors while reporting errors
    }
  }
}
