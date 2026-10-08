import 'dart:ui';

import 'package:dashboard_shakhsi/app/apple_visual/rendering/material/apple_glass_blend_mode_semantics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const resolver = AppleGlassBlendModeResolver();

  test('maps source normal to Flutter srcOver', () {
    final result = resolver.resolve(0);

    expect(result.sourceMode, AppleGlassSourceBlendMode.normal);
    expect(result.nativeFlutterMode, BlendMode.srcOver);
    expect(result.requiresCustomCompositing, isFalse);
  });

  test('maps source luminosity to Flutter luminosity', () {
    final result = resolver.resolve(15);

    expect(result.sourceMode, AppleGlassSourceBlendMode.luminosity);
    expect(result.nativeFlutterMode, BlendMode.luminosity);
    expect(result.requiresCustomCompositing, isFalse);
  });

  test('marks source plus darker as custom compositing', () {
    final result = resolver.resolve(16);

    expect(result.sourceMode, AppleGlassSourceBlendMode.plusDarker);
    expect(result.nativeFlutterMode, isNull);
    expect(result.requiresCustomCompositing, isTrue);
  });

  test('maps source plus lighter to Flutter plus', () {
    final result = resolver.resolve(17);

    expect(result.sourceMode, AppleGlassSourceBlendMode.plusLighter);
    expect(result.nativeFlutterMode, BlendMode.plus);
    expect(result.requiresCustomCompositing, isFalse);
  });

  test('plus darker channel equation matches Core Graphics semantics', () {
    expect(
      AppleGlassPlusDarkerBlendMath.channel(source: 0.8, destination: 0.7),
      closeTo(0.5, 1e-12),
    );

    expect(
      AppleGlassPlusDarkerBlendMath.channel(source: 0.2, destination: 0.3),
      0,
    );
  });

  test('rejects undocumented raw source blend values', () {
    expect(() => resolver.resolve(99), throwsStateError);
  });
}
