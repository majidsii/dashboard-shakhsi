import 'apple_glass_backend_capabilities.dart';

enum AppleGlassBackendState { shaderSupported, shaderUnsupported }

final class AppleGlassBackendResolver {
  const AppleGlassBackendResolver({
    this.capabilities = const FlutterAppleGlassBackendCapabilities(),
  });

  final AppleGlassBackendCapabilities capabilities;

  AppleGlassBackendState resolve() {
    if (capabilities.shaderFilterSupported) {
      return AppleGlassBackendState.shaderSupported;
    }

    return AppleGlassBackendState.shaderUnsupported;
  }
}
