import 'package:dashboard_shakhsi/app/apple_visual/rendering/shader/apple_glass_shader_runtime.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('shader runtime owns shader creation lifecycle', () {
    final runtime = AppleGlassShaderRuntime();

    expect(runtime, isA<AppleGlassShaderRuntime>());
  });
}
