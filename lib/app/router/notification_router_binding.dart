import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/notifications/notification_navigation_queue.dart';
import '../../core/notifications/notification_routing_providers.dart';
import '../bootstrap/notification_routing_bootstrap.dart';
import 'go_router_notification_adapter.dart';

/// Binds the scoped notification queue to the active GoRouter lifecycle.
///
/// Router readiness is announced after the first frame so MaterialApp.router
/// has attached its delegate. Pending notification intents remain queued until
/// that point. Unmounting or replacing the router pauses navigation first.
final class NotificationRouterBinding extends ConsumerStatefulWidget {
  const NotificationRouterBinding({
    required this.router,
    required this.child,
    super.key,
  });

  final GoRouter router;
  final Widget child;

  @override
  ConsumerState<NotificationRouterBinding> createState() =>
      _NotificationRouterBindingState();
}

final class _NotificationRouterBindingState
    extends ConsumerState<NotificationRouterBinding> {
  late final NotificationNavigationQueue _navigationQueue;
  int _bindingGeneration = 0;

  @override
  void initState() {
    super.initState();
    _navigationQueue = ref.read(notificationNavigationQueueProvider);
    _scheduleRouterReady(widget.router);
  }

  @override
  void didUpdateWidget(NotificationRouterBinding oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!identical(oldWidget.router, widget.router)) {
      _navigationQueue.markRouterUnavailable();
      _scheduleRouterReady(widget.router);
    }
  }

  void _scheduleRouterReady(GoRouter router) {
    final generation = ++_bindingGeneration;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || generation != _bindingGeneration) {
        return;
      }

      _navigationQueue.markRouterReady(GoRouterNotificationAdapter(router));
    });
  }

  @override
  void dispose() {
    _bindingGeneration += 1;
    _navigationQueue.markRouterUnavailable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NotificationRoutingBootstrap(child: widget.child);
  }
}
