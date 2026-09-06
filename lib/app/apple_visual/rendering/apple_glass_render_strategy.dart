import 'package:flutter/widgets.dart';
import '../foundation/apple_liquid_glass_recipe.dart';

abstract interface class AppleGlassRenderStrategy {
  Widget build({required AppleLiquidGlassRecipe recipe, required Widget child});
}
