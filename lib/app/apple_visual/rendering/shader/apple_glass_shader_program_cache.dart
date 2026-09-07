import 'dart:ui';

import 'apple_glass_shader_program_loader.dart';

final class AppleGlassShaderProgramCache {
  AppleGlassShaderProgramCache({AppleGlassShaderProgramLoader? loader})
    : _loader = loader ?? const AppleDefaultGlassShaderProgramLoader();

  final AppleGlassShaderProgramLoader _loader;

  Future<FragmentProgram>? _programFuture;

  Future<FragmentProgram> get program {
    return _programFuture ??= _loader.load();
  }

  void clear() {
    _programFuture = null;
  }
}
