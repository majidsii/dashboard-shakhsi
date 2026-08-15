class AppleSourceMaterialStyle {
  const AppleSourceMaterialStyle({
    required this.sourceId,
    required this.sourceName,
    required this.sourceValues,
  });

  final String sourceId;
  final String sourceName;
  final Map<String, double> sourceValues;
}

class AppleMaterialTokens {
  const AppleMaterialTokens._({
    required this.isResolved,
    this._customGlassStyles,
  });

  const AppleMaterialTokens.resolved({
    required List<AppleSourceMaterialStyle> customGlassStyles,
  }) : this._(isResolved: true, customGlassStyles: customGlassStyles);

  static const empty = AppleMaterialTokens._(isResolved: false);

  final bool isResolved;
  final List<AppleSourceMaterialStyle>? _customGlassStyles;

  List<AppleSourceMaterialStyle> get customGlassStyles {
    final value = _customGlassStyles;
    if (value == null) {
      throw StateError('Apple material tokens are unresolved.');
    }
    return value;
  }
}
