import 'dart:ui';

abstract interface class AppleGlassShaderProgramLoader {
  Future<FragmentProgram> load();
}

final class AppleDefaultGlassShaderProgramLoader
    implements AppleGlassShaderProgramLoader {
  const AppleDefaultGlassShaderProgramLoader();

  static const _asset = 'shaders/apple_liquid_glass.frag';

  @override
  Future<FragmentProgram> load() {
    return FragmentProgram.fromAsset(_asset);
  }
}
