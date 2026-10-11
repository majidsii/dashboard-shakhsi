import 'apple_glass_shadow_stack_compositor.dart';

final class AppleGlassShadowRuntimePainter {
  const AppleGlassShadowRuntimePainter();

  void paint({required List<AppleGlassResolvedShadowLayer> layers}) {
    for (final layer in layers) {
      switch (layer.backendKind) {
        case AppleGlassShadowBackendKind.native:
          _paintNative(layer);
        case AppleGlassShadowBackendKind.plusDarker:
          _paintPlusDarker(layer);
      }
    }
  }

  void _paintNative(AppleGlassResolvedShadowLayer layer) {}

  void _paintPlusDarker(AppleGlassResolvedShadowLayer layer) {}
}
