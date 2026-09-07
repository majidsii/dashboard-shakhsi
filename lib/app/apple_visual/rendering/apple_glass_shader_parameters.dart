import 'package:flutter/foundation.dart';

@immutable
final class AppleGlassShaderParameters {
  const AppleGlassShaderParameters({
    required this.customGlassEnabled,
    required this.saturation,
    required this.brightness,
    required this.distortion,
    required this.depth,
    required this.chromaticAberration,
    required this.skipLightingEffects,
    required this.customGlassRadius,
  });

  final bool customGlassEnabled;
  final double saturation;
  final double brightness;
  final double distortion;
  final double depth;
  final double chromaticAberration;
  final bool skipLightingEffects;

  /// Source evidence only.
  /// No radius-to-sigma conversion belongs here.
  final double customGlassRadius;
}
