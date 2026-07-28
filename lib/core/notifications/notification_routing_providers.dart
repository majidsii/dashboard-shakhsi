import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'notification_navigation_queue.dart';
import 'notification_response_source.dart';
import 'notification_route_parser.dart';
import 'notification_routing_startup_service.dart';

/// Owns runtime notification response delivery for the active provider scope.
final notificationResponseSourceProvider = Provider<NotificationResponseSource>(
  (ref) {
    final source = NotificationResponseSource();
    ref.onDispose(() {
      unawaited(source.close());
    });
    return source;
  },
);

/// Platform launch-details boundary.
///
/// The safe default represents a normal application launch. Platform bootstrap
/// can override this provider with the local-notification plugin loader without
/// coupling the routing domain to that plugin.
final notificationLaunchDetailsLoaderProvider =
    Provider<NotificationLaunchDetailsLoader>((ref) {
      return () async =>
          const NotificationLaunchDetails(didLaunchFromNotification: false);
    });

final notificationColdStartGatewayProvider =
    Provider<NotificationColdStartGateway>((ref) {
      return NotificationColdStartGateway(
        ref.watch(notificationLaunchDetailsLoaderProvider),
      );
    });

final notificationRouteParserProvider = Provider<NotificationRouteParser>((
  ref,
) {
  return const NotificationRouteParser();
});

/// Shared exactly-once queue later attached to the concrete GoRouter adapter.
final notificationNavigationQueueProvider =
    Provider<NotificationNavigationQueue>((ref) {
      return NotificationNavigationQueue();
    });

final notificationRoutingStartupServiceProvider =
    Provider<NotificationRoutingStartupService>((ref) {
      final service = NotificationRoutingStartupService(
        responseSource: ref.watch(notificationResponseSourceProvider),
        coldStartGateway: ref.watch(notificationColdStartGatewayProvider),
        routeParser: ref.watch(notificationRouteParserProvider),
        navigationQueue: ref.watch(notificationNavigationQueueProvider),
      );

      ref.onDispose(() {
        unawaited(service.dispose());
      });
      return service;
    });

/// Starts notification click routing without blocking application rendering.
///
/// Riverpod caches the future for the lifetime of the provider scope, while the
/// startup service itself remains retry-safe and idempotent.
final notificationRoutingStartupProvider = FutureProvider<void>((ref) async {
  await ref.watch(notificationRoutingStartupServiceProvider).start();
});
