// Public constructor keeps the dependency name free of underscores.
// ignore_for_file: prefer_initializing_formals

import 'linux_notification_delivery_exception.dart';
import 'linux_notification_delivery_result.dart';
import 'native_notification_gateway.dart';
import 'notification_delivery_policy.dart';
import 'notification_payload_codec.dart';
import 'notification_schedule_repository.dart';
import 'stable_notification_id.dart';

abstract interface class LinuxNotificationDeliveryResources {
  NotificationScheduleRepository get repository;
  NativeNotificationGateway get gateway;

  Future<void> close();
}

abstract interface class LinuxNotificationDeliveryResourcesFactory {
  Future<LinuxNotificationDeliveryResources> open();
}

final class LinuxNotificationDeliveryService {
  LinuxNotificationDeliveryService({
    required LinuxNotificationDeliveryResourcesFactory resourcesFactory,
  }) : _resourcesFactory = resourcesFactory;

  final LinuxNotificationDeliveryResourcesFactory _resourcesFactory;

  Future<LinuxNotificationDeliveryResult> deliver(String scheduleId) async {
    LinuxNotificationDeliveryResources? resources;
    late LinuxNotificationDeliveryResult primary;
    final closeFailures = <LinuxNotificationDeliveryCloseFailure>[];

    try {
      final openedResources = await _run(
        operation: LinuxNotificationDeliveryOperation.initialize,
        action: _resourcesFactory.open,
      );
      resources = openedResources;

      final request = await _run(
        operation: LinuxNotificationDeliveryOperation.lookup,
        action: () => openedResources.repository.getById(scheduleId),
      );

      if (request == null) {
        primary = LinuxNotificationDeliveryResult.missingRequest();
      } else {
        final content = NotificationDeliveryPolicy.contentFor(request);
        final payload = NotificationPayloadCodec.encode(request);
        final id = StableNotificationId.fromScheduleId(request.scheduleId);

        await _run<void>(
          operation: LinuxNotificationDeliveryOperation.display,
          action: () => openedResources.gateway.showNow(
            id: id,
            title: content.title,
            body: content.body,
            payload: payload,
          ),
        );

        primary = LinuxNotificationDeliveryResult.delivered();
      }
    } on LinuxNotificationDeliveryException catch (error) {
      primary = _resultFor(error);
    } finally {
      final openedResources = resources;
      if (openedResources != null) {
        try {
          await openedResources.close();
        } catch (error, stackTrace) {
          final closeException =
              LinuxNotificationDeliveryException.forOperation(
                operation: LinuxNotificationDeliveryOperation.close,
                cause: error,
                causeStackTrace: stackTrace,
              );
          closeFailures.add(
            LinuxNotificationDeliveryCloseFailure(
              error: closeException.cause,
              stackTrace: closeException.causeStackTrace,
            ),
          );
        }
      }
    }

    return closeFailures.isEmpty
        ? primary
        : primary.withCloseFailures(closeFailures);
  }

  Future<T> _run<T>({
    required LinuxNotificationDeliveryOperation operation,
    required Future<T> Function() action,
  }) async {
    try {
      return await action();
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(
        LinuxNotificationDeliveryException.forOperation(
          operation: operation,
          cause: error,
          causeStackTrace: stackTrace,
        ),
        stackTrace,
      );
    }
  }

  LinuxNotificationDeliveryResult _resultFor(
    LinuxNotificationDeliveryException error,
  ) {
    return switch (error.failure) {
      LinuxNotificationDeliveryFailure.initializationFailed =>
        LinuxNotificationDeliveryResult.initializationFailed(
          error.cause,
          error.causeStackTrace,
        ),
      LinuxNotificationDeliveryFailure.lookupFailed =>
        LinuxNotificationDeliveryResult.lookupFailed(
          error.cause,
          error.causeStackTrace,
        ),
      LinuxNotificationDeliveryFailure.displayFailed =>
        LinuxNotificationDeliveryResult.displayFailed(
          error.cause,
          error.causeStackTrace,
        ),
      LinuxNotificationDeliveryFailure.closeFailed => throw StateError(
        'Close failures are appended after a primary delivery result.',
      ),
    };
  }
}
