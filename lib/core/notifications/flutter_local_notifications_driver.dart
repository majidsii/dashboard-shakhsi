import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'local_notification_plugin_config.dart';
import 'local_notifications_driver.dart';

typedef NotificationPayloadHandler = void Function(String payload);

final class FlutterLocalNotificationsDriver
    implements LocalNotificationsDriver {
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
}
