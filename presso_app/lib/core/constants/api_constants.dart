class ApiConstants {
  ApiConstants._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.31.197:5181',
  );

  // Auth
  static const String login = '/api/auth/login';
  static const String refresh = '/api/auth/refresh';

  // Users
  static const String me = '/api/users/me';
  static const String fcmToken = '/api/users/me/fcm-token';
  static const String savings = '/api/users/savings';
  static const String studentVerify = '/api/users/student-verify';

  // Addresses
  static const String addresses = '/api/addresses';

  // Services
  static const String services = '/api/services';

  // Slots
  static const String slots = '/api/slots';

  // Orders
  static const String orders = '/api/orders';

  // Coins
  static const String coinsBalance = '/api/coins/balance';
  static const String coinsHistory = '/api/coins/history';

  // Referrals
  static const String referralCode = '/api/referrals/my-code';
  static const String referralApply = '/api/referrals/apply';
  static const String referralHistory = '/api/referrals/history';

  // Config
  static const String config = '/api/config';

  // Home
  static const String dailyMessage = '/api/home/daily-message';
  static const String aiTip = '/api/home/ai-tip';

  // Notifications
  static const String notifications = '/api/notifications';

  // Stores
  static const String stores = '/api/stores';
  static const String nearestStore = '/api/stores/nearest';

  // Service Zones
  static const String serviceZoneCheck = '/api/service-zones/check';
  static const String activeServiceZones = '/api/service-zones/active';
}
