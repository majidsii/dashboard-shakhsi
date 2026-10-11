final class AppleGlassShaderParameters {
  const AppleGlassShaderParameters({
    required this.saturation,
    required this.brightnessResponse,
    required this.distortionStrength,
    required this.depthResponse,
    required this.lightingResponse,
    required this.chromaticAberration,
    required this.customGlassRadius,
  });

  final double saturation;
  final double brightnessResponse;
  final double distortionStrength;
  final double depthResponse;
  final double lightingResponse;
  final double chromaticAberration;
  final double customGlassRadius;
}
