import 'dart:math' as math;
import 'dart:ui';

enum AppleGlassSourceBlendMode {
  normal(0),
  darken(1),
  multiply(2),
  colorBurn(3),
  lighten(4),
  screen(5),
  colorDodge(6),
  overlay(7),
  softLight(8),
  hardLight(9),
  difference(10),
  exclusion(11),
  hue(12),
  saturation(13),
  color(14),
  luminosity(15),
  plusDarker(16),
  plusLighter(17);

  const AppleGlassSourceBlendMode(this.rawValue);

  final int rawValue;

  static AppleGlassSourceBlendMode fromRawValue(int value) {
    return values.singleWhere(
      (mode) => mode.rawValue == value,
      orElse: () =>
          throw StateError('Unsupported Sketch blend-mode identifier: $value'),
    );
  }
}

final class AppleGlassBlendModeResolution {
  const AppleGlassBlendModeResolution({
    required this.sourceMode,
    required this.nativeFlutterMode,
    required this.requiresCustomCompositing,
  });

  final AppleGlassSourceBlendMode sourceMode;
  final BlendMode? nativeFlutterMode;
  final bool requiresCustomCompositing;
}

final class AppleGlassBlendModeResolver {
  const AppleGlassBlendModeResolver();

  AppleGlassBlendModeResolution resolve(int rawValue) {
    final sourceMode = AppleGlassSourceBlendMode.fromRawValue(rawValue);

    final nativeMode = switch (sourceMode) {
      AppleGlassSourceBlendMode.normal => BlendMode.srcOver,
      AppleGlassSourceBlendMode.darken => BlendMode.darken,
      AppleGlassSourceBlendMode.multiply => BlendMode.multiply,
      AppleGlassSourceBlendMode.colorBurn => BlendMode.colorBurn,
      AppleGlassSourceBlendMode.lighten => BlendMode.lighten,
      AppleGlassSourceBlendMode.screen => BlendMode.screen,
      AppleGlassSourceBlendMode.colorDodge => BlendMode.colorDodge,
      AppleGlassSourceBlendMode.overlay => BlendMode.overlay,
      AppleGlassSourceBlendMode.softLight => BlendMode.softLight,
      AppleGlassSourceBlendMode.hardLight => BlendMode.hardLight,
      AppleGlassSourceBlendMode.difference => BlendMode.difference,
      AppleGlassSourceBlendMode.exclusion => BlendMode.exclusion,
      AppleGlassSourceBlendMode.hue => BlendMode.hue,
      AppleGlassSourceBlendMode.saturation => BlendMode.saturation,
      AppleGlassSourceBlendMode.color => BlendMode.color,
      AppleGlassSourceBlendMode.luminosity => BlendMode.luminosity,
      AppleGlassSourceBlendMode.plusDarker => null,
      AppleGlassSourceBlendMode.plusLighter => BlendMode.plus,
    };

    return AppleGlassBlendModeResolution(
      sourceMode: sourceMode,
      nativeFlutterMode: nativeMode,
      requiresCustomCompositing:
          sourceMode == AppleGlassSourceBlendMode.plusDarker,
    );
  }
}

/// Source-backed Core Graphics channel equation for Plus Darker:
///
/// R = MAX(0, 1 - ((1 - D) + (1 - S)))
///   = MAX(0, S + D - 1)
///
/// This helper intentionally operates on a single premultiplied component.
/// Full material compositing still needs an explicit implementation that
/// preserves alpha semantics and layer ordering.
final class AppleGlassPremultipliedRgba {
  const AppleGlassPremultipliedRgba({
    required this.red,
    required this.green,
    required this.blue,
    required this.alpha,
  });

  final double red;
  final double green;
  final double blue;
  final double alpha;
}

abstract final class AppleGlassPlusDarkerBlendMath {
  static double channel({required double source, required double destination}) {
    return math.max(0.0, source + destination - 1.0);
  }

  /// Core Graphics defines the result as premultiplied, with source and
  /// destination components including alpha. Apply the Plus Darker equation
  /// component-wise to premultiplied RGBA, including the alpha component.
  static AppleGlassPremultipliedRgba composite({
    required AppleGlassPremultipliedRgba source,
    required AppleGlassPremultipliedRgba destination,
  }) {
    return AppleGlassPremultipliedRgba(
      red: channel(source: source.red, destination: destination.red),
      green: channel(source: source.green, destination: destination.green),
      blue: channel(source: source.blue, destination: destination.blue),
      alpha: channel(source: source.alpha, destination: destination.alpha),
    );
  }
}
