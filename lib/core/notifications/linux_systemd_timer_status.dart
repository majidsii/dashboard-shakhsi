import 'linux_systemd_timer_name.dart';

enum LinuxSystemdLoadState {
  loaded,
  notFound,
  masked,
  error,
  badSetting,
  stub,
  merged,
}

enum LinuxSystemdActiveState {
  active,
  reloading,
  inactive,
  failed,
  activating,
  deactivating,
  maintenance,
  refreshing,
}

enum LinuxSystemdTimerSubState { dead, waiting, running, elapsed, failed }

enum LinuxSystemdUnitFileState {
  enabled,
  enabledRuntime,
  linked,
  linkedRuntime,
  alias,
  masked,
  maskedRuntime,
  staticState,
  disabled,
  indirect,
  generated,
  transient,
  bad,
}

enum LinuxSystemdUnitResult {
  success,
  resources,
  timeout,
  exitCode,
  signal,
  coreDump,
  watchdog,
  startLimitHit,
}

final class LinuxSystemdTimerStatus {
  const LinuxSystemdTimerStatus({
    required this.name,
    required this.loadState,
    required this.activeState,
    required this.subState,
    required this.unitFileState,
    required this.result,
  });

  final LinuxSystemdTimerName name;
  final LinuxSystemdLoadState loadState;
  final LinuxSystemdActiveState activeState;
  final LinuxSystemdTimerSubState subState;
  final LinuxSystemdUnitFileState unitFileState;
  final LinuxSystemdUnitResult result;

  bool get isInstalled => loadState == LinuxSystemdLoadState.loaded;

  bool get isEnabled {
    return switch (unitFileState) {
      LinuxSystemdUnitFileState.enabled ||
      LinuxSystemdUnitFileState.enabledRuntime => true,
      _ => false,
    };
  }

  bool get isActive => activeState == LinuxSystemdActiveState.active;

  bool get isWaiting => subState == LinuxSystemdTimerSubState.waiting;

  bool get isHealthy {
    return isInstalled &&
        isEnabled &&
        isActive &&
        isWaiting &&
        result == LinuxSystemdUnitResult.success;
  }
}
