import 'local_notifications_initializer.dart';
import 'notification_coordinator.dart';

abstract interface class NotificationStartup {
  Future<void> initialize();
}

final class NotificationStartupService implements NotificationStartup {
  factory NotificationStartupService({
    required bool enabled,
    required LocalNotificationsInitializer initializer,
    required NotificationCoordinator coordinator,
  }) {
    return NotificationStartupService._(enabled, initializer, coordinator);
  }

  NotificationStartupService._(
    this._enabled,
    this._initializer,
    this._coordinator,
  );

  final bool _enabled;
  final LocalNotificationsInitializer _initializer;
  final NotificationCoordinator _coordinator;

  Future<void>? _initialization;

  @override
  Future<void> initialize() {
    final existing = _initialization;
    if (existing != null) {
      return existing;
    }

    final initialization = _run();
    _initialization = initialization;
    return initialization.then<void>(
      (_) {},
      onError: (Object error, StackTrace stackTrace) {
        _initialization = null;
        Error.throwWithStackTrace(error, stackTrace);
      },
    );
  }

  Future<void> _run() async {
    if (!_enabled) {
      return;
    }

    await _initializer.initialize();
    await _coordinator.reconcileFromPersistence();
  }
}
