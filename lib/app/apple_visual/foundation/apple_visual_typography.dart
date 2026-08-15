enum AppleTypographyRole { body, headline, title1 }

class AppleSourceTypographyToken {
  const AppleSourceTypographyToken({
    required this.sourceId,
    required this.sourceName,
    required this.fontSize,
    required this.lineHeight,
    required this.sourcePostScriptName,
    required this.sourceWeight,
  });

  final String sourceId;
  final String sourceName;
  final double fontSize;
  final double? lineHeight;
  final String? sourcePostScriptName;
  final double? sourceWeight;
}

abstract final class AppleTypographyRuntime {
  static const String nonApplePersianFontFamily = 'Vazirmatn';
  static const bool nonAppleGlyphArtworkIsExact = false;
}

class AppleTypographyTokens {
  const AppleTypographyTokens._({
    required this.isResolved,
    this._body,
    this._headline,
    this._title1,
  });

  const AppleTypographyTokens.resolved({
    required AppleSourceTypographyToken body,
    required AppleSourceTypographyToken headline,
    required AppleSourceTypographyToken title1,
  }) : this._(isResolved: true, body: body, headline: headline, title1: title1);

  static const empty = AppleTypographyTokens._(isResolved: false);

  final bool isResolved;
  final AppleSourceTypographyToken? _body;
  final AppleSourceTypographyToken? _headline;
  final AppleSourceTypographyToken? _title1;

  AppleSourceTypographyToken get body {
    final value = _body;
    if (value == null) {
      throw StateError('Apple typography tokens are unresolved.');
    }
    return value;
  }

  AppleSourceTypographyToken get headline {
    final value = _headline;
    if (value == null) {
      throw StateError('Apple typography tokens are unresolved.');
    }
    return value;
  }

  AppleSourceTypographyToken get title1 {
    final value = _title1;
    if (value == null) {
      throw StateError('Apple typography tokens are unresolved.');
    }
    return value;
  }
}
