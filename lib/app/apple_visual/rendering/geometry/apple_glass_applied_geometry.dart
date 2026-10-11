import 'dart:ui';

import 'package:flutter/widgets.dart' show EdgeInsets;

final class AppleGlassAppliedGeometry {
  const AppleGlassAppliedGeometry({
    required this.sourceFrameSize,
    required this.exportInsets,
    required this.materialRect,
    required this.sourceRadius,
    required this.scaledShape,
  });

  /// Concrete applied source-layer frame, not the golden export canvas.
  final Size sourceFrameSize;

  /// Effect-space expansion around the concrete source frame.
  ///
  /// For the first locked iOS small-control tuple this is source-backed by
  /// the enabled outer normal shadow:
  /// blur=15, offset=(0, 8), spread=0.
  final EdgeInsets exportInsets;

  /// Location of the source material body inside the export/effect canvas.
  final Rect materialRect;

  /// Raw finite source radius value. A Sketch max-radius sentinel is preserved
  /// here instead of being rewritten to an invented numeric radius.
  final double sourceRadius;

  /// Flutter's normalized continuous-corner primitive.
  ///
  /// RSuperellipse.scaleRadii() performs the geometry-constrained scaling;
  /// callers do not hard-code half-height or another replacement radius.
  final RSuperellipse scaledShape;
}
