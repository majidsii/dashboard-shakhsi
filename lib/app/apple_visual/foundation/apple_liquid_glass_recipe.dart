import 'package:flutter/widgets.dart';

import 'apple_visual_family.dart';
import 'apple_visual_state.dart';

enum AppleGlassRole {
  smallControl,
  tintedSmallControl,
  mediumSurface,
  largeSurface,
  overGlassControl,
}

final class AppleLiquidGlassRecipe {
  AppleLiquidGlassRecipe({
    required this.family,
    required this.brightness,
    required this.role,
    required this.state,
    required List<String> sourceIds,
    required List<String> sourceNames,
    required Map<String, Object?> sourceValues,
    required List<String> roleMappingEvidence,
  }) : sourceIds = List<String>.unmodifiable(sourceIds),
       sourceNames = List<String>.unmodifiable(sourceNames),
       sourceValues = Map<String, Object?>.unmodifiable(sourceValues),
       roleMappingEvidence = List<String>.unmodifiable(roleMappingEvidence);

  final AppleVisualFamily family;
  final Brightness brightness;
  final AppleGlassRole role;
  final AppleControlState state;

  final List<String> sourceIds;
  final List<String> sourceNames;
  final Map<String, Object?> sourceValues;
  final List<String> roleMappingEvidence;
}
