import '../../foundation/apple_liquid_glass_recipe.dart';
import '../material/apple_glass_material_layer_resolver.dart';
import 'apple_glass_shadow_stack_compositor.dart';

final class AppleGlassShadowRuntimePipeline {
  const AppleGlassShadowRuntimePipeline({
    this.materialResolver = const AppleGlassMaterialLayerResolver(),
    this.shadowCompositor = const AppleGlassShadowStackCompositor(),
  });

  final AppleGlassMaterialLayerResolver materialResolver;
  final AppleGlassShadowStackCompositor shadowCompositor;

  List<AppleGlassResolvedShadowLayer> resolve({
    required AppleLiquidGlassRecipe recipe,
  }) {
    final material = materialResolver.resolve(recipe);

    return shadowCompositor.resolveLayers(material);
  }
}
