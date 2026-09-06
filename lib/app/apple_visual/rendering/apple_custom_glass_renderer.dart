import 'package:flutter/widgets.dart';

import '../foundation/apple_liquid_glass_recipe.dart';
import 'apple_glass_render_strategy.dart';
import 'compositor/apple_custom_glass_compositor.dart';

final class AppleCustomGlassRenderer implements AppleGlassRenderStrategy {
  const AppleCustomGlassRenderer();

  static const _compositor = AppleCustomGlassCompositor();

  @override
  Widget build({
    required AppleLiquidGlassRecipe recipe,
    required Widget child,
  }) {
    return _compositor.compose(recipe: recipe, child: child);
  }
}
