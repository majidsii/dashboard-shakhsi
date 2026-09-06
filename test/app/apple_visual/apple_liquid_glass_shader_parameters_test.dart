import 'package:dashboard_shakhsi/app/apple_visual/foundation/apple_liquid_glass_recipe.dart';
import 'package:dashboard_shakhsi/app/apple_visual/foundation/apple_liquid_glass_recipe_resolver.dart';
import 'package:dashboard_shakhsi/app/apple_visual/foundation/apple_visual_family.dart';
import 'package:dashboard_shakhsi/app/apple_visual/foundation/apple_visual_state.dart';
import 'package:dashboard_shakhsi/app/apple_visual/rendering/shader/apple_liquid_glass_shader_parameters_mapper.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps recipe into shader parameters', () {
    final recipe = AppleLiquidGlassRecipeResolver.resolve(
      family: AppleVisualFamily.ios27,
      brightness: Brightness.light,
      role: AppleGlassRole.smallControl,
      state: AppleControlState.idle,
    );

    final params = const AppleLiquidGlassShaderParametersMapper().map(recipe);

    expect(params.opacity, isA<double>());
    expect(params.blurRadius, isA<double>());
  });

  test('uses deterministic defaults', () {
    final recipe = AppleLiquidGlassRecipe(
      family: AppleVisualFamily.ios27,
      brightness: Brightness.light,
      role: AppleGlassRole.smallControl,
      state: AppleControlState.idle,
      sourceIds: const ['test'],
      sourceNames: const ['test'],
      sourceValues: const {},
      roleMappingEvidence: const ['test'],
    );

    final params = const AppleLiquidGlassShaderParametersMapper().map(recipe);

    expect(params.opacity, 1);
    expect(params.blurRadius, 0);
    expect(params.tintStrength, 0);
    expect(params.specularStrength, 0);
  });
}
