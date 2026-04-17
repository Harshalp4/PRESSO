import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ApiEnvironment {
  local('Local', 'http://192.168.29.63:5181'),
  render('Render', 'https://presso-3ggb.onrender.com');

  final String label;
  final String url;
  const ApiEnvironment(this.label, this.url);
}

class EnvConfigNotifier extends StateNotifier<ApiEnvironment> {
  static const _key = 'api_environment';

  EnvConfigNotifier() : super(ApiEnvironment.render) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    if (saved == 'local') {
      state = ApiEnvironment.local;
    } else {
      state = ApiEnvironment.render;
    }
  }

  Future<void> toggle() async {
    final next = state == ApiEnvironment.local
        ? ApiEnvironment.render
        : ApiEnvironment.local;
    state = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, next.name);
  }
}

final envConfigProvider =
    StateNotifierProvider<EnvConfigNotifier, ApiEnvironment>(
  (ref) => EnvConfigNotifier(),
);
