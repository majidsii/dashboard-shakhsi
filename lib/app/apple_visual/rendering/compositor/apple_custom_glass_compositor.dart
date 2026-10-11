import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../../foundation/apple_liquid_glass_recipe.dart';
import 'apple_custom_glass_material_surface.dart';
import 'apple_glass_compositor.dart';
import 'apple_glass_shader_filter_factory.dart';

final class AppleCustomGlassCompositor implements AppleGlassCompositor {
  const AppleCustomGlassCompositor();

  static const _shaderFilterFactory = AppleGlassShaderFilterFactory();

  @override
  Widget compose({
    required AppleLiquidGlassRecipe recipe,
    required Widget child,
  }) {
    return AppleCustomGlassMaterialSurface(recipe: recipe, child: child);
  }

  @visibleForTesting
  ui.ImageFilter? createShaderFilter(ui.FragmentShader shader) {
    return _shaderFilterFactory.create(shader: shader);
  }
}
