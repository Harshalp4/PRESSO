import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:presso_app/core/network/dio_client.dart';

class AppConfigState {
  final Map<String, String> _values;
  final bool isLoaded;

  const AppConfigState({
    Map<String, String>? values,
    this.isLoaded = false,
  }) : _values = values ?? const {};

  String? getString(String key) => _values[key];

  int getInt(String key, {int fallback = 0}) {
    final v = _values[key];
    if (v == null) return fallback;
    return int.tryParse(v) ?? fallback;
  }

  double getDouble(String key, {double fallback = 0.0}) {
    final v = _values[key];
    if (v == null) return fallback;
    return double.tryParse(v) ?? fallback;
  }

  bool getBool(String key, {bool fallback = false}) {
    final v = _values[key];
    if (v == null) return fallback;
    return v == 'true' || v == '1';
  }

  List<String> getStringList(String key) {
    final v = _values[key];
    if (v == null) return [];
    try {
      final list = jsonDecode(v) as List<dynamic>;
      return list.cast<String>();
    } catch (_) {
      return [];
    }
  }

  // Convenience getters
  double get coinValueRupees => getDouble('coin_value_rupees', fallback: 0.1);
  int get studentDiscountPercent => getInt('student_discount_percent', fallback: 20);
  double get expressCharge => getDouble('express_charge', fallback: 30.0);
  int get deliveryHoursStandard => getInt('delivery_hours_standard', fallback: 48);
  int get deliveryHoursSpecialty => getInt('delivery_hours_specialty', fallback: 72);
  int get deliveryHoursExpress => getInt('delivery_hours_express', fallback: 24);
  int get referralBonusCoins => getInt('referral_bonus_coins', fallback: 50);
  int get coinsEarnedPercent => getInt('coins_earned_percent', fallback: 5);
  int get minOrderItems => getInt('min_order_items', fallback: 3);
  int get loyaltyGoldThreshold => getInt('loyalty_gold_threshold', fallback: 500);
  int get loyaltyPlatinumThreshold => getInt('loyalty_platinum_threshold', fallback: 1500);
  int get loyaltyDiamondThreshold => getInt('loyalty_diamond_threshold', fallback: 3000);
  List<String> get serviceAreas => getStringList('service_areas');

  String getAiTip(String timeContext) {
    return getString('ai_tip_$timeContext') ?? 'Schedule a Presso pickup today!';
  }

  AppConfigState copyWith({Map<String, String>? values, bool? isLoaded}) {
    return AppConfigState(
      values: values ?? _values,
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }
}

class AppConfigNotifier extends StateNotifier<AppConfigState> {
  final Dio _dio;

  AppConfigNotifier(this._dio) : super(const AppConfigState()) {
    _loadFromCache();
    refresh();
  }

  static const _cacheKey = 'app_config_cache';

  Future<void> _loadFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_cacheKey);
    if (cached != null) {
      try {
        final map = (jsonDecode(cached) as Map<String, dynamic>)
            .map((k, v) => MapEntry(k, v.toString()));
        state = state.copyWith(values: map, isLoaded: true);
      } catch (_) {}
    }
  }

  Future<void> refresh() async {
    try {
      final response = await _dio.get('/api/config');
      if (response.statusCode == 200) {
        final body = response.data;
        Map<String, String>? data;
        if (body is Map<String, dynamic>) {
          final inner = body['data'];
          if (inner is Map<String, dynamic>) {
            data = inner.map((k, v) => MapEntry(k, v.toString()));
          }
        }
        if (data != null) {
          state = state.copyWith(values: data, isLoaded: true);
          // Cache
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_cacheKey, jsonEncode(data));
        }
      }
    } catch (_) {
      // Use cached/default values
    }
  }
}

final appConfigProvider =
    StateNotifierProvider<AppConfigNotifier, AppConfigState>((ref) {
  return AppConfigNotifier(ref.watch(dioProvider));
});
