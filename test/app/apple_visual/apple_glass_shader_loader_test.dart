import 'package:dashboard_shakhsi/app/apple_visual/rendering/shader/apple_glass_shader_program_cache.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('shader program cache owns program lifecycle', () {
    final cache = AppleGlassShaderProgramCache();

    expect(cache, isA<AppleGlassShaderProgramCache>());
  });
}
