import 'dart:io';

/// Read-only source for Linux systemd-related environment variables.
abstract interface class LinuxSystemdEnvironment {
  String? value(String name);
}

/// Production environment source backed by [Platform.environment].
final class PlatformLinuxSystemdEnvironment implements LinuxSystemdEnvironment {
  const PlatformLinuxSystemdEnvironment();

  @override
  String? value(String name) => Platform.environment[name];
}
