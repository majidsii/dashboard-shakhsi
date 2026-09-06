import '../foundation/apple_liquid_glass_recipe.dart';

final class AppleGlassSemanticResolver {
  const AppleGlassSemanticResolver();

  bool requiresCustomGlass(AppleLiquidGlassRecipe recipe) {
    final sourceValues = recipe.sourceValues;

    return sourceValues['style.blurs[0].isCustomGlass'] == 1 &&
        sourceValues['style.blurs[0].isEnabled'] == true;
  }
}
