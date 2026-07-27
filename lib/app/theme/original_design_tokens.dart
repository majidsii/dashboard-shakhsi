import 'package:flutter/material.dart';

abstract final class OriginalDesignTokens {
  static const double contentMaxWidth = 780;
  static const double pageTopPadding = 24;
  static const double pageHorizontalPadding = 16;
  static const double pageBottomPadding = 84;

  static const double glassBlurSigma = 28;
  static const double fieldBlurSigma = 12;
  static const double rowBlurSigma = 16;
  static const double glassSaturation = 1.85;
  static const double fieldSaturation = 1.50;
  static const double rowSaturation = 1.60;

  // Dark-only backdrop tuning: soften the moving aurora without changing
  // the light theme or the foreground glass material.
  static const double darkAuroraDecorationBlurSigma = 20;
  static const double darkSheenBandOpacityScale = .65;

  static const double referenceWindowWidth = 1180;
  static const double referenceWindowHeight = 780;
  static const double glassRadius = 26;
  static const double cardRadius = 28;
  static const double summaryRadius = 24;
  static const double rowRadius = 20;
  static const double fieldRadius = 16;
  static const double pillRadius = 999;

  static const Color lightAccent = Color(0xFF007AFF);
  static const Color darkAccent = Color(0xFF0A84FF);
  static const Color lightIncome = Color(0xFF34C759);
  static const Color darkIncome = Color(0xFF30D158);
  static const Color lightExpense = Color(0xFFFF3B30);
  static const Color darkExpense = Color(0xFFFF453A);
  static const Color lightAmber = Color(0xFFFF9500);
  static const Color darkAmber = Color(0xFFFF9F0A);
  static const Color lightViolet = Color(0xFFAF52DE);
  static const Color darkViolet = Color(0xFFBF5AF2);
  static const Color lightPriorityLow = Color(0xFF32ADE6);
  static const Color darkPriorityLow = Color(0xFF64D2FF);
}

@immutable
final class OriginalPalette extends ThemeExtension<OriginalPalette> {
  const OriginalPalette({
    required this.backgroundTop,
    required this.backgroundMiddle,
    required this.backgroundBottom,
    required this.blob1,
    required this.blob2,
    required this.blob3,
    required this.blob4,
    required this.sheenBand,
    required this.grainOpacity,
    required this.ink,
    required this.muted,
    required this.faint,
    required this.hair,
    required this.hairTop,
    required this.glassStart,
    required this.glassEnd,
    required this.rimStart,
    required this.rimMid,
    required this.rimLow,
    required this.rimEnd,
    required this.sheen,
    required this.sheenOpacity,
    required this.row,
    required this.field,
    required this.inner,
    required this.line,
    required this.track,
    required this.thumb,
    required this.accent,
    required this.accent2,
    required this.accentSoft,
    required this.income,
    required this.incomeSoft,
    required this.expense,
    required this.expenseSoft,
    required this.amber,
    required this.amberSoft,
    required this.violet,
    required this.violetSoft,
    required this.shadowPrimary,
    required this.shadowSecondary,
  });

  factory OriginalPalette.light() => const OriginalPalette(
    backgroundTop: Color(0xFFEEF1F9),
    backgroundMiddle: Color(0xFFE8ECF7),
    backgroundBottom: Color(0xFFE0E6F3),
    blob1: Color(0x997A9BFF),
    blob2: Color(0x75C484FF),
    blob3: Color(0x705EE0B6),
    blob4: Color(0x75FF98B6),
    sheenBand: Color(0x57FFFFFF),
    grainOpacity: .032,
    ink: Color(0xFF0F1325),
    muted: Color(0xA3161C3A),
    faint: Color(0x66161C3A),
    hair: Color(0x8CFFFFFF),
    hairTop: Color(0xE6FFFFFF),
    glassStart: Color(0x75FFFFFF),
    glassEnd: Color(0x29FFFFFF),
    rimStart: Color(0xF2FFFFFF),
    rimMid: Color(0x4DFFFFFF),
    rimLow: Color(0x12FFFFFF),
    rimEnd: Color(0x8CFFFFFF),
    sheen: Color(0x99FFFFFF),
    sheenOpacity: .5,
    row: Color(0x80FFFFFF),
    field: Color(0x6BFFFFFF),
    inner: Color(0x57FFFFFF),
    line: Color(0x1F1C2650),
    track: Color(0x211C2650),
    thumb: Color(0xD9FFFFFF),
    accent: OriginalDesignTokens.lightAccent,
    accent2: Color(0xFF5AC8FA),
    accentSoft: Color(0x21007AFF),
    income: OriginalDesignTokens.lightIncome,
    incomeSoft: Color(0x2634C759),
    expense: OriginalDesignTokens.lightExpense,
    expenseSoft: Color(0x1FFF3B30),
    amber: OriginalDesignTokens.lightAmber,
    amberSoft: Color(0x29FF9500),
    violet: OriginalDesignTokens.lightViolet,
    violetSoft: Color(0x21AF52DE),
    shadowPrimary: Color(0x26301E5E),
    shadowSecondary: Color(0x0F301E5E),
  );

  factory OriginalPalette.dark() => const OriginalPalette(
    backgroundTop: Color(0xFF080A13),
    backgroundMiddle: Color(0xFF05060D),
    backgroundBottom: Color(0xFF030409),
    blob1: Color(0x6B306CFF),
    blob2: Color(0x578C3EFF),
    blob3: Color(0x4200C7FF),
    blob4: Color(0x42FF50A4),
    sheenBand: Color(0x12FFFFFF),
    grainOpacity: .05,
    ink: Color(0xFFF4F5FA),
    muted: Color(0xA8E6EBFF),
    faint: Color(0x61E6EBFF),
    hair: Color(0x24FFFFFF),
    hairTop: Color(0x47FFFFFF),
    glassStart: Color(0x1FFFFFFF),
    glassEnd: Color(0x09FFFFFF),
    rimStart: Color(0x8CFFFFFF),
    rimMid: Color(0x24FFFFFF),
    rimLow: Color(0x08FFFFFF),
    rimEnd: Color(0x4DFFFFFF),
    sheen: Color(0x4DFFFFFF),
    sheenOpacity: .35,
    row: Color(0x12FFFFFF),
    field: Color(0x13FFFFFF),
    inner: Color(0x0EFFFFFF),
    line: Color(0x1FFFFFFF),
    track: Color(0x21FFFFFF),
    thumb: Color(0x2BFFFFFF),
    accent: OriginalDesignTokens.darkAccent,
    accent2: Color(0xFF64D2FF),
    accentSoft: Color(0x330A84FF),
    income: OriginalDesignTokens.darkIncome,
    incomeSoft: Color(0x2930D158),
    expense: OriginalDesignTokens.darkExpense,
    expenseSoft: Color(0x24FF453A),
    amber: OriginalDesignTokens.darkAmber,
    amberSoft: Color(0x2BFF9F0A),
    violet: OriginalDesignTokens.darkViolet,
    violetSoft: Color(0x29BF5AF2),
    shadowPrimary: Color(0x80000000),
    shadowSecondary: Color(0x59000000),
  );

  final Color backgroundTop;
  final Color backgroundMiddle;
  final Color backgroundBottom;
  final Color blob1;
  final Color blob2;
  final Color blob3;
  final Color blob4;
  final Color sheenBand;
  final double grainOpacity;
  final Color ink;
  final Color muted;
  final Color faint;
  final Color hair;
  final Color hairTop;
  final Color glassStart;
  final Color glassEnd;
  final Color rimStart;
  final Color rimMid;
  final Color rimLow;
  final Color rimEnd;
  final Color sheen;
  final double sheenOpacity;
  final Color row;
  final Color field;
  final Color inner;
  final Color line;
  final Color track;
  final Color thumb;
  final Color accent;
  final Color accent2;
  final Color accentSoft;
  final Color income;
  final Color incomeSoft;
  final Color expense;
  final Color expenseSoft;
  final Color amber;
  final Color amberSoft;
  final Color violet;
  final Color violetSoft;
  final Color shadowPrimary;
  final Color shadowSecondary;

  static OriginalPalette of(BuildContext context) {
    return Theme.of(context).extension<OriginalPalette>()!;
  }

  @override
  OriginalPalette copyWith() => this;

  @override
  OriginalPalette lerp(covariant OriginalPalette? other, double t) {
    if (other == null) return this;
    Color blend(Color a, Color b) => Color.lerp(a, b, t)!;
    return OriginalPalette(
      backgroundTop: blend(backgroundTop, other.backgroundTop),
      backgroundMiddle: blend(backgroundMiddle, other.backgroundMiddle),
      backgroundBottom: blend(backgroundBottom, other.backgroundBottom),
      blob1: blend(blob1, other.blob1),
      blob2: blend(blob2, other.blob2),
      blob3: blend(blob3, other.blob3),
      blob4: blend(blob4, other.blob4),
      sheenBand: blend(sheenBand, other.sheenBand),
      grainOpacity: grainOpacity + (other.grainOpacity - grainOpacity) * t,
      ink: blend(ink, other.ink),
      muted: blend(muted, other.muted),
      faint: blend(faint, other.faint),
      hair: blend(hair, other.hair),
      hairTop: blend(hairTop, other.hairTop),
      glassStart: blend(glassStart, other.glassStart),
      glassEnd: blend(glassEnd, other.glassEnd),
      rimStart: blend(rimStart, other.rimStart),
      rimMid: blend(rimMid, other.rimMid),
      rimLow: blend(rimLow, other.rimLow),
      rimEnd: blend(rimEnd, other.rimEnd),
      sheen: blend(sheen, other.sheen),
      sheenOpacity: sheenOpacity + (other.sheenOpacity - sheenOpacity) * t,
      row: blend(row, other.row),
      field: blend(field, other.field),
      inner: blend(inner, other.inner),
      line: blend(line, other.line),
      track: blend(track, other.track),
      thumb: blend(thumb, other.thumb),
      accent: blend(accent, other.accent),
      accent2: blend(accent2, other.accent2),
      accentSoft: blend(accentSoft, other.accentSoft),
      income: blend(income, other.income),
      incomeSoft: blend(incomeSoft, other.incomeSoft),
      expense: blend(expense, other.expense),
      expenseSoft: blend(expenseSoft, other.expenseSoft),
      amber: blend(amber, other.amber),
      amberSoft: blend(amberSoft, other.amberSoft),
      violet: blend(violet, other.violet),
      violetSoft: blend(violetSoft, other.violetSoft),
      shadowPrimary: blend(shadowPrimary, other.shadowPrimary),
      shadowSecondary: blend(shadowSecondary, other.shadowSecondary),
    );
  }
}
