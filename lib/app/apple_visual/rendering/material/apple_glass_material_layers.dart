final class AppleGlassSourceFillLayer {
  const AppleGlassSourceFillLayer({
    required this.index,
    required this.isEnabled,
    required this.colorHexArgb,
    required this.colorAlpha,
    required this.colorRed,
    required this.colorGreen,
    required this.colorBlue,
    required this.blendMode,
    required this.contextOpacity,
    required this.fillType,
    required this.layeringType,
    required this.noiseIndex,
    required this.noiseIntensity,
    required this.patternFillType,
    required this.patternTileScale,
  });

  final int index;
  final bool isEnabled;
  final String colorHexArgb;
  final double colorAlpha;
  final double colorRed;
  final double colorGreen;
  final double colorBlue;

  /// Raw source blend-mode identifier.
  ///
  /// Deliberately not mapped to Flutter BlendMode until the source semantics
  /// for each identifier are documented.
  final int blendMode;

  final double contextOpacity;
  final int fillType;
  final int layeringType;
  final int noiseIndex;
  final double noiseIntensity;
  final int patternFillType;
  final double patternTileScale;
}

final class AppleGlassSourceShadowLayer {
  const AppleGlassSourceShadowLayer({
    required this.index,
    required this.isEnabled,
    required this.colorHexArgb,
    required this.colorAlpha,
    required this.colorRed,
    required this.colorGreen,
    required this.colorBlue,
    required this.blendMode,
    required this.contextOpacity,
    required this.blurRadius,
    required this.offsetX,
    required this.offsetY,
    required this.spread,
  });

  final int index;
  final bool isEnabled;
  final String colorHexArgb;
  final double colorAlpha;
  final double colorRed;
  final double colorGreen;
  final double colorBlue;

  /// Raw source blend-mode identifier.
  ///
  /// Deliberately not mapped to Flutter BlendMode until the source semantics
  /// for each identifier are documented.
  final int blendMode;

  final double contextOpacity;
  final double blurRadius;
  final double offsetX;
  final double offsetY;
  final double spread;
}

final class AppleGlassSourceCornerSemantics {
  const AppleGlassSourceCornerSemantics({
    required this.prefersConcentric,
    required this.smoothing,
    required this.style,
    required this.radius,
  });

  final bool prefersConcentric;
  final double smoothing;
  final int style;

  /// Optional because the source tuple may omit an explicit radius while still
  /// providing corner style/smoothing semantics.
  final double? radius;
}

final class AppleGlassSourceMaterialLayers {
  const AppleGlassSourceMaterialLayers({
    required this.fills,
    required this.shadows,
    required this.corners,
  });

  final List<AppleGlassSourceFillLayer> fills;
  final List<AppleGlassSourceShadowLayer> shadows;
  final AppleGlassSourceCornerSemantics corners;
}
