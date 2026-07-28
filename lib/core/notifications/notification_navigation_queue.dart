import 'dart:collection';

import 'notification_route_intent.dart';

/// Router-facing boundary used by notification navigation.
///
/// The queue depends only on this contract. The concrete GoRouter adapter is
/// introduced separately, so notification delivery never handles raw routes.
abstract interface class NotificationRouterAdapter {
  void navigate(NotificationRouteIntent intent);
}

/// Holds typed notification route intents until application routing is ready.
///
/// Each call to [enqueue] creates one queue entry and receives at most one
/// navigation attempt. Successfully attempted entries are removed before the
/// adapter is called, so repeated readiness signals cannot replay them.
final class NotificationNavigationQueue {
  final Queue<NotificationRouteIntent> _pending =
      Queue<NotificationRouteIntent>();

  NotificationRouterAdapter? _router;
  bool _isDraining = false;

  bool get isRouterReady => _router != null;

  int get pendingCount => _pending.length;

  /// Adds one typed intent to the tail of the FIFO queue.
  ///
  /// When routing is already ready, delivery is attempted immediately.
  void enqueue(NotificationRouteIntent intent) {
    _pending.addLast(intent);
    _drain();
  }

  /// Attaches the currently usable router and drains pending work in FIFO order.
  ///
  /// Repeating this call does not replay entries that were already attempted.
  void markRouterReady(NotificationRouterAdapter router) {
    _router = router;
    _drain();
  }

  /// Pauses delivery without discarding pending entries.
  void markRouterUnavailable() {
    _router = null;
  }

  void _drain() {
    if (_isDraining || _router == null) {
      return;
    }

    _isDraining = true;
    try {
      while (_router != null && _pending.isNotEmpty) {
        final intent = _pending.removeFirst();
        final router = _router!;

        // Remove before navigation. If navigation throws after causing a side
        // effect, this queue must not replay the same entry on the next drain.
        router.navigate(intent);
      }
    } finally {
      _isDraining = false;
    }
  }
}
