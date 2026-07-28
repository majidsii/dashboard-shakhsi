import 'dart:async';

/// Raw notification-response input received while the application is running.
///
/// This source intentionally does not decode payloads. Validation and route
/// allow-listing belong to `NotificationRouteParser` in the next layer.
final class NotificationResponseSource {
  final StreamController<String?> _controller =
      StreamController<String?>.broadcast(sync: true);

  bool _isClosed = false;

  Stream<String?> get payloads => _controller.stream;

  bool get isClosed => _isClosed;

  /// Publishes one plugin callback as one runtime payload event.
  ///
  /// Late callbacks after shutdown are ignored so notification integration
  /// cannot crash application teardown.
  void publishRuntimePayload(String? rawPayload) {
    if (_isClosed) {
      return;
    }

    _controller.add(rawPayload);
  }

  /// Stops runtime delivery. Repeated calls are safe.
  Future<void> close() async {
    if (_isClosed) {
      return;
    }

    _isClosed = true;
    await _controller.close();
  }
}

/// Platform launch information normalized away from the notification plugin.
final class NotificationLaunchDetails {
  const NotificationLaunchDetails({
    required this.didLaunchFromNotification,
    this.payload,
  });

  final bool didLaunchFromNotification;
  final String? payload;
}

typedef NotificationLaunchDetailsLoader =
    Future<NotificationLaunchDetails> Function();

/// Provides the notification payload that opened the application, at most once.
///
/// Concurrent reads are serialized. Exactly one successful caller can consume
/// launch details; later callers receive `null`. Loader failures do not consume
/// the launch, allowing a later startup retry.
final class NotificationColdStartGateway {
  NotificationColdStartGateway(this._loadDetails);

  final NotificationLaunchDetailsLoader _loadDetails;

  Future<void> _operationTail = Future<void>.value();
  bool _consumed = false;

  Future<String?> takeInitialPayload() {
    final result = Completer<String?>();

    _operationTail = _operationTail.then((_) async {
      if (_consumed) {
        result.complete(null);
        return;
      }

      try {
        final details = await _loadDetails();
        _consumed = true;
        result.complete(
          details.didLaunchFromNotification ? details.payload : null,
        );
      } catch (error, stackTrace) {
        result.completeError(error, stackTrace);
      }
    });

    return result.future;
  }
}
