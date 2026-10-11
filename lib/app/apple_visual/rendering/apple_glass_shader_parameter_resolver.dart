import '../foundation/apple_liquid_glass_recipe.dart';
import 'apple_glass_shader_parameters.dart';

final class AppleGlassShaderParameterResolver {
  const AppleGlassShaderParameterResolver();

  AppleGlassShaderParameters resolve(AppleLiquidGlassRecipe recipe) {
    final values = recipe.sourceValues;

    return AppleGlassShaderParameters(
      customGlassEnabled:
          values['style.blurs[0].isCustomGlass'] == 1 &&
          values['style.blurs[0].isEnabled'] == true,
      saturation: _first(values, [
        'style.saturation',
        'style.blurs[0].saturation',
      ]),
      brightness: _first(values, [
        'style.brightness',
        'style.blurs[0].brightness',
      ]),
      distortion: _first(values, [
        'style.distortion',
        'style.blurs[0].distortion',
      ]),
      depth: _first(values, ['style.depth', 'style.blurs[0].depth']),
      chromaticAberration: _first(values, [
        'style.chromaticAberration',
        'style.blurs[0].chromaticAberration',
      ]),
      skipLightingEffects:
          values['style.skipLightingEffects'] == true ||
          values['style.blurs[0].skipLightingEffects'] == true,
      customGlassRadius: _first(values, [
        'style.radius',
        'style.blurs[0].radius',
      ]),
    );
  }

  double _first(Map<String, Object?> values, List<String> keys) {
    for (final key in keys) {
      final value = values[key];

      if (value is num) {
        return value.toDouble();
      }
    }

    return 0;
  }
}
