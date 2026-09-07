import 'dart:ui';

import 'apple_glass_shader_program_cache.dart';

final class AppleGlassShaderRuntime {
  AppleGlassShaderRuntime({AppleGlassShaderProgramCache? cache})
    : _cache = cache ?? AppleGlassShaderProgramCache();

  final AppleGlassShaderProgramCache _cache;

  Future<FragmentShader> createShader() async {
    final program = await _cache.program;
    return program.fragmentShader();
  }
}
