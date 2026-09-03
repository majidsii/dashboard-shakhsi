import 'apple_visual_family.dart';

final class AppleRendererDeviation {
  const AppleRendererDeviation({
    required this.family,
    required this.component,
    required this.platform,
    required this.reason,
    required this.measuredDelta,
  });

  final AppleVisualFamily family;
  final String component;
  final String platform;
  final String reason;
  final double measuredDelta;
}

abstract final class AppleRendererDeviationBaseline {
  static const List<AppleRendererDeviation> acceptedDeviations =
      <AppleRendererDeviation>[];
}
