import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/notifications/notification_routing_providers.dart';

/// Activates notification click routing while always rendering [child].
///
/// Startup errors are retained in Riverpod for diagnostics but intentionally do
/// not replace or block the application UI.
final class NotificationRoutingBootstrap extends ConsumerWidget {
  const NotificationRoutingBootstrap({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(notificationRoutingStartupProvider);
    return child;
  }
}
