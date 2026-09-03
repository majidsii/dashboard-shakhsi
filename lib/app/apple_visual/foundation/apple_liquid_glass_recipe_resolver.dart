import 'package:flutter/widgets.dart';

import '../generated/apple_source_liquid_glass_recipes.g.dart';
import 'apple_liquid_glass_recipe.dart';
import 'apple_visual_family.dart';
import 'apple_visual_state.dart';

abstract final class AppleLiquidGlassRecipeResolver {
  static AppleLiquidGlassRecipe resolve({
    required AppleVisualFamily family,
    required Brightness brightness,
    required AppleGlassRole role,
    required AppleControlState state,
  }) {
    if (state != AppleControlState.idle) {
      throw StateError(
        'No source-backed Apple Liquid Glass recipe for '
        'family=$family brightness=$brightness role=$role state=$state',
      );
    }

    final source = AppleSourceLiquidGlassRecipeReference.records.singleWhere(
      (record) =>
          record.family == _familyName(family) &&
          record.appearance == _appearanceName(brightness) &&
          record.role == _roleName(role),
      orElse: () => throw StateError(
        'No source-backed Apple Liquid Glass recipe for '
        'family=$family brightness=$brightness role=$role state=$state',
      ),
    );

    return AppleLiquidGlassRecipe(
      family: family,
      brightness: brightness,
      role: role,
      state: state,
      sourceIds: source.sourceIds,
      sourceNames: source.sourceNames,
      sourceValues: source.sourceValues,
      roleMappingEvidence: source.roleMappingEvidence,
    );
  }

  static String _familyName(AppleVisualFamily family) => switch (family) {
    AppleVisualFamily.ios27 => 'ios27',
    AppleVisualFamily.macos27 => 'macos27',
  };

  static String _appearanceName(Brightness brightness) => switch (brightness) {
    Brightness.light => 'light',
    Brightness.dark => 'dark',
  };

  static String _roleName(AppleGlassRole role) => switch (role) {
    AppleGlassRole.smallControl => 'smallControl',
    AppleGlassRole.tintedSmallControl => 'tintedSmallControl',
    AppleGlassRole.mediumSurface => 'mediumSurface',
    AppleGlassRole.largeSurface => 'largeSurface',
    AppleGlassRole.overGlassControl => 'overGlassControl',
  };
}
