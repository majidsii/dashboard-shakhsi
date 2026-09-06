import 'package:flutter/widgets.dart';

import '../../foundation/apple_liquid_glass_recipe.dart';
import 'apple_custom_glass_filter.dart';
import 'apple_glass_compositor.dart';

final class AppleCustomGlassCompositor implements AppleGlassCompositor {
  const AppleCustomGlassCompositor();

  @override
  Widget compose({
    required AppleLiquidGlassRecipe recipe,
    required Widget child,
  }) {
    return AppleCustomGlassFilter(recipe: recipe, child: child);
  }
}
