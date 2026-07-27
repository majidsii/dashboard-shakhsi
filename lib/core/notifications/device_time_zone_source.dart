import 'package:flutter_timezone/flutter_timezone.dart';

abstract interface class DeviceTimeZoneSource {
  Future<String> localTimeZoneName();
}

final class FlutterDeviceTimeZoneSource implements DeviceTimeZoneSource {
  const FlutterDeviceTimeZoneSource();

  @override
  Future<String> localTimeZoneName() async {
    final timezone = await FlutterTimezone.getLocalTimezone();
    return timezone.identifier;
  }
}
