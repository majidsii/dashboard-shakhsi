final class AppleLiquidGlassShaderParameters {
  const AppleLiquidGlassShaderParameters({
    required this.opacity,
    required this.blurRadius,
    required this.tintStrength,
    required this.specularStrength,
  });

  final double opacity;
  final double blurRadius;
  final double tintStrength;
  final double specularStrength;

  AppleLiquidGlassShaderParameters copyWith({
    double? opacity,
    double? blurRadius,
    double? tintStrength,
    double? specularStrength,
  }) {
    return AppleLiquidGlassShaderParameters(
      opacity: opacity ?? this.opacity,
      blurRadius: blurRadius ?? this.blurRadius,
      tintStrength: tintStrength ?? this.tintStrength,
      specularStrength: specularStrength ?? this.specularStrength,
    );
  }
}
