import '../../foundation/apple_liquid_glass_recipe.dart';
import 'apple_glass_material_layers.dart';

final class AppleGlassMaterialLayerResolver {
  const AppleGlassMaterialLayerResolver();

  AppleGlassSourceMaterialLayers resolve(AppleLiquidGlassRecipe recipe) {
    final values = recipe.sourceValues;

    final fillIndexes = _indexes(values, 'style.fills');
    final shadowIndexes = _indexes(values, 'style.shadows');

    final fills = <AppleGlassSourceFillLayer>[
      for (final index in fillIndexes)
        AppleGlassSourceFillLayer(
          index: index,
          isEnabled: _bool(values, 'style.fills[$index].isEnabled'),
          colorHexArgb: _string(values, 'style.fills[$index].color.hexArgb'),
          colorAlpha: _double(values, 'style.fills[$index].color.alpha'),
          colorRed: _double(values, 'style.fills[$index].color.red'),
          colorGreen: _double(values, 'style.fills[$index].color.green'),
          colorBlue: _double(values, 'style.fills[$index].color.blue'),
          blendMode: _int(
            values,
            'style.fills[$index].contextSettings.blendMode',
          ),
          contextOpacity: _double(
            values,
            'style.fills[$index].contextSettings.opacity',
          ),
          fillType: _int(values, 'style.fills[$index].fillType'),
          layeringType: _int(values, 'style.fills[$index].layeringType'),
          noiseIndex: _int(values, 'style.fills[$index].noiseIndex'),
          noiseIntensity: _double(values, 'style.fills[$index].noiseIntensity'),
          patternFillType: _int(values, 'style.fills[$index].patternFillType'),
          patternTileScale: _double(
            values,
            'style.fills[$index].patternTileScale',
          ),
        ),
    ];

    final shadows = <AppleGlassSourceShadowLayer>[
      for (final index in shadowIndexes)
        AppleGlassSourceShadowLayer(
          index: index,
          isEnabled: _bool(values, 'style.shadows[$index].isEnabled'),
          colorHexArgb: _string(values, 'style.shadows[$index].color.hexArgb'),
          colorAlpha: _double(values, 'style.shadows[$index].color.alpha'),
          colorRed: _double(values, 'style.shadows[$index].color.red'),
          colorGreen: _double(values, 'style.shadows[$index].color.green'),
          colorBlue: _double(values, 'style.shadows[$index].color.blue'),
          blendMode: _int(
            values,
            'style.shadows[$index].contextSettings.blendMode',
          ),
          contextOpacity: _double(
            values,
            'style.shadows[$index].contextSettings.opacity',
          ),
          blurRadius: _double(values, 'style.shadows[$index].blurRadius'),
          offsetX: _double(values, 'style.shadows[$index].offsetX'),
          offsetY: _double(values, 'style.shadows[$index].offsetY'),
          spread: _double(values, 'style.shadows[$index].spread'),
        ),
    ];

    return AppleGlassSourceMaterialLayers(
      fills: List<AppleGlassSourceFillLayer>.unmodifiable(fills),
      shadows: List<AppleGlassSourceShadowLayer>.unmodifiable(shadows),
      corners: AppleGlassSourceCornerSemantics(
        prefersConcentric: _bool(values, 'style.corners.prefersConcentric'),
        smoothing: _double(values, 'style.corners.smoothing'),
        style: _int(values, 'style.corners.style'),
        radius: _optionalDouble(values, 'style.corners.radii[0]'),
      ),
    );
  }

  List<int> _indexes(Map<String, Object?> values, String prefix) {
    final pattern = RegExp('^${RegExp.escape(prefix)}\\[(\\d+)\\]\\.');

    final indexes = <int>{};

    for (final key in values.keys) {
      final match = pattern.firstMatch(key);
      if (match != null) {
        indexes.add(int.parse(match.group(1)!));
      }
    }

    final sorted = indexes.toList()..sort();
    return sorted;
  }

  String _string(Map<String, Object?> values, String key) {
    final value = values[key];
    if (value is String) {
      return value;
    }
    throw StateError('Missing or invalid source string: $key');
  }

  bool _bool(Map<String, Object?> values, String key) {
    final value = values[key];
    if (value is bool) {
      return value;
    }
    throw StateError('Missing or invalid source bool: $key');
  }

  int _int(Map<String, Object?> values, String key) {
    final value = values[key];
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    throw StateError('Missing or invalid source integer: $key');
  }

  double _double(Map<String, Object?> values, String key) {
    final value = values[key];
    if (value is num) {
      return value.toDouble();
    }
    throw StateError('Missing or invalid source number: $key');
  }

  double? _optionalDouble(Map<String, Object?> values, String key) {
    final value = values[key];
    if (value == null) {
      return null;
    }
    if (value is num) {
      return value.toDouble();
    }
    throw StateError('Invalid source number: $key');
  }
}
