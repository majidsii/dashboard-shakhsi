enum AppleMotionPreset { defaultSpring, interactiveSpring }

enum AppleMotionAccessibilityPolicy { standard, reduceMotion }

class AppleMotionProvenance {
  const AppleMotionProvenance({
    required this.apiReference,
    required this.officialSwiftUIRuntimeReference,
    required this.exactInternalLiquidGlassMotion,
  });

  final String apiReference;
  final bool officialSwiftUIRuntimeReference;
  final bool exactInternalLiquidGlassMotion;
}

class AppleSpringMotion {
  const AppleSpringMotion({
    required this.preset,
    required this.responseSeconds,
    required this.dampingFraction,
    required this.blendDurationSeconds,
    required this.provenance,
  });

  final AppleMotionPreset preset;
  final double responseSeconds;
  final double dampingFraction;
  final double blendDurationSeconds;
  final AppleMotionProvenance provenance;
}

class AppleMotionTokens {
  const AppleMotionTokens._({
    required this.isResolved,
    this._defaultSpring,
    this._interactiveSpring,
    this._accessibilityPolicies,
  });

  AppleMotionTokens.resolved({
    required AppleSpringMotion defaultSpring,
    required AppleSpringMotion interactiveSpring,
    required List<AppleMotionAccessibilityPolicy> accessibilityPolicies,
  }) : this._(
         isResolved: true,
         defaultSpring: defaultSpring,
         interactiveSpring: interactiveSpring,
         accessibilityPolicies:
             List<AppleMotionAccessibilityPolicy>.unmodifiable(
               accessibilityPolicies,
             ),
       );

  static const empty = AppleMotionTokens._(isResolved: false);

  final bool isResolved;
  final AppleSpringMotion? _defaultSpring;
  final AppleSpringMotion? _interactiveSpring;
  final List<AppleMotionAccessibilityPolicy>? _accessibilityPolicies;

  AppleSpringMotion get defaultSpring {
    final value = _defaultSpring;
    if (value == null) {
      throw StateError('Apple motion tokens are unresolved.');
    }
    return value;
  }

  AppleSpringMotion get interactiveSpring {
    final value = _interactiveSpring;
    if (value == null) {
      throw StateError('Apple motion tokens are unresolved.');
    }
    return value;
  }

  List<AppleMotionAccessibilityPolicy> get accessibilityPolicies {
    final value = _accessibilityPolicies;
    if (value == null) {
      throw StateError('Apple motion tokens are unresolved.');
    }
    return value;
  }
}
