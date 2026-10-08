import 'package:dashboard_shakhsi/app/apple_visual/foundation/apple_liquid_glass_recipe.dart';
import 'package:dashboard_shakhsi/app/apple_visual/foundation/apple_liquid_glass_recipe_resolver.dart';
import 'package:dashboard_shakhsi/app/apple_visual/foundation/apple_visual_family.dart';
import 'package:dashboard_shakhsi/app/apple_visual/foundation/apple_visual_state.dart';
import 'package:dashboard_shakhsi/app/apple_visual/rendering/compositor/apple_glass_shadow_stack_compositor.dart';
import 'package:dashboard_shakhsi/app/apple_visual/rendering/material/apple_glass_material_layer_resolver.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const materialResolver = AppleGlassMaterialLayerResolver();
  const compositor = AppleGlassShadowStackCompositor();

  test('classifies ios27 light smallControl shadows in exact source order', () {
    final recipe = AppleLiquidGlassRecipeResolver.resolve(
      family: AppleVisualFamily.ios27,
      brightness: Brightness.light,
      role: AppleGlassRole.smallControl,
      state: AppleControlState.idle,
    );

    final material = materialResolver.resolve(recipe);
    final layers = compositor.resolveLayers(material);

    expect(layers, hasLength(13));

    expect(
      layers.map((layer) => layer.shadow.index).toList(growable: false),
      orderedEquals(<int>[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]),
    );

    expect(
      layers.map((layer) => layer.backendKind).toList(growable: false),
      orderedEquals(<AppleGlassShadowBackendKind>[
        AppleGlassShadowBackendKind.native,
        AppleGlassShadowBackendKind.plusDarker,
        AppleGlassShadowBackendKind.plusDarker,
        AppleGlassShadowBackendKind.plusDarker,
        AppleGlassShadowBackendKind.plusDarker,
        AppleGlassShadowBackendKind.plusDarker,
        AppleGlassShadowBackendKind.native,
        AppleGlassShadowBackendKind.native,
        AppleGlassShadowBackendKind.native,
        AppleGlassShadowBackendKind.native,
        AppleGlassShadowBackendKind.plusDarker,
        AppleGlassShadowBackendKind.native,
        AppleGlassShadowBackendKind.native,
      ]),
    );

    final enabledSourceIndexes = material.shadows
        .where((shadow) => shadow.isEnabled)
        .map((shadow) => shadow.index)
        .toList(growable: false);

    final resolvedIndexes = layers
        .map((layer) => layer.shadow.index)
        .toList(growable: false);

    expect(resolvedIndexes, orderedEquals(enabledSourceIndexes));
  });
}
