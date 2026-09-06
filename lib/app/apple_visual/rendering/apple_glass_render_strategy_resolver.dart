import '../foundation/apple_liquid_glass_recipe.dart';
import 'apple_custom_glass_renderer.dart';
import 'apple_glass_render_strategy.dart';
import 'apple_standard_glass_renderer.dart';

final class AppleGlassRenderStrategyResolver {
  const AppleGlassRenderStrategyResolver();

  AppleGlassRenderStrategy resolve(AppleLiquidGlassRecipe recipe) {
    final sourceValues = recipe.sourceValues;

    final hasEnabledCustomGlass =
        sourceValues['style.blurs[0].isCustomGlass'] == 1 &&
        sourceValues['style.blurs[0].isEnabled'] == true;

    if (hasEnabledCustomGlass) {
      return const AppleCustomGlassRenderer();
    }

    return const AppleStandardGlassRenderer();
  }
}
