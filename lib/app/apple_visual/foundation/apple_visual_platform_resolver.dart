import 'package:flutter/foundation.dart';

import 'apple_visual_family.dart';

abstract final class AppleVisualPlatformResolver {
  static AppleVisualFamily resolve(TargetPlatform platform) {
    return switch (platform) {
      TargetPlatform.android || TargetPlatform.iOS => AppleVisualFamily.ios27,
      TargetPlatform.windows ||
      TargetPlatform.linux ||
      TargetPlatform.macOS => AppleVisualFamily.macos27,
      TargetPlatform.fuchsia => AppleVisualFamily.ios27,
    };
  }
}
