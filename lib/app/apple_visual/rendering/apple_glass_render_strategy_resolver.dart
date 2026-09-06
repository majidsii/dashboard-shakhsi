import '../foundation/apple_liquid_glass_recipe.dart';
import 'apple_custom_glass_renderer.dart';
import 'apple_glass_backend_capabilities.dart';
import 'apple_glass_render_strategy.dart';
import 'apple_standard_glass_renderer.dart';
import 'apple_unsupported_glass_renderer.dart';

final class AppleGlassRenderStrategyResolver {
  const AppleGlassRenderStrategyResolver({
    this.capabilities = const FlutterAppleGlassBackendCapabilities(),
  });

  final AppleGlassBackendCapabilities capabilities;

  AppleGlassRenderStrategy resolve(AppleLiquidGlassRecipe recipe) {
    final sourceValues = recipe.sourceValues;

    final hasEnabledCustomGlass =
        sourceValues['style.blurs[0].isCustomGlass'] == 1 &&
        sourceValues['style.blurs[0].isEnabled'] == true;

    if (!hasEnabledCustomGlass) {
      return const AppleStandardGlassRenderer();
    }

    if (!capabilities.shaderFilterSupported) {
      return const AppleUnsupportedGlassRenderer();
    }

    return const AppleCustomGlassRenderer();
  }
}
