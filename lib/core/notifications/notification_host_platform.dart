import 'package:flutter/foundation.dart';

import 'notification_platform_capabilities.dart';

NotificationHostPlatform detectNotificationHostPlatform({
  required bool isWeb,
  required TargetPlatform platform,
}) {
  if (isWeb) {
    return NotificationHostPlatform.unsupported;
  }

  return switch (platform) {
    TargetPlatform.android => NotificationHostPlatform.android,
    TargetPlatform.linux => NotificationHostPlatform.linux,
    TargetPlatform.macOS => NotificationHostPlatform.macos,
    TargetPlatform.windows => NotificationHostPlatform.windows,
    TargetPlatform.iOS ||
    TargetPlatform.fuchsia => NotificationHostPlatform.unsupported,
  };
}
