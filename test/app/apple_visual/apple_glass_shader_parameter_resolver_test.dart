import 'package:dashboard_shakhsi/app/apple_visual/foundation/apple_liquid_glass_recipe.dart';
import 'package:dashboard_shakhsi/app/apple_visual/foundation/apple_liquid_glass_recipe_resolver.dart';
import 'package:dashboard_shakhsi/app/apple_visual/foundation/apple_visual_family.dart';
import 'package:dashboard_shakhsi/app/apple_visual/foundation/apple_visual_state.dart';
import 'package:dashboard_shakhsi/app/apple_visual/rendering/shader/apple_glass_shader_parameter_resolver.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('resolves deterministic shader parameter contract', () {
    final recipe = AppleLiquidGlassRecipeResolver.resolve(
      family: AppleVisualFamily.ios27,
      brightness: Brightness.light,
      role: AppleGlassRole.smallControl,
      state: AppleControlState.idle,
    );

    final result = const AppleGlassShaderParameterResolver().resolve(recipe);

    expect(result.saturation, isA<double>());
    expect(result.brightnessResponse, isA<double>());
    expect(result.distortionStrength, isA<double>());
  });
}
