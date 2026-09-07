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
      saturation: _read(values, 'style.blurs[0].saturation'),
      brightness: _read(values, 'style.blurs[0].brightness'),
      distortion: _read(values, 'style.blurs[0].distortion'),
      depth: _read(values, 'style.blurs[0].depth'),
      chromaticAberration: _read(values, 'style.blurs[0].chromaticAberration'),
      skipLightingEffects: values['style.blurs[0].skipLightingEffects'] == true,
      customGlassRadius: _read(values, 'style.blurs[0].radius'),
    );
  }

  double _read(Map<String, Object?> values, String key) {
    final value = values[key];
    return value is num ? value.toDouble() : 0;
  }
}
