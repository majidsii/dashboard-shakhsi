import 'dart:async';
import 'dart:collection';

import 'notification_navigation_queue.dart';
import 'notification_response_source.dart';
import 'notification_route_parser.dart';

/// Connects notification response inputs to safe, typed application routing.
///
/// Runtime callbacks are subscribed before cold-start details are loaded so a
/// tap cannot be missed during startup. Those callbacks are buffered until the
/// cold-start payload is handled, preserving launch navigation before newer
/// runtime taps.
final class NotificationRoutingStartupService {
  factory NotificationRoutingStartupService({
    required NotificationResponseSource responseSource,
    required NotificationColdStartGateway coldStartGateway,
    required NotificationRouteParser routeParser,
    required NotificationNavigationQueue navigationQueue,
  }) {
    return NotificationRoutingStartupService._(
      responseSource,
      coldStartGateway,
      routeParser,
      navigationQueue,
    );
  }

  NotificationRoutingStartupService._(
    this._responseSource,
    this._coldStartGateway,
    this._routeParser,
    this._navigationQueue,
  );

  final NotificationResponseSource _responseSource;
  final NotificationColdStartGateway _coldStartGateway;
  final NotificationRouteParser _routeParser;
  final NotificationNavigationQueue _navigationQueue;

  final Queue<String?> _bufferedRuntimePayloads = Queue<String?>();

  // The subscription is owned by this service and cancelled in dispose().
  // The lint cannot follow lifecycle ownership across methods.
  // ignore: cancel_subscriptions
  StreamSubscription<String?>? _runtimeSubscription;
  Future<void>? _startOperation;
  bool _runtimeRoutingEnabled = false;
  bool _coldStartCompleted = false;
  bool _isDisposed = false;

  bool get isStarted => _coldStartCompleted && !_isDisposed;

  bool get isDisposed => _isDisposed;

  /// Starts runtime listening and consumes cold-start input exactly once.
  ///
  /// Concurrent callers share one operation. A failed cold-start read can be
  /// retried without registering another runtime subscription.
  Future<void> start() {
    if (_isDisposed) {
      throw StateError(
        'NotificationRoutingStartupService has already been disposed.',
      );
    }

    if (_coldStartCompleted) {
      return Future<void>.value();
    }

    final operation = _startOperation;
    if (operation != null) {
      return operation;
    }

    _runtimeSubscription ??= _responseSource.payloads.listen(
      _handleRuntimePayload,
    );

    final newOperation = _runStartAttempt();
    _startOperation = newOperation;
    return newOperation;
  }

  Future<void> _runStartAttempt() async {
    try {
      final rawPayload = await _coldStartGateway.takeInitialPayload();
      if (_isDisposed) {
        return;
      }

      _routePayload(rawPayload);
      _coldStartCompleted = true;
      _enableRuntimeRouting();
    } catch (_) {
      if (!_isDisposed) {
        // Runtime taps must not remain blocked by a platform launch-details
        // failure. The cold-start gateway itself remains retryable.
        _enableRuntimeRouting();
      }
      rethrow;
    } finally {
      _startOperation = null;
    }
  }

  void _handleRuntimePayload(String? rawPayload) {
    if (_isDisposed) {
      return;
    }

    if (!_runtimeRoutingEnabled) {
      _bufferedRuntimePayloads.addLast(rawPayload);
      return;
    }

    _routePayload(rawPayload);
  }

  void _enableRuntimeRouting() {
    if (_runtimeRoutingEnabled || _isDisposed) {
      return;
    }

    _runtimeRoutingEnabled = true;
    while (!_isDisposed && _bufferedRuntimePayloads.isNotEmpty) {
      _routePayload(_bufferedRuntimePayloads.removeFirst());
    }
  }

  void _routePayload(String? rawPayload) {
    if (_isDisposed) {
      return;
    }

    final intent = _routeParser.parse(rawPayload);
    if (intent != null) {
      _navigationQueue.enqueue(intent);
    }
  }

  /// Stops runtime routing and discards callbacks buffered during startup.
  ///
  /// Repeated calls are safe. A cold-start operation already in flight may
  /// finish, but its result is ignored after disposal.
  Future<void> dispose() async {
    if (_isDisposed) {
      return;
    }

    _isDisposed = true;
    _bufferedRuntimePayloads.clear();

    final subscription = _runtimeSubscription;
    _runtimeSubscription = null;
    await subscription?.cancel();
  }
}
