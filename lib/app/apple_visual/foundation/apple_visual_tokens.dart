class AppleSourceColorToken {
  const AppleSourceColorToken({
    required this.sourceId,
    required this.sourceName,
    required this.red,
    required this.green,
    required this.blue,
    required this.alpha,
  });

  final String sourceId;
  final String sourceName;
  final double red;
  final double green;
  final double blue;
  final double alpha;
}

class AppleColorTokens {
  const AppleColorTokens._({
    required this.isResolved,
    this._primaryLabel,
    this._secondaryLabel,
    this._accentBlue,
    this._primaryFill,
  });

  const AppleColorTokens.resolved({
    required AppleSourceColorToken primaryLabel,
    required AppleSourceColorToken secondaryLabel,
    required AppleSourceColorToken accentBlue,
    required AppleSourceColorToken primaryFill,
  }) : this._(
         isResolved: true,
         primaryLabel: primaryLabel,
         secondaryLabel: secondaryLabel,
         accentBlue: accentBlue,
         primaryFill: primaryFill,
       );

  static const empty = AppleColorTokens._(isResolved: false);

  final bool isResolved;
  final AppleSourceColorToken? _primaryLabel;
  final AppleSourceColorToken? _secondaryLabel;
  final AppleSourceColorToken? _accentBlue;
  final AppleSourceColorToken? _primaryFill;

  AppleSourceColorToken get primaryLabel =>
      _require(_primaryLabel, 'primaryLabel');

  AppleSourceColorToken get secondaryLabel =>
      _require(_secondaryLabel, 'secondaryLabel');

  AppleSourceColorToken get accentBlue => _require(_accentBlue, 'accentBlue');

  AppleSourceColorToken get primaryFill =>
      _require(_primaryFill, 'primaryFill');

  static AppleSourceColorToken _require(
    AppleSourceColorToken? token,
    String name,
  ) {
    if (token == null) {
      throw StateError('Apple color token $name is unresolved.');
    }
    return token;
  }
}
