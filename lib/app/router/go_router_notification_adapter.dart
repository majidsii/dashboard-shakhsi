import 'package:go_router/go_router.dart';

import '../../core/notifications/notification_navigation_queue.dart';
import '../../core/notifications/notification_route_intent.dart';
import 'notification_route_location_mapper.dart';

/// Concrete notification navigation adapter backed by GoRouter.
///
/// Only mapped, allow-listed locations reach [GoRouter.go].
final class GoRouterNotificationAdapter implements NotificationRouterAdapter {
  factory GoRouterNotificationAdapter(
    GoRouter router, {
    NotificationRouteLocationMapper mapper =
        const NotificationRouteLocationMapper(),
  }) {
    return GoRouterNotificationAdapter._(router, mapper);
  }

  GoRouterNotificationAdapter._(this._router, this._mapper);

  final GoRouter _router;
  final NotificationRouteLocationMapper _mapper;

  @override
  void navigate(NotificationRouteIntent intent) {
    final location = _mapper.locationFor(intent);
    if (location == null) {
      return;
    }

    _router.go(location);
  }
}
