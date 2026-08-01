// ignore_for_file: prefer_initializing_formals

import 'dart:async';

import 'package:dashboard_shakhsi/core/date_time/app_clock.dart';

import 'async_fifo_keyed_mutex.dart';
import 'async_writer_preferring_rw_lock.dart';
import 'linux_notification_delivery_command_factory.dart';
import 'linux_notification_request_fingerprint.dart';
import 'linux_systemd_notification_scheduler_exception.dart';
import 'linux_systemd_notification_unit.dart';
import 'linux_systemd_schedule_registry.dart';
import 'linux_systemd_schedule_registry_store.dart';
import 'linux_systemd_timer_name.dart';
import 'linux_systemd_timer_status.dart';
import 'linux_systemd_unit_renderer.dart';
import 'linux_systemd_unit_transaction.dart';
import 'linux_systemd_user_driver.dart';
import 'native_notification_gateway.dart';
import 'notification_delivery_policy.dart';
import 'notification_owner.dart';
import 'notification_payload_codec.dart';
import 'notification_request.dart';
import 'notification_scheduler.dart';
import 'stable_notification_id.dart';

final class LinuxSystemdNotificationScheduler implements NotificationScheduler {
  LinuxSystemdNotificationScheduler({
    required AppClock clock,
    required NativeNotificationGateway gateway,
    required LinuxNotificationDeliveryCommandFactory commandFactory,
    required LinuxSystemdUnitRenderer renderer,
    required LinuxSystemdUnitStore unitStore,
    required LinuxSystemdUserDriver driver,
    required LinuxSystemdScheduleRegistryStore registryStore,
    required LinuxNotificationRequestFingerprint fingerprint,
    AsyncWriterPreferringRwLock? globalLock,
    AsyncFifoKeyedMutex<String>? scheduleMutex,
  }) : _clock = clock,
       _gateway = gateway,
       _commandFactory = commandFactory,
       _renderer = renderer,
       _unitStore = unitStore,
       _driver = driver,
       _registryStore = registryStore,
       _fingerprint = fingerprint,
       _globalLock = globalLock ?? AsyncWriterPreferringRwLock(),
       _scheduleMutex = scheduleMutex ?? AsyncFifoKeyedMutex<String>();

  final AppClock _clock;
  final NativeNotificationGateway _gateway;
  final LinuxNotificationDeliveryCommandFactory _commandFactory;
  final LinuxSystemdUnitRenderer _renderer;
  final LinuxSystemdUnitStore _unitStore;
  final LinuxSystemdUserDriver _driver;
  final LinuxSystemdScheduleRegistryStore _registryStore;
  final LinuxNotificationRequestFingerprint _fingerprint;
  final AsyncWriterPreferringRwLock _globalLock;
  final AsyncFifoKeyedMutex<String> _scheduleMutex;

  @override
  Future<void> schedule(NotificationRequest request) {
    return _globalLock.runRead(
      () => _scheduleMutex.synchronized(
        request.scheduleId,
        () => _scheduleUnlocked(request),
      ),
    );
  }

  @override
  Future<void> cancel(String scheduleId) {
    return _globalLock.runRead(
      () => _scheduleMutex.synchronized(
        scheduleId,
        () => _cancelUnlocked(
          scheduleId,
          operation: LinuxSystemdNotificationSchedulerOperation.cancel,
        ),
      ),
    );
  }

  @override
  Future<void> cancelByOwner(NotificationOwner owner) {
    return _globalLock.runWrite(() async {
      final registry = await _step(
        operation: LinuxSystemdNotificationSchedulerOperation.cancelByOwner,
        failure: LinuxSystemdNotificationSchedulerFailure.registryFailed,
        owner: owner,
        action: _registryStore.load,
      );
      final matches = registry.entries
          .where((entry) => entry.owner == owner)
          .toList(growable: false);

      if (matches.isEmpty) {
        return;
      }

      throw LinuxSystemdNotificationSchedulerException(
        operation: LinuxSystemdNotificationSchedulerOperation.cancelByOwner,
        failure:
            LinuxSystemdNotificationSchedulerFailure.partialOwnerCancellation,
        owner: owner,
      );
    });
  }

  @override
  Future<void> reconcile(List<NotificationRequest> expected) {
    return _globalLock.runWrite(() async {
      if (expected.isEmpty) {
        return;
      }

      throw LinuxSystemdNotificationSchedulerException(
        operation: LinuxSystemdNotificationSchedulerOperation.reconcile,
        failure: LinuxSystemdNotificationSchedulerFailure.partialReconciliation,
      );
    });
  }

  Future<void> _scheduleUnlocked(NotificationRequest request) async {
    final operation = LinuxSystemdNotificationSchedulerOperation.schedule;
    final nowUtc = _clock.nowUtc().toUtc();

    if (!request.scheduledAtUtc.isAfter(nowUtc)) {
      await _cancelUnlocked(
        request.scheduleId,
        operation: operation,
        owner: request.owner,
      );

      final content = NotificationDeliveryPolicy.contentFor(request);
      await _step<void>(
        operation: operation,
        failure: LinuxSystemdNotificationSchedulerFailure.mutationFailed,
        scheduleId: request.scheduleId,
        owner: request.owner,
        names: LinuxSystemdUnitNames.forScheduleKey(request.scheduleId),
        action: () => _gateway.showNow(
          id: StableNotificationId.fromScheduleId(request.scheduleId),
          title: content.title,
          body: content.body,
          payload: NotificationPayloadCodec.encode(request),
        ),
      );
      return;
    }

    final requestFingerprint = await _step<String>(
      operation: operation,
      failure: LinuxSystemdNotificationSchedulerFailure.renderFailed,
      scheduleId: request.scheduleId,
      owner: request.owner,
      action: () => _fingerprint.compute(request),
    );
    final names = LinuxSystemdUnitNames.forScheduleKey(request.scheduleId);
    final timerName = LinuxSystemdTimerName.parse(names.timerFileName);
    final registry = await _step<LinuxSystemdScheduleRegistry>(
      operation: operation,
      failure: LinuxSystemdNotificationSchedulerFailure.registryFailed,
      scheduleId: request.scheduleId,
      owner: request.owner,
      names: names,
      action: _registryStore.load,
    );
    final previous = registry.entryForScheduleId(request.scheduleId);

    if (previous != null && previous.requestFingerprint == requestFingerprint) {
      final status = await _step<LinuxSystemdTimerStatus>(
        operation: operation,
        failure: LinuxSystemdNotificationSchedulerFailure.mutationFailed,
        scheduleId: request.scheduleId,
        owner: request.owner,
        names: names,
        action: () => _driver.status(timerName),
      );

      if (status.isHealthy) {
        return;
      }
    }

    final unit = await _step(
      operation: operation,
      failure: LinuxSystemdNotificationSchedulerFailure.commandFactoryFailed,
      scheduleId: request.scheduleId,
      owner: request.owner,
      names: names,
      action: () => _commandFactory.create(request),
    );
    final rendered = await _step(
      operation: operation,
      failure: LinuxSystemdNotificationSchedulerFailure.renderFailed,
      scheduleId: request.scheduleId,
      owner: request.owner,
      names: names,
      action: () => _renderer.render(unit),
    );

    if (rendered.serviceFileName != names.serviceFileName ||
        rendered.timerFileName != names.timerFileName) {
      throw LinuxSystemdNotificationSchedulerException(
        operation: operation,
        failure: LinuxSystemdNotificationSchedulerFailure.renderFailed,
        scheduleId: request.scheduleId,
        owner: request.owner,
        names: names,
        cause: StateError(
          'Rendered unit names do not match the schedule identity.',
        ),
        causeStackTrace: StackTrace.current,
      );
    }

    final transaction = await _step<LinuxSystemdUnitInstallTransaction>(
      operation: operation,
      failure: LinuxSystemdNotificationSchedulerFailure.unitTransactionFailed,
      scheduleId: request.scheduleId,
      owner: request.owner,
      names: names,
      action: () => _unitStore.beginInstall(rendered),
    );

    if (transaction.names != names) {
      throw LinuxSystemdNotificationSchedulerException(
        operation: operation,
        failure: LinuxSystemdNotificationSchedulerFailure.unitTransactionFailed,
        scheduleId: request.scheduleId,
        owner: request.owner,
        names: names,
        cause: StateError(
          'Unit transaction identity does not match the schedule.',
        ),
        causeStackTrace: StackTrace.current,
      );
    }

    await _step<void>(
      operation: operation,
      failure: LinuxSystemdNotificationSchedulerFailure.unitTransactionFailed,
      scheduleId: request.scheduleId,
      owner: request.owner,
      names: names,
      action: transaction.apply,
    );
    await _step<void>(
      operation: operation,
      failure: LinuxSystemdNotificationSchedulerFailure.daemonReloadFailed,
      scheduleId: request.scheduleId,
      owner: request.owner,
      names: names,
      action: _driver.reloadDaemon,
    );
    final confirmedStatus = await _step<LinuxSystemdTimerStatus>(
      operation: operation,
      failure: LinuxSystemdNotificationSchedulerFailure.mutationFailed,
      scheduleId: request.scheduleId,
      owner: request.owner,
      names: names,
      action: () => _driver.enableAndStart(timerName),
    );

    if (!confirmedStatus.isHealthy) {
      throw LinuxSystemdNotificationSchedulerException(
        operation: operation,
        failure: LinuxSystemdNotificationSchedulerFailure.mutationFailed,
        scheduleId: request.scheduleId,
        owner: request.owner,
        names: names,
        cause: StateError(
          'Enabled timer did not reach the healthy waiting state.',
        ),
        causeStackTrace: StackTrace.current,
        confirmedStatus: confirmedStatus,
      );
    }

    final nextEntry = LinuxSystemdScheduleRegistryEntry(
      scheduleId: request.scheduleId,
      owner: request.owner,
      timerName: timerName,
      serviceFileName: names.serviceFileName,
      scheduledAtUtc: request.scheduledAtUtc,
      requestFingerprint: requestFingerprint,
    );
    final nextRegistry = LinuxSystemdScheduleRegistry(
      schemaVersion: LinuxSystemdScheduleRegistry.currentSchemaVersion,
      generation: registry.generation + 1,
      entries: <LinuxSystemdScheduleRegistryEntry>[
        for (final entry in registry.entries)
          if (entry.scheduleId != request.scheduleId) entry,
        nextEntry,
      ],
    );

    await _step<void>(
      operation: operation,
      failure: LinuxSystemdNotificationSchedulerFailure.registryFailed,
      scheduleId: request.scheduleId,
      owner: request.owner,
      names: names,
      action: () => _registryStore.replace(nextRegistry),
    );
    await _step<void>(
      operation: operation,
      failure: LinuxSystemdNotificationSchedulerFailure.unitTransactionFailed,
      scheduleId: request.scheduleId,
      owner: request.owner,
      names: names,
      action: transaction.finalize,
    );
  }

  Future<void> _cancelUnlocked(
    String scheduleId, {
    required LinuxSystemdNotificationSchedulerOperation operation,
    NotificationOwner? owner,
  }) async {
    final names = LinuxSystemdUnitNames.forScheduleKey(scheduleId);
    final registry = await _step<LinuxSystemdScheduleRegistry>(
      operation: operation,
      failure: LinuxSystemdNotificationSchedulerFailure.registryFailed,
      scheduleId: scheduleId,
      owner: owner,
      names: names,
      action: _registryStore.load,
    );
    final existing = registry.entryForScheduleId(scheduleId);

    if (existing == null) {
      return;
    }

    final transaction = await _step<LinuxSystemdUnitRemoveTransaction>(
      operation: operation,
      failure: LinuxSystemdNotificationSchedulerFailure.unitTransactionFailed,
      scheduleId: scheduleId,
      owner: owner ?? existing.owner,
      names: names,
      action: () => _unitStore.beginRemove(names),
    );
    final timerName = LinuxSystemdTimerName.parse(names.timerFileName);

    await _step<LinuxSystemdTimerStatus>(
      operation: operation,
      failure: LinuxSystemdNotificationSchedulerFailure.mutationFailed,
      scheduleId: scheduleId,
      owner: owner ?? existing.owner,
      names: names,
      action: () => _driver.disableAndStop(timerName),
    );
    await _step<void>(
      operation: operation,
      failure: LinuxSystemdNotificationSchedulerFailure.unitTransactionFailed,
      scheduleId: scheduleId,
      owner: owner ?? existing.owner,
      names: names,
      action: transaction.apply,
    );
    await _step<void>(
      operation: operation,
      failure: LinuxSystemdNotificationSchedulerFailure.daemonReloadFailed,
      scheduleId: scheduleId,
      owner: owner ?? existing.owner,
      names: names,
      action: _driver.reloadDaemon,
    );

    final nextRegistry = LinuxSystemdScheduleRegistry(
      schemaVersion: LinuxSystemdScheduleRegistry.currentSchemaVersion,
      generation: registry.generation + 1,
      entries: registry.entries.where(
        (entry) => entry.scheduleId != scheduleId,
      ),
    );

    await _step<void>(
      operation: operation,
      failure: LinuxSystemdNotificationSchedulerFailure.registryFailed,
      scheduleId: scheduleId,
      owner: owner ?? existing.owner,
      names: names,
      action: () => _registryStore.replace(nextRegistry),
    );
    await _step<void>(
      operation: operation,
      failure: LinuxSystemdNotificationSchedulerFailure.unitTransactionFailed,
      scheduleId: scheduleId,
      owner: owner ?? existing.owner,
      names: names,
      action: transaction.finalize,
    );
  }

  Future<T> _step<T>({
    required LinuxSystemdNotificationSchedulerOperation operation,
    required LinuxSystemdNotificationSchedulerFailure failure,
    required FutureOr<T> Function() action,
    String? scheduleId,
    NotificationOwner? owner,
    LinuxSystemdUnitNames? names,
  }) async {
    try {
      return await Future<T>.sync(action);
    } on LinuxSystemdNotificationSchedulerException {
      rethrow;
    } catch (error, stackTrace) {
      throw LinuxSystemdNotificationSchedulerException(
        operation: operation,
        failure: failure,
        scheduleId: scheduleId,
        owner: owner,
        names: names,
        cause: error,
        causeStackTrace: stackTrace,
      );
    }
  }
}
