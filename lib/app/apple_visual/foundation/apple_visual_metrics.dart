enum AppleMetricComponent {
  button,
  searchField,
  textField,
  segmentedControl,
  toggle,
}

class AppleMetricProvenance {
  const AppleMetricProvenance({
    required this.sourceId,
    required this.sourceName,
    required this.appearance,
    required this.stateLabels,
  });

  final String sourceId;
  final String sourceName;
  final String? appearance;
  final List<String> stateLabels;
}

class AppleMetricVariant {
  const AppleMetricVariant({
    required this.component,
    required this.sizeLabel,
    required this.geometry,
    required this.provenance,
  });

  final AppleMetricComponent component;
  final String? sizeLabel;
  final Map<String, double> geometry;
  final List<AppleMetricProvenance> provenance;
}

class AppleMetricTokens {
  const AppleMetricTokens._({required this.isResolved, this._variants});

  AppleMetricTokens.resolved({required List<AppleMetricVariant> variants})
    : this._(
        isResolved: true,
        variants: List<AppleMetricVariant>.unmodifiable(variants),
      );

  static const empty = AppleMetricTokens._(isResolved: false);

  final bool isResolved;
  final List<AppleMetricVariant>? _variants;

  List<AppleMetricVariant> get variants {
    final value = _variants;
    if (value == null) {
      throw StateError('Apple metric tokens are unresolved.');
    }
    return value;
  }

  List<AppleMetricVariant> variantsFor(AppleMetricComponent component) {
    return List<AppleMetricVariant>.unmodifiable(
      variants.where((variant) => variant.component == component),
    );
  }
}
