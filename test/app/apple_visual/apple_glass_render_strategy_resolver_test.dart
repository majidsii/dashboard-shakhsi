import 'package:dashboard_shakhsi/app/apple_visual/foundation/apple_liquid_glass_recipe.dart';
import 'package:dashboard_shakhsi/app/apple_visual/foundation/apple_liquid_glass_recipe_resolver.dart';
import 'package:dashboard_shakhsi/app/apple_visual/foundation/apple_visual_family.dart';
import 'package:dashboard_shakhsi/app/apple_visual/foundation/apple_visual_state.dart';
import 'package:dashboard_shakhsi/app/apple_visual/rendering/apple_custom_glass_renderer.dart';
import 'package:dashboard_shakhsi/app/apple_visual/rendering/apple_glass_backend_capabilities.dart';
import 'package:dashboard_shakhsi/app/apple_visual/rendering/apple_glass_backend_resolver.dart';
import 'package:dashboard_shakhsi/app/apple_visual/rendering/apple_glass_render_strategy_resolver.dart';
import 'package:dashboard_shakhsi/app/apple_visual/rendering/apple_standard_glass_renderer.dart';
import 'package:dashboard_shakhsi/app/apple_visual/rendering/apple_unsupported_glass_renderer.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

final class _FakeAppleGlassBackendCapabilities
    implements AppleGlassBackendCapabilities {
  const _FakeAppleGlassBackendCapabilities({
    required this.shaderFilterSupported,
  });

  @override
  final bool shaderFilterSupported;
}

void main() {
  group('AppleGlassRenderStrategyResolver', () {
    test(
      'routes enabled source Custom Glass to custom renderer when supported',
      () {
        final recipe = AppleLiquidGlassRecipeResolver.resolve(
          family: AppleVisualFamily.ios27,
          brightness: Brightness.light,
          role: AppleGlassRole.smallControl,
          state: AppleControlState.idle,
        );

        final resolver = AppleGlassRenderStrategyResolver(
          backendResolver: AppleGlassBackendResolver(
            capabilities: const _FakeAppleGlassBackendCapabilities(
              shaderFilterSupported: true,
            ),
          ),
        );

        expect(recipe.sourceValues['style.blurs[0].isCustomGlass'], 1);
        expect(recipe.sourceValues['style.blurs[0].isEnabled'], isTrue);
        expect(resolver.resolve(recipe), isA<AppleCustomGlassRenderer>());
      },
    );

    test(
      'routes Custom Glass to explicit unsupported strategy when shader filters are unavailable',
      () {
        final recipe = AppleLiquidGlassRecipeResolver.resolve(
          family: AppleVisualFamily.ios27,
          brightness: Brightness.light,
          role: AppleGlassRole.smallControl,
          state: AppleControlState.idle,
        );

        final resolver = AppleGlassRenderStrategyResolver(
          backendResolver: AppleGlassBackendResolver(
            capabilities: const _FakeAppleGlassBackendCapabilities(
              shaderFilterSupported: false,
            ),
          ),
        );

        expect(resolver.resolve(recipe), isA<AppleUnsupportedGlassRenderer>());
      },
    );

    test(
      'routes non-Custom-Glass recipe to standard renderer regardless of shader support',
      () {
        final recipe = AppleLiquidGlassRecipe(
          family: AppleVisualFamily.ios27,
          brightness: Brightness.light,
          role: AppleGlassRole.smallControl,
          state: AppleControlState.idle,
          sourceIds: const ['test-source'],
          sourceNames: const ['test-standard-glass'],
          sourceValues: const {
            'style.blurs[0].isCustomGlass': 0,
            'style.blurs[0].isEnabled': false,
          },
          roleMappingEvidence: const ['test-only'],
        );

        final resolver = AppleGlassRenderStrategyResolver(
          backendResolver: AppleGlassBackendResolver(
            capabilities: const _FakeAppleGlassBackendCapabilities(
              shaderFilterSupported: false,
            ),
          ),
        );

        expect(resolver.resolve(recipe), isA<AppleStandardGlassRenderer>());
      },
    );
  });
}
