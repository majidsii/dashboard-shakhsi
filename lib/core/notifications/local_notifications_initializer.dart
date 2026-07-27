import 'local_notifications_driver.dart';
import 'notification_time_zone_initializer.dart';

final class LocalNotificationsInitializer {
  factory LocalNotificationsInitializer({
    required NotificationTimeZoneInitializer timeZoneInitializer,
    required LocalNotificationsDriver driver,
  }) {
    return LocalNotificationsInitializer._(timeZoneInitializer, driver);
  }

  LocalNotificationsInitializer._(this._timeZoneInitializer, this._driver);

  final NotificationTimeZoneInitializer _timeZoneInitializer;
  final LocalNotificationsDriver _driver;

  Future<void>? _initialization;

  Future<void> initialize() {
    return _initialization ??= _initialize().catchError((Object error) {
      _initialization = null;
      throw error;
    });
  }

  Future<void> _initialize() async {
    await _timeZoneInitializer.initialize();
    await _driver.initialize();
  }
}
