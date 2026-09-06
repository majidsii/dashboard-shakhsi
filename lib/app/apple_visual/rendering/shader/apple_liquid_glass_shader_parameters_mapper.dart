import '../../foundation/apple_liquid_glass_recipe.dart';
import 'apple_liquid_glass_shader_parameters.dart';

final class AppleLiquidGlassShaderParametersMapper {
  const AppleLiquidGlassShaderParametersMapper();

  AppleLiquidGlassShaderParameters map(AppleLiquidGlassRecipe recipe) {
    final values = recipe.sourceValues;

    return AppleLiquidGlassShaderParameters(
      opacity: _doubleValue(values['style.opacity'], fallback: 1),
      blurRadius: _doubleValue(values['style.blurs[0].radius'], fallback: 0),
      tintStrength: _doubleValue(values['style.tintStrength'], fallback: 0),
      specularStrength: _doubleValue(
        values['style.specularStrength'],
        fallback: 0,
      ),
    );
  }

  double _doubleValue(Object? value, {required double fallback}) {
    if (value is num) {
      return value.toDouble();
    }

    return fallback;
  }
}
