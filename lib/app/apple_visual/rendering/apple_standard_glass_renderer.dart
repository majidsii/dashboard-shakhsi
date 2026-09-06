import 'package:flutter/widgets.dart';
import '../foundation/apple_liquid_glass_recipe.dart';
import 'apple_glass_render_strategy.dart';

final class AppleStandardGlassRenderer implements AppleGlassRenderStrategy {
  const AppleStandardGlassRenderer();

  @override
  Widget build({
    required AppleLiquidGlassRecipe recipe,
    required Widget child,
  }) {
    return child;
  }
}
