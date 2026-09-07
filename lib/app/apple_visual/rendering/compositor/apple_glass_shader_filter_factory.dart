import 'dart:ui' as ui;

final class AppleGlassShaderFilterFactory {
  const AppleGlassShaderFilterFactory();

  ui.ImageFilter create({required ui.FragmentShader shader}) {
    return ui.ImageFilter.shader(shader);
  }
}
