class ApiConstants {
  // Use Mac's network IP — works for both physical devices and desktop
  static const String baseUrl = 'http://192.168.29.63:5181';

  // Auth
  static const String login = '/api/auth/login';
  static const String register = '/api/auth/register';

  // Users
  static const String usersMe = '/api/users/me';

  // Rider - Pickup Assignments
  static const String riderPickupAssignments = '/api/rider/pickup-assignments';
  static String riderPickupAssignment(String id) =>
      '/api/rider/pickup-assignments/$id';
  static String riderPickupAccept(String id) =>
      '/api/rider/pickup-assignments/$id/accept';
  static String riderPickupArrive(String id) =>
      '/api/rider/pickup-assignments/$id/arrive';
  static String riderPickupVerifyOtp(String id) =>
      '/api/rider/pickup-assignments/$id/verify-otp';
  static String riderPickupCollect(String id) =>
      '/api/rider/pickup-assignments/$id/collect';
  static String riderPickupComplete(String id) =>
      '/api/rider/pickup-assignments/$id/complete';
  static String riderPickupPhotos(String id) =>
      '/api/rider/pickup-assignments/$id/photos';

  // Rider - Delivery Assignments
  static const String riderDeliveryAssignments =
      '/api/rider/delivery-assignments';
  static String riderDeliveryAssignment(String id) =>
      '/api/rider/delivery-assignments/$id';
  static String riderDeliveryAccept(String id) =>
      '/api/rider/delivery-assignments/$id/accept';
  static String riderDeliveryArrive(String id) =>
      '/api/rider/delivery-assignments/$id/arrive';
  static String riderDeliveryVerifyOtp(String id) =>
      '/api/rider/delivery-assignments/$id/verify-otp';
  static String riderDeliveryComplete(String id) =>
      '/api/rider/delivery-assignments/$id/complete';

  // Rider - Earnings
  static const String riderEarnings = '/api/rider/earnings';

  // Facility
  static const String facilityOrders = '/api/facility/orders';
  static String facilityOrder(String id) => '/api/facility/orders/$id';
  static String facilityOrderStatus(String id) =>
      '/api/facility/orders/$id/status';
  static const String facilityScan = '/api/facility/scan';

  // Shared Preferences Keys
  static const String jwtTokenKey = 'jwt_token';
}
