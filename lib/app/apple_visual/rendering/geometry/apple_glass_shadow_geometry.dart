import 'dart:ui';

import '../material/apple_glass_material_layers.dart';
import 'apple_glass_applied_geometry.dart';

final class AppleGlassShadowGeometry {
  const AppleGlassShadowGeometry({
    required this.shape,
    required this.blurRadius,
  });

  final RSuperellipse shape;
  final double blurRadius;

  static AppleGlassShadowGeometry resolve({
    required AppleGlassAppliedGeometry geometry,
    required AppleGlassSourceShadowLayer shadow,
  }) {
    final spreadAdjusted = geometry.scaledShape.inflate(shadow.spread);
    final offsetShape = spreadAdjusted.shift(
      Offset(shadow.offsetX, shadow.offsetY),
    );

    if (!offsetShape.isFinite || offsetShape.hasNaN || offsetShape.isEmpty) {
      throw StateError(
        'Invalid Apple glass shadow geometry: '
        'index=${shadow.index} '
        'spread=${shadow.spread} '
        'offset=(${shadow.offsetX}, ${shadow.offsetY}).',
      );
    }

    return AppleGlassShadowGeometry(
      shape: offsetShape,
      blurRadius: shadow.blurRadius,
    );
  }
}
