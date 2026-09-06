import 'dart:ui' as ui;

abstract interface class AppleGlassBackendCapabilities {
  bool get shaderFilterSupported;
}

final class FlutterAppleGlassBackendCapabilities
    implements AppleGlassBackendCapabilities {
  const FlutterAppleGlassBackendCapabilities();

  @override
  bool get shaderFilterSupported => ui.ImageFilter.isShaderFilterSupported;
}
