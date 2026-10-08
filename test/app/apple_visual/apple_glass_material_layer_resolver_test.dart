import 'package:dashboard_shakhsi/app/apple_visual/foundation/apple_liquid_glass_recipe.dart';
import 'package:dashboard_shakhsi/app/apple_visual/foundation/apple_liquid_glass_recipe_resolver.dart';
import 'package:dashboard_shakhsi/app/apple_visual/foundation/apple_visual_family.dart';
import 'package:dashboard_shakhsi/app/apple_visual/foundation/apple_visual_state.dart';
import 'package:dashboard_shakhsi/app/apple_visual/rendering/material/apple_glass_material_layer_resolver.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'resolves the complete ios27 light smallControl material source stack',
    () {
      final recipe = AppleLiquidGlassRecipeResolver.resolve(
        family: AppleVisualFamily.ios27,
        brightness: Brightness.light,
        role: AppleGlassRole.smallControl,
        state: AppleControlState.idle,
      );

      final material = const AppleGlassMaterialLayerResolver().resolve(recipe);

      expect(material.fills, hasLength(4));
      expect(material.shadows, hasLength(13));

      final fill0 = material.fills[0];
      expect(fill0.index, 0);
      expect(fill0.isEnabled, isTrue);
      expect(fill0.colorHexArgb, '#33F8F8F8');
      expect(fill0.colorAlpha, 0.2);
      expect(fill0.blendMode, 15);
      expect(fill0.contextOpacity, 1);
      expect(fill0.fillType, 0);
      expect(fill0.layeringType, 0);

      final fill3 = material.fills[3];
      expect(fill3.colorHexArgb, '#99444444');
      expect(fill3.colorAlpha, 0.6);
      expect(fill3.blendMode, 17);

      final shadow0 = material.shadows[0];
      expect(shadow0.isEnabled, isTrue);
      expect(shadow0.colorHexArgb, '#05000000');
      expect(shadow0.colorAlpha, 0.02);
      expect(shadow0.blendMode, 0);
      expect(shadow0.blurRadius, 15);
      expect(shadow0.offsetX, 0);
      expect(shadow0.offsetY, 8);
      expect(shadow0.spread, 0);

      final shadow12 = material.shadows.singleWhere(
        (shadow) => shadow.index == 12,
      );
      expect(shadow12.colorHexArgb, '#FF282828');
      expect(shadow12.blendMode, 17);
      expect(shadow12.blurRadius, 10);
      expect(shadow12.offsetY, 40);
      expect(shadow12.spread, -40);

      expect(material.corners.prefersConcentric, isFalse);
      expect(material.corners.smoothing, 0.6);
      expect(material.corners.style, 1);
      expect(material.corners.radius, isNull);
    },
  );

  test(
    'keeps source blend identifiers raw instead of guessing Flutter modes',
    () {
      final recipe = AppleLiquidGlassRecipeResolver.resolve(
        family: AppleVisualFamily.ios27,
        brightness: Brightness.light,
        role: AppleGlassRole.smallControl,
        state: AppleControlState.idle,
      );

      final material = const AppleGlassMaterialLayerResolver().resolve(recipe);

      expect(
        material.fills.map((fill) => fill.blendMode).toSet(),
        containsAll(<int>{0, 15, 17}),
      );
      expect(
        material.shadows.map((shadow) => shadow.blendMode).toSet(),
        containsAll(<int>{0, 16, 17}),
      );
    },
  );
}
