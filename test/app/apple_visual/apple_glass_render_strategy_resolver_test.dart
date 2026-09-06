import 'package:dashboard_shakhsi/app/apple_visual/foundation/apple_liquid_glass_recipe.dart';
import 'package:dashboard_shakhsi/app/apple_visual/foundation/apple_liquid_glass_recipe_resolver.dart';
import 'package:dashboard_shakhsi/app/apple_visual/foundation/apple_visual_family.dart';
import 'package:dashboard_shakhsi/app/apple_visual/foundation/apple_visual_state.dart';
import 'package:dashboard_shakhsi/app/apple_visual/rendering/apple_custom_glass_renderer.dart';
import 'package:dashboard_shakhsi/app/apple_visual/rendering/apple_glass_render_strategy_resolver.dart';
import 'package:dashboard_shakhsi/app/apple_visual/rendering/apple_standard_glass_renderer.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppleGlassRenderStrategyResolver', () {
    test('routes enabled source Custom Glass to custom renderer', () {
      final recipe = AppleLiquidGlassRecipeResolver.resolve(
        family: AppleVisualFamily.ios27,
        brightness: Brightness.light,
        role: AppleGlassRole.smallControl,
        state: AppleControlState.idle,
      );

      expect(recipe.sourceValues['style.blurs[0].isCustomGlass'], 1);
      expect(recipe.sourceValues['style.blurs[0].isEnabled'], isTrue);

      final strategy = const AppleGlassRenderStrategyResolver().resolve(recipe);

      expect(strategy, isA<AppleCustomGlassRenderer>());
    });

    test('routes recipe without enabled Custom Glass to standard renderer', () {
      final recipe = AppleLiquidGlassRecipe(
        family: AppleVisualFamily.ios27,
        brightness: Brightness.light,
        role: AppleGlassRole.smallControl,
        state: AppleControlState.idle,
        sourceIds: const ['test-source'],
        sourceNames: const ['test-standard-glass'],
        sourceValues: const {
          'style.blurs[0].isCustomGlass': 0,
          'style.blurs[0].isEnabled': false,
        },
        roleMappingEvidence: const ['test-only'],
      );

      final strategy = const AppleGlassRenderStrategyResolver().resolve(recipe);

      expect(strategy, isA<AppleStandardGlassRenderer>());
    });
  });
}
