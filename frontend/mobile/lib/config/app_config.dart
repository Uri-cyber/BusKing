class AppConfig {
  // API Configuration
  static const String apiBaseUrl = 'http://localhost:3000/api/v1';
  static const String wsUrl = 'ws://localhost:3000/ws';

  // Production URLs (uncomment for production)
  // static const String apiBaseUrl = 'https://api.busalert.app/v1';
  // static const String wsUrl = 'wss://api.busalert.app/ws';

  // App Configuration
  static const String appName = 'BusAlert';
  static const String appVersion = '1.0.0';

  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String settingsKey = 'user_settings';

  // Feature Flags
  static const bool enableWebSocket = true;
  static const bool enablePushNotifications = true;
  static const bool enableGeofencing = true;

  // Timeouts
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration wsReconnectDelay = Duration(seconds: 5);

  // Pagination
  static const int defaultPageSize = 20;

  // Alert Settings
  static const List<int> alertMinutesOptions = [1, 2, 3, 5, 10, 15];
  static const int defaultAlertMinutes = 5;

  // Days of Week (Hebrew)
  static const Map<int, String> daysOfWeek = {
    0: 'ראשון',
    1: 'שני',
    2: 'שלישי',
    3: 'רביעי',
    4: 'חמישי',
    5: 'שישי',
    6: 'שבת',
  };
}
