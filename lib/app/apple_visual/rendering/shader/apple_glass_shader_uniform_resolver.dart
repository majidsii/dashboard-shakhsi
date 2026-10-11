import '../../foundation/apple_liquid_glass_recipe.dart';
import 'apple_glass_shader_parameter_resolver.dart';
import 'apple_glass_shader_uniforms.dart';

final class AppleGlassShaderUniformResolver {
  const AppleGlassShaderUniformResolver({
    this.parameterResolver = const AppleGlassShaderParameterResolver(),
  });

  final AppleGlassShaderParameterResolver parameterResolver;

  AppleGlassShaderUniforms resolve(AppleLiquidGlassRecipe recipe) {
    final parameters = parameterResolver.resolve(recipe);

    return AppleGlassShaderUniforms(
      saturation: parameters.saturation,
      brightness: parameters.brightnessResponse,
      distortion: parameters.distortionStrength,
      depth: parameters.depthResponse,
      chromaticAberration: parameters.chromaticAberration,
      customGlassRadius: parameters.customGlassRadius,
      lighting: parameters.lightingResponse,
    );
  }
}
