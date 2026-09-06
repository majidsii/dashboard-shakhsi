import '../../foundation/apple_liquid_glass_recipe.dart';
import 'apple_glass_shader_parameters.dart';

final class AppleGlassShaderParameterResolver {
  const AppleGlassShaderParameterResolver();

  AppleGlassShaderParameters resolve(AppleLiquidGlassRecipe recipe) {
    final values = recipe.sourceValues;

    return AppleGlassShaderParameters(
      saturation: _number(values['style.blurs[0].saturation']),
      brightnessResponse: _number(values['style.blurs[0].brightnessResponse']),
      distortionStrength: _number(values['style.blurs[0].distortionStrength']),
      depthResponse: _number(values['style.blurs[0].depthResponse']),
      lightingResponse: _number(values['style.blurs[0].lightingResponse']),
    );
  }

  double _number(Object? value) {
    if (value is num) {
      return value.toDouble();
    }

    return 0;
  }
}
