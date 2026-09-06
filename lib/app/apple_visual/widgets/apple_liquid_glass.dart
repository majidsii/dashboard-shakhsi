import 'package:flutter/widgets.dart';

import '../foundation/apple_liquid_glass_recipe.dart';
import '../foundation/apple_liquid_glass_recipe_resolver.dart';
import '../foundation/apple_visual_state.dart';
import '../foundation/apple_visual_theme.dart';
import '../rendering/apple_glass_render_strategy_resolver.dart';

@visibleForTesting
final class AppleLiquidGlassRenderDiagnostics {
  const AppleLiquidGlassRenderDiagnostics({required this.recipe});

  final AppleLiquidGlassRecipe recipe;
}

final class AppleLiquidGlass extends StatelessWidget {
  const AppleLiquidGlass({
    required this.theme,
    required this.role,
    required this.child,
    this.state = AppleControlState.idle,
    super.key,
  });

  final AppleVisualThemeData theme;
  final AppleGlassRole role;
  final AppleControlState state;
  final Widget child;

  @visibleForTesting
  AppleLiquidGlassRenderDiagnostics get debugRenderDiagnostics {
    return AppleLiquidGlassRenderDiagnostics(recipe: _resolveRecipe());
  }

  AppleLiquidGlassRecipe _resolveRecipe() {
    return AppleLiquidGlassRecipeResolver.resolve(
      family: theme.family,
      brightness: theme.brightness,
      role: role,
      state: state,
    );
  }

  @override
  Widget build(BuildContext context) {
    final recipe = _resolveRecipe();

    return _AppleLiquidGlassRenderer(recipe: recipe, child: child);
  }
}

final class _AppleLiquidGlassRenderer extends StatelessWidget {
  const _AppleLiquidGlassRenderer({required this.recipe, required this.child});

  static const _strategyResolver = AppleGlassRenderStrategyResolver();

  final AppleLiquidGlassRecipe recipe;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final strategy = _strategyResolver.resolve(recipe);

    return strategy.build(recipe: recipe, child: child);
  }
}
