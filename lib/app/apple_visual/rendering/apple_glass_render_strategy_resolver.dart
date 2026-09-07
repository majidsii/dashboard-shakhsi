import '../foundation/apple_liquid_glass_recipe.dart';
import 'apple_custom_glass_renderer.dart';
import 'apple_glass_backend_resolver.dart';
import 'apple_glass_render_strategy.dart';
import 'apple_glass_semantic_resolver.dart';
import 'apple_standard_glass_renderer.dart';
import 'apple_unsupported_glass_renderer.dart';

final class AppleGlassRenderStrategyResolver {
  const AppleGlassRenderStrategyResolver({
    this.semanticResolver = const AppleGlassSemanticResolver(),
    this.backendResolver = const AppleGlassBackendResolver(),
  });

  final AppleGlassSemanticResolver semanticResolver;
  final AppleGlassBackendResolver backendResolver;

  AppleGlassRenderStrategy resolve(AppleLiquidGlassRecipe recipe) {
    final requiresCustom = semanticResolver.requiresCustomGlass(recipe);

    if (!requiresCustom) {
      return const AppleStandardGlassRenderer();
    }

    final backend = backendResolver.resolve();

    switch (backend) {
      case AppleGlassBackendState.shaderSupported:
        return const AppleCustomGlassRenderer();

      case AppleGlassBackendState.shaderUnsupported:
        return const AppleUnsupportedGlassRenderer();
    }
  }
}
