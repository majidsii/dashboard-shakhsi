import '../material/apple_glass_blend_mode_semantics.dart';
import '../material/apple_glass_material_layers.dart';

enum AppleGlassShadowBackendKind { native, plusDarker }

final class AppleGlassResolvedShadowLayer {
  const AppleGlassResolvedShadowLayer({
    required this.shadow,
    required this.blend,
    required this.backendKind,
  });

  final AppleGlassSourceShadowLayer shadow;
  final AppleGlassBlendModeResolution blend;
  final AppleGlassShadowBackendKind backendKind;
}

final class AppleGlassShadowStackCompositor {
  const AppleGlassShadowStackCompositor({
    this.blendModeResolver = const AppleGlassBlendModeResolver(),
  });

  final AppleGlassBlendModeResolver blendModeResolver;

  List<AppleGlassResolvedShadowLayer> resolveLayers(
    AppleGlassSourceMaterialLayers material,
  ) {
    final layers = <AppleGlassResolvedShadowLayer>[];

    for (final shadow in material.shadows) {
      if (!shadow.isEnabled) {
        continue;
      }

      final blend = blendModeResolver.resolve(shadow.blendMode);

      final AppleGlassShadowBackendKind backendKind;

      if (blend.requiresCustomCompositing &&
          blend.sourceMode == AppleGlassSourceBlendMode.plusDarker) {
        backendKind = AppleGlassShadowBackendKind.plusDarker;
      } else if (!blend.requiresCustomCompositing &&
          blend.nativeFlutterMode != null) {
        backendKind = AppleGlassShadowBackendKind.native;
      } else {
        throw StateError(
          'Unsupported enabled Apple glass shadow: '
          'index=${shadow.index} '
          'blendMode=${shadow.blendMode} '
          'sourceMode=${blend.sourceMode.name}.',
        );
      }

      layers.add(
        AppleGlassResolvedShadowLayer(
          shadow: shadow,
          blend: blend,
          backendKind: backendKind,
        ),
      );
    }

    return List<AppleGlassResolvedShadowLayer>.unmodifiable(layers);
  }
}
