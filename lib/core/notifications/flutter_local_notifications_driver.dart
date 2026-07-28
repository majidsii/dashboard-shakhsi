import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as timezone;

import 'local_notification_plugin_config.dart';
import 'local_notifications_driver.dart';
import 'native_notification_gateway.dart';

typedef NotificationPayloadHandler = void Function(String payload);

final class FlutterLocalNotificationsDriver
    implements LocalNotificationsDriver, NativeNotificationGateway {
  factory FlutterLocalNotificationsDriver({
    required LocalNotificationPluginConfig config,
    FlutterLocalNotificationsPlugin? plugin,
    NotificationPayloadHandler? onPayload,
  }) {
    return FlutterLocalNotificationsDriver._(
      config,
      plugin ?? FlutterLocalNotificationsPlugin(),
      onPayload,
    );
  }

  FlutterLocalNotificationsDriver._(
    this._config,
    this._plugin,
    this._onPayload,
  );

  final LocalNotificationPluginConfig _config;
  final FlutterLocalNotificationsPlugin _plugin;
  final NotificationPayloadHandler? _onPayload;

  static const NotificationDetails _notificationDetails = NotificationDetails(
    android: AndroidNotificationDetails(
      'dashboard_reminders',
      'یادآورها',
      channelDescription: 'یادآورهای تسک‌ها، عادت‌ها و برنامه‌های شخصی',
      importance: Importance.high,
      priority: Priority.high,
    ),
    macOS: DarwinNotificationDetails(),
    linux: LinuxNotificationDetails(),
    windows: WindowsNotificationDetails(),
  );

  @override
  Future<void> initialize() async {
    final darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    final settings = InitializationSettings(
      android: AndroidInitializationSettings(_config.androidDefaultIcon),
      macOS: darwin,
      linux: LinuxInitializationSettings(
        defaultActionName: _config.defaultActionName,
      ),
      windows: WindowsInitializationSettings(
        appName: _config.appName,
        appUserModelId: _config.appUserModelId,
        guid: _config.windowsGuid,
      ),
    );

    final initialized = await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null && payload.isNotEmpty) {
          _onPayload?.call(payload);
        }
      },
    );

    if (initialized == false) {
      throw StateError(
        'Local notifications plugin initialization returned false.',
      );
    }
  }

  @override
  Future<void> showNow({
    required int id,
    required String title,
    required String body,
    required String payload,
  }) {
    return _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: _notificationDetails,
      payload: payload,
    );
  }

  @override
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledAtUtc,
    required String payload,
  }) {
    return _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: timezone.TZDateTime.from(
        scheduledAtUtc.toUtc(),
        timezone.local,
      ),
      notificationDetails: _notificationDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: payload,
    );
  }

  @override
  Future<void> cancel(int id) {
    return _plugin.cancel(id: id);
  }

  @override
  Future<List<NativePendingNotification>> pending() async {
    final pending = await _plugin.pendingNotificationRequests();
    return pending
        .map(
          (item) =>
              NativePendingNotification(id: item.id, payload: item.payload),
        )
        .toList(growable: false);
  }
}
