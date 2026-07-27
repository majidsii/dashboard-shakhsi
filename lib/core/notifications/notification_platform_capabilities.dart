enum NotificationHostPlatform { android, linux, macos, windows, unsupported }

final class NotificationPlatformCapabilities {
  const NotificationPlatformCapabilities({
    required this.supportsImmediateDelivery,
    required this.supportsScheduledDelivery,
    required this.supportsPendingRequests,
  });

  final bool supportsImmediateDelivery;
  final bool supportsScheduledDelivery;
  final bool supportsPendingRequests;

  static NotificationPlatformCapabilities forPlatform(
    NotificationHostPlatform platform,
  ) {
    return switch (platform) {
      NotificationHostPlatform.android ||
      NotificationHostPlatform.macos ||
      NotificationHostPlatform.windows =>
        const NotificationPlatformCapabilities(
          supportsImmediateDelivery: true,
          supportsScheduledDelivery: true,
          supportsPendingRequests: true,
        ),
      NotificationHostPlatform.linux => const NotificationPlatformCapabilities(
        supportsImmediateDelivery: true,
        supportsScheduledDelivery: false,
        supportsPendingRequests: false,
      ),
      NotificationHostPlatform.unsupported =>
        const NotificationPlatformCapabilities(
          supportsImmediateDelivery: false,
          supportsScheduledDelivery: false,
          supportsPendingRequests: false,
        ),
    };
  }
}
