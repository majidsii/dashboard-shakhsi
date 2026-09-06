import 'dart:async';
import 'dart:ui' as ui;

final class AppleLiquidGlassShaderRepository {
  AppleLiquidGlassShaderRepository._();

  static final AppleLiquidGlassShaderRepository instance =
      AppleLiquidGlassShaderRepository._();

  static const _asset = 'shaders/apple_liquid_glass_identity.frag';

  Future<ui.FragmentProgram>? _loading;

  Future<ui.FragmentProgram> loadProgram() {
    final existing = _loading;

    if (existing != null) {
      return existing;
    }

    final future = ui.FragmentProgram.fromAsset(_asset);

    _loading = future;

    return future;
  }
}
