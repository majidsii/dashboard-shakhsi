import 'package:timezone/data/latest_all.dart' as timezone_data;
import 'package:timezone/timezone.dart' as timezone;

import 'device_time_zone_source.dart';

abstract interface class NotificationTimeZoneRuntime {
  void initializeDatabase();

  bool selectLocation(String name);
}

final class TimezonePackageRuntime implements NotificationTimeZoneRuntime {
  const TimezonePackageRuntime();

  @override
  void initializeDatabase() {
    timezone_data.initializeTimeZones();
  }

  @override
  bool selectLocation(String name) {
    try {
      timezone.setLocalLocation(timezone.getLocation(name));
      return true;
    } on timezone.LocationNotFoundException {
      return false;
    }
  }
}

final class NotificationTimeZoneInitializer {
  factory NotificationTimeZoneInitializer({
    required DeviceTimeZoneSource source,
    required NotificationTimeZoneRuntime runtime,
  }) {
    return NotificationTimeZoneInitializer._(source, runtime);
  }

  NotificationTimeZoneInitializer._(this._source, this._runtime);

  final DeviceTimeZoneSource _source;
  final NotificationTimeZoneRuntime _runtime;

  Future<String>? _initialization;

  Future<String> initialize() {
    return _initialization ??= _initialize().catchError((Object error) {
      _initialization = null;
      throw error;
    });
  }

  Future<String> _initialize() async {
    _runtime.initializeDatabase();

    final deviceLocation = await _source.localTimeZoneName();
    if (_runtime.selectLocation(deviceLocation)) {
      return deviceLocation;
    }

    const fallback = 'Etc/UTC';
    if (!_runtime.selectLocation(fallback)) {
      throw StateError('The Etc/UTC timezone is unavailable.');
    }
    return fallback;
  }
}
