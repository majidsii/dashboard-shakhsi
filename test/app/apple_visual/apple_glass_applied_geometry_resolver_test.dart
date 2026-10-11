import 'package:dashboard_shakhsi/app/apple_visual/foundation/apple_liquid_glass_recipe.dart';
import 'package:dashboard_shakhsi/app/apple_visual/foundation/apple_liquid_glass_recipe_resolver.dart';
import 'package:dashboard_shakhsi/app/apple_visual/foundation/apple_visual_family.dart';
import 'package:dashboard_shakhsi/app/apple_visual/foundation/apple_visual_state.dart';
import 'package:dashboard_shakhsi/app/apple_visual/rendering/geometry/apple_glass_applied_geometry_resolver.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const resolver = AppleGlassAppliedGeometryResolver();

  AppleLiquidGlassRecipe targetRecipe() {
    return AppleLiquidGlassRecipeResolver.resolve(
      family: AppleVisualFamily.ios27,
      brightness: Brightness.light,
      role: AppleGlassRole.smallControl,
      state: AppleControlState.idle,
    );
  }

  test('resolves locked 110x78 export to exact 80x48 material placement', () {
    final geometry = resolver.resolve(
      recipe: targetRecipe(),
      canvasSize: const Size(110, 78),
    );

    expect(geometry, isNotNull);

    expect(geometry!.sourceFrameSize, const Size(80, 48));
    expect(geometry.exportInsets, const EdgeInsets.fromLTRB(15, 7, 15, 23));
    expect(geometry.materialRect, const Rect.fromLTWH(15, 7, 80, 48));

    expect(geometry.sourceRadius, greaterThan(1e30));

    // The source max-radius sentinel stays in the recipe/model, then Flutter
    // performs geometry-constrained scaling. No hard-coded 24 is supplied by
    // production code.
    expect(geometry.scaledShape.tlRadiusX, closeTo(24, 1e-6));
    expect(geometry.scaledShape.tlRadiusY, closeTo(24, 1e-6));
    expect(geometry.scaledShape.trRadiusX, closeTo(24, 1e-6));
    expect(geometry.scaledShape.brRadiusY, closeTo(24, 1e-6));
  });

  test('accepts the concrete 80x48 source frame without export padding', () {
    final geometry = resolver.resolve(
      recipe: targetRecipe(),
      canvasSize: const Size(80, 48),
    );

    expect(geometry, isNotNull);
    expect(geometry!.materialRect, const Rect.fromLTWH(0, 0, 80, 48));
    expect(geometry.scaledShape.tlRadiusX, closeTo(24, 1e-6));
    expect(geometry.scaledShape.tlRadiusY, closeTo(24, 1e-6));
  });

  test(
    'rejects an unsupported canvas instead of guessing scale or alignment',
    () {
      expect(
        () => resolver.resolve(
          recipe: targetRecipe(),
          canvasSize: const Size(100, 70),
        ),
        throwsStateError,
      );
    },
  );
}
