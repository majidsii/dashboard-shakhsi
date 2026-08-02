// Public named constructor parameters intentionally initialize private dependencies.
// ignore_for_file: prefer_initializing_formals

import 'linux_executable_path_source.dart';
import 'linux_notification_delivery_command_factory.dart';
import 'linux_notification_delivery_invocation.dart';
import 'linux_systemd_notification_unit.dart';
import 'notification_request.dart';

final class ResolvedLinuxNotificationDeliveryCommandFactory
    implements LinuxNotificationDeliveryCommandFactory {
  ResolvedLinuxNotificationDeliveryCommandFactory({
    required LinuxExecutablePathSource executablePathSource,
  }) : _executablePathSource = executablePathSource;

  final LinuxExecutablePathSource _executablePathSource;

  String? _resolvedExecutablePath;
  Future<String>? _resolutionInFlight;

  @override
  Future<LinuxSystemdNotificationUnit> create(
    NotificationRequest request,
  ) async {
    final executablePath = await _resolveExecutablePath();

    return LinuxSystemdNotificationUnit(
      scheduleKey: request.scheduleId,
      scheduledAtUtc: request.scheduledAtUtc,
      executablePath: executablePath,
      arguments: <String>[linuxNotificationDeliveryFlag, request.scheduleId],
    );
  }

  Future<String> _resolveExecutablePath() {
    final resolved = _resolvedExecutablePath;
    if (resolved != null) {
      return Future<String>.value(resolved);
    }

    final current = _resolutionInFlight;
    if (current != null) {
      return current;
    }

    final started = _resolveAndCache();
    _resolutionInFlight = started;
    return started;
  }

  Future<String> _resolveAndCache() async {
    try {
      final path = await _executablePathSource.resolve();
      _resolvedExecutablePath = path;
      return path;
    } finally {
      _resolutionInFlight = null;
    }
  }
}
