import 'package:flutter/widgets.dart';

import 'apple_visual_family.dart';
import 'apple_visual_materials.dart';
import 'apple_visual_metrics.dart';
import 'apple_visual_motion.dart';
import 'apple_visual_tokens.dart';
import 'apple_visual_typography.dart';

class AppleVisualThemeData {
  const AppleVisualThemeData({
    required this.family,
    required this.brightness,
    required this.colors,
    required this.typography,
    required this.metrics,
    required this.materials,
    required this.motion,
  });

  final AppleVisualFamily family;
  final Brightness brightness;
  final AppleColorTokens colors;
  final AppleTypographyTokens typography;
  final AppleMetricTokens metrics;
  final AppleMaterialTokens materials;
  final AppleMotionTokens motion;

  bool get isResolved =>
      colors.isResolved &&
      typography.isResolved &&
      metrics.isResolved &&
      materials.isResolved &&
      motion.isResolved;
}
