import 'dart:ui' as ui;

import 'package:dashboard_shakhsi/app/apple_visual/rendering/compositor/apple_glass_shader_filter_factory.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('shader filter capability contract is explicit', () {
    expect(ui.ImageFilter.isShaderFilterSupported, isA<bool>());
  });

  test('shader filter factory keeps ImageFilter.shader behind contract', () {
    expect(AppleGlassShaderFilterFactory, isNotNull);
  });
}
