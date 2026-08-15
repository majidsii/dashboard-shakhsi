import 'package:flutter/widgets.dart';

import '../generated/apple_source_colors.g.dart';
import '../generated/apple_source_materials.g.dart';
import '../generated/apple_source_metrics.g.dart';
import '../generated/apple_source_motion.g.dart';
import '../generated/apple_source_typography.g.dart';
import 'apple_visual_family.dart';
import 'apple_visual_materials.dart';
import 'apple_visual_metrics.dart';
import 'apple_visual_motion.dart';
import 'apple_visual_tokens.dart';
import 'apple_visual_typography.dart';

abstract final class AppleSourceTokenMapper {
  static AppleMotionPreset _motionPreset(String value) {
    return switch (value) {
      'defaultSpring' => AppleMotionPreset.defaultSpring,
      'interactiveSpring' => AppleMotionPreset.interactiveSpring,
      _ => throw StateError(
        'Unsupported generated Apple motion preset: $value',
      ),
    };
  }

  static AppleMotionAccessibilityPolicy _motionAccessibilityPolicy(
    String value,
  ) {
    return switch (value) {
      'standard' => AppleMotionAccessibilityPolicy.standard,
      'reduceMotion' => AppleMotionAccessibilityPolicy.reduceMotion,
      _ => throw StateError(
        'Unsupported generated Apple motion accessibility policy: $value',
      ),
    };
  }

  static AppleSpringMotion _springMotion(AppleGeneratedSpringMotion source) {
    return AppleSpringMotion(
      preset: _motionPreset(source.id),
      responseSeconds: source.responseSeconds,
      dampingFraction: source.dampingFraction,
      blendDurationSeconds: source.blendDurationSeconds,
      provenance: AppleMotionProvenance(
        apiReference: source.provenance.apiReference,
        officialSwiftUIRuntimeReference:
            source.provenance.officialSwiftUIRuntimeReference,
        exactInternalLiquidGlassMotion:
            source.provenance.exactInternalLiquidGlassMotion,
      ),
    );
  }

  static AppleMotionTokens motion({required AppleVisualFamily family}) {
    switch (family) {
      case AppleVisualFamily.ios27:
      case AppleVisualFamily.macos27:
        break;
    }

    return AppleMotionTokens.resolved(
      defaultSpring: _springMotion(AppleSourceMotionReference.defaultSpring),
      interactiveSpring: _springMotion(
        AppleSourceMotionReference.interactiveSpring,
      ),
      accessibilityPolicies: AppleSourceMotionReference.accessibilityPolicies
          .map(_motionAccessibilityPolicy)
          .toList(growable: false),
    );
  }

  static AppleMetricComponent _metricComponent(String value) {
    return switch (value) {
      'button' => AppleMetricComponent.button,
      'searchField' => AppleMetricComponent.searchField,
      'textField' => AppleMetricComponent.textField,
      'segmentedControl' => AppleMetricComponent.segmentedControl,
      'toggle' => AppleMetricComponent.toggle,
      _ => throw StateError(
        'Unsupported generated Apple metric component: $value',
      ),
    };
  }

  static AppleMetricTokens metrics({required AppleVisualFamily family}) {
    final sourceVariants = switch (family) {
      AppleVisualFamily.ios27 => AppleSourceMetricReference.iosVariants,
      AppleVisualFamily.macos27 => AppleSourceMetricReference.macosVariants,
    };

    return AppleMetricTokens.resolved(
      variants: sourceVariants
          .map(
            (source) => AppleMetricVariant(
              component: _metricComponent(source.component),
              sizeLabel: source.sizeLabel,
              geometry: Map<String, double>.unmodifiable(source.geometry),
              provenance: List<AppleMetricProvenance>.unmodifiable(
                source.provenance.map(
                  (entry) => AppleMetricProvenance(
                    sourceId: entry.sourceId,
                    sourceName: entry.sourceName,
                    appearance: entry.appearance,
                    stateLabels: List<String>.unmodifiable(entry.stateLabels),
                  ),
                ),
              ),
            ),
          )
          .toList(growable: false),
    );
  }

  static AppleMaterialTokens materials({required AppleVisualFamily family}) {
    final sourceStyles = switch (family) {
      AppleVisualFamily.ios27 =>
        AppleSourceMaterialReference.iosCustomGlassStyles,
      AppleVisualFamily.macos27 =>
        AppleSourceMaterialReference.macosCustomGlassStyles,
    };

    return AppleMaterialTokens.resolved(
      customGlassStyles: List<AppleSourceMaterialStyle>.unmodifiable(
        sourceStyles.map(
          (source) => AppleSourceMaterialStyle(
            sourceId: source.sourceId,
            sourceName: source.sourceName,
            sourceValues: Map<String, double>.unmodifiable(source.sourceValues),
          ),
        ),
      ),
    );
  }

  static AppleColorTokens colors({
    required AppleVisualFamily family,
    required Brightness brightness,
  }) {
    final swatches = switch (family) {
      AppleVisualFamily.ios27 => AppleSourceColorReference.iosSwatches,
      AppleVisualFamily.macos27 => AppleSourceColorReference.macosSwatches,
    };

    final ids = _ColorSourceIds.forTheme(family, brightness);

    AppleSourceColorToken pick(String sourceId) {
      final source = swatches.singleWhere(
        (entry) => entry.sourceId == sourceId,
      );

      return AppleSourceColorToken(
        sourceId: source.sourceId,
        sourceName: source.name,
        red: source.red,
        green: source.green,
        blue: source.blue,
        alpha: source.alpha,
      );
    }

    return AppleColorTokens.resolved(
      primaryLabel: pick(ids.primaryLabel),
      secondaryLabel: pick(ids.secondaryLabel),
      accentBlue: pick(ids.accentBlue),
      primaryFill: pick(ids.primaryFill),
    );
  }

  static AppleTypographyTokens typography({required AppleVisualFamily family}) {
    return AppleTypographyTokens.resolved(
      body: typographyRole(family: family, role: AppleTypographyRole.body),
      headline: typographyRole(
        family: family,
        role: AppleTypographyRole.headline,
      ),
      title1: typographyRole(family: family, role: AppleTypographyRole.title1),
    );
  }

  static AppleSourceTypographyToken typographyRole({
    required AppleVisualFamily family,
    required AppleTypographyRole role,
  }) {
    final source = switch ((family, role)) {
      (AppleVisualFamily.ios27, AppleTypographyRole.body) =>
        AppleSourceTypographyReference.iosBody,
      (AppleVisualFamily.ios27, AppleTypographyRole.headline) =>
        AppleSourceTypographyReference.iosHeadline,
      (AppleVisualFamily.ios27, AppleTypographyRole.title1) =>
        AppleSourceTypographyReference.iosTitle1,
      (AppleVisualFamily.macos27, AppleTypographyRole.body) =>
        AppleSourceTypographyReference.macosBody,
      (AppleVisualFamily.macos27, AppleTypographyRole.headline) =>
        AppleSourceTypographyReference.macosHeadline,
      (AppleVisualFamily.macos27, AppleTypographyRole.title1) =>
        AppleSourceTypographyReference.macosTitle1,
    };

    return AppleSourceTypographyToken(
      sourceId: source.sourceId,
      sourceName: source.sourceName,
      fontSize: source.fontSize,
      lineHeight: source.lineHeight,
      sourcePostScriptName: source.sourcePostScriptName,
      sourceWeight: source.sourceWeight,
    );
  }
}

class _ColorSourceIds {
  const _ColorSourceIds(
    this.primaryLabel,
    this.secondaryLabel,
    this.accentBlue,
    this.primaryFill,
  );

  final String primaryLabel;
  final String secondaryLabel;
  final String accentBlue;
  final String primaryFill;

  static _ColorSourceIds forTheme(
    AppleVisualFamily family,
    Brightness brightness,
  ) => switch ((family, brightness)) {
    (AppleVisualFamily.ios27, Brightness.light) => const _ColorSourceIds(
      '5941701F-DDE9-4318-ADDE-068451F0E822',
      'CB3179CC-FD0F-4ED0-9C4D-324808246F3D',
      '117CF35E-A575-4626-B899-FA9637445FFC',
      'FCBAD928-F1D7-4414-B032-65DA451F227A',
    ),
    (AppleVisualFamily.ios27, Brightness.dark) => const _ColorSourceIds(
      '6BA01314-540A-41EB-96C6-38E13B190312',
      '2037FC05-8030-45A5-9CC7-43E456560112',
      '0A6FA887-AE13-41DF-9AA5-07313DCA56DC',
      '66F6B232-E9AF-4A6B-A51E-BCB51BF9E518',
    ),
    (AppleVisualFamily.macos27, Brightness.light) => const _ColorSourceIds(
      '2E2D2309-55DC-47E7-A385-800BA821048B',
      '4928019B-30D7-4558-B6B2-80F2E171E6EA',
      '117CF35E-A575-4626-B899-FA9637445FFC',
      '00E553B6-CE90-4F2A-9D4D-0FC52F66A894',
    ),
    (AppleVisualFamily.macos27, Brightness.dark) => const _ColorSourceIds(
      '5A246CA8-2E26-4ACF-A2AB-56D22F652B9E',
      '332E3010-176D-4F98-BEE0-9839AD252637',
      '0A6FA887-AE13-41DF-9AA5-07313DCA56DC',
      'B44716D1-A72A-4036-8D6D-60C60085A70D',
    ),
  };
}
