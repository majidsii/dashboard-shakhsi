#!/usr/bin/env python3
from pathlib import Path
import re
import sys

paths = {
    "provider": Path(
        "lib/core/notifications/notification_platform_providers.dart"
    ),
    "test": Path(
        "test/core/notifications/"
        "notification_platform_providers_test.dart"
    ),
}

for label, path in paths.items():
    if not path.is_file():
        print(f"ERROR: missing Task 10.6.6 {label}: {path}")
        sys.exit(1)

provider = paths["provider"].read_text(encoding="utf-8")
test = paths["test"].read_text(encoding="utf-8")

required_provider = (
    "final notificationHostPlatformProvider",
    "Provider<NotificationHostPlatform>",
    "detectNotificationHostPlatform(",
    "isWeb: kIsWeb",
    "platform: defaultTargetPlatform",
    "final notificationClockProvider",
    "final notificationPlatformCapabilitiesProvider",
    "NotificationPlatformCapabilities.forPlatform(",
    "final flutterLocalNotificationsDriverProvider",
    "FlutterLocalNotificationsDriver(",
    "LocalNotificationPluginConfig.defaults()",
    "final nativeNotificationGatewayProvider",
    "final platformNotificationSchedulerProvider",
    "PlatformNotificationScheduler(",
    "final noopNotificationSchedulerProvider",
    "NoopNotificationScheduler()",
    "final linuxExecutablePathSourceProvider",
    "ValidatedLinuxExecutablePathSource(",
    "DartIoLinuxExecutablePathSource()",
    "DartIoLinuxExecutableFileVerifier()",
    "final linuxNotificationDeliveryCommandFactoryProvider",
    "ResolvedLinuxNotificationDeliveryCommandFactory(",
    "final linuxSystemdFileSystemProvider",
    "DartIoLinuxSystemdFileSystem()",
    "final linuxSystemdRegistryStoreProvider",
    "LinuxSystemdScheduleRegistryFileStore(",
    "final linuxSystemdUnitStoreProvider",
    "LinuxSystemdUserUnitStore(",
    "final linuxSystemdUserDriverProvider",
    "LinuxSystemdUserDriver(",
    "final linuxSystemdNotificationSchedulerProvider",
    "LinuxSystemdNotificationScheduler(",
    "final notificationSchedulerProvider",
    "Provider<NotificationScheduler>",
    "return switch (ref.watch(notificationHostPlatformProvider))",
    "NotificationHostPlatform.linux =>",
    "NotificationHostPlatform.android ||",
    "NotificationHostPlatform.macos ||",
    "NotificationHostPlatform.windows =>",
    "NotificationHostPlatform.unsupported =>",
)
missing_provider = [
    token for token in required_provider if token not in provider
]
if missing_provider:
    print(
        "ERROR: lazy platform provider composition incomplete: "
        f"{missing_provider}"
    )
    sys.exit(1)

# The scheduler switch must not pre-read providers into eager local variables.
scheduler_start = provider.find("final notificationSchedulerProvider")
if scheduler_start < 0:
    print("ERROR: notificationSchedulerProvider is missing.")
    sys.exit(1)
scheduler_source = provider[scheduler_start:]

for forbidden in (
    "final linuxScheduler =",
    "final platformScheduler =",
    "final noopScheduler =",
    "ref.read(linuxSystemdNotificationSchedulerProvider)",
):
    if forbidden in scheduler_source:
        print(
            "ERROR: scheduler selection eagerly resolves a branch: "
            f"{forbidden}"
        )
        sys.exit(1)

def _watch_pattern(provider_name: str) -> re.Pattern[str]:
    return re.compile(
        rf"ref\.watch\(\s*{re.escape(provider_name)}\s*,?\s*\)",
        flags=re.MULTILINE,
    )


branch_patterns = {
    "Linux": re.compile(
        r"NotificationHostPlatform\.linux\s*=>\s*"
        r"ref\.watch\(\s*linuxSystemdNotificationSchedulerProvider"
        r"\s*,?\s*\)",
        flags=re.MULTILINE,
    ),
    "native": re.compile(
        r"NotificationHostPlatform\.android\s*\|\|\s*"
        r"NotificationHostPlatform\.macos\s*\|\|\s*"
        r"NotificationHostPlatform\.windows\s*=>\s*"
        r"ref\.watch\(\s*platformNotificationSchedulerProvider"
        r"\s*,?\s*\)",
        flags=re.MULTILINE,
    ),
    "unsupported": re.compile(
        r"NotificationHostPlatform\.unsupported\s*=>\s*"
        r"ref\.watch\(\s*noopNotificationSchedulerProvider"
        r"\s*,?\s*\)",
        flags=re.MULTILINE,
    ),
}

watch_expectations = {
    "linuxSystemdNotificationSchedulerProvider": "Linux",
    "platformNotificationSchedulerProvider": "native",
    "noopNotificationSchedulerProvider": "unsupported",
}

for provider_name, branch_name in watch_expectations.items():
    count = len(_watch_pattern(provider_name).findall(scheduler_source))
    if count != 1:
        print(
            "ERROR: scheduler provider must be watched exactly once: "
            f"{provider_name}; found {count}."
        )
        sys.exit(1)

    if branch_patterns[branch_name].search(scheduler_source) is None:
        print(
            "ERROR: scheduler provider is not confined to its expected "
            f"{branch_name} switch branch: {provider_name}."
        )
        sys.exit(1)

# Production Linux providers must stay separate, so non-Linux branches can
# avoid resolving filesystem, executable, process, registry, and systemd state.
linux_provider_names = (
    "linuxExecutablePathSourceProvider",
    "linuxNotificationDeliveryCommandFactoryProvider",
    "linuxSystemdEnvironmentProvider",
    "linuxSystemdUserUnitPathResolverProvider",
    "linuxSystemdFileSystemProvider",
    "linuxSystemdScheduleRegistryCodecProvider",
    "linuxSystemdTransactionIdFactoryProvider",
    "linuxSystemdRegistryStoreProvider",
    "linuxSystemdUnitRendererProvider",
    "linuxProcessRunnerProvider",
    "linuxSystemdUserDriverProvider",
    "linuxSystemdUnitStoreProvider",
    "linuxNotificationRequestFingerprintProvider",
    "linuxSystemdNotificationSchedulerProvider",
)
for name in linux_provider_names:
    if provider.count(f"final {name}") != 1:
        print(f"ERROR: Linux dependency is not a separate provider: {name}")
        sys.exit(1)

required_tests = (
    "selects the Linux systemd scheduler on Linux",
    "selects the native platform scheduler on",
    "selects the noop scheduler on unsupported hosts",
    "does not construct Linux dependencies on",
    "Linux branch does not construct platform or noop schedulers",
    "unsupported branch constructs neither native nor Linux scheduler",
    "selected scheduler identity is cached by the provider container",
    "host platform is injectable without dart:io platform checks",
    "linuxSystemdNotificationSchedulerProvider.overrideWith",
    "platformNotificationSchedulerProvider.overrideWith",
    "noopNotificationSchedulerProvider.overrideWith",
    "expect(linuxConstructionCount, 0)",
)
missing_tests = [token for token in required_tests if token not in test]
if missing_tests:
    print(f"ERROR: Task 10.6.6 GREEN coverage incomplete: {missing_tests}")
    sys.exit(1)

# Existing legacy provider libraries, when present, must alias the new provider
# objects rather than keeping a second eager scheduler graph.
legacy_declarations: list[str] = []
for path in Path("lib").rglob("*.dart"):
    if path == paths["provider"]:
        continue
    source = path.read_text(encoding="utf-8")
    for name in (
        "notificationHostPlatformProvider",
        "notificationSchedulerProvider",
    ):
        pattern = re.compile(
            rf"(?m)^final\s+(?:[A-Za-z0-9_<>,?\s]+\s+)?{name}\s*="
        )
        if pattern.search(source) is None:
            continue
        alias = f"notification_platform.{name};"
        if alias not in source:
            legacy_declarations.append(f"{path}:{name}")

if legacy_declarations:
    print(
        "ERROR: legacy platform provider declarations were not aliased to "
        f"the lazy composition: {legacy_declarations}"
    )
    sys.exit(1)

for forbidden in (
    "Platform.isLinux",
    "Platform.isAndroid",
    "Platform.isMacOS",
    "Platform.isWindows",
    "Future.delayed(",
    "Process.start",
    "Process.run",
    "TODO",
    "FIXME",
    "UnimplementedError",
):
    if forbidden in provider or forbidden in test:
        print(f"ERROR: Task 10.6.6 contains forbidden behavior: {forbidden}")
        sys.exit(1)


persistence_path = Path("lib/core/providers/persistence_providers.dart")
runtime_provider_test_path = Path(
    "test/core/providers/notification_runtime_providers_test.dart"
)

for label, path in (
    ("legacy provider file", persistence_path),
    ("legacy runtime provider test", runtime_provider_test_path),
):
    if not path.is_file():
        print(f"ERROR: missing {label}: {path}")
        sys.exit(1)

persistence_source = persistence_path.read_text(encoding="utf-8")
runtime_provider_test = runtime_provider_test_path.read_text(
    encoding="utf-8"
)

unused_legacy_imports = (
    "flutter_local_notifications_driver.dart",
    "native_notification_gateway.dart",
    "noop_notification_scheduler.dart",
    "notification_host_platform.dart",
    "notification_platform_capabilities.dart",
    "notification_scheduler.dart",
    "platform_notification_scheduler.dart",
    "package:flutter/foundation.dart",
)
remaining_unused_imports = [
    token for token in unused_legacy_imports
    if token in persistence_source
]
if remaining_unused_imports:
    print(
        "ERROR: legacy provider aliases retain unused concrete imports: "
        f"{remaining_unused_imports}"
    )
    sys.exit(1)

for token in (
    "notification_platform.notificationHostPlatformProvider",
    "notification_platform.notificationSchedulerProvider",
):
    if token not in persistence_source:
        print(f"ERROR: legacy provider alias is missing: {token}")
        sys.exit(1)

runtime_title = "Linux provider graph uses systemd scheduler"
runtime_index = runtime_provider_test.find(runtime_title)
if runtime_index < 0:
    print("ERROR: Linux runtime provider regression test was not migrated.")
    sys.exit(1)

runtime_next = runtime_provider_test.find(
    "\n  test(",
    runtime_index + len(runtime_title),
)
runtime_block = runtime_provider_test[
    runtime_index:
    runtime_next if runtime_next >= 0 else len(runtime_provider_test)
]

if "isA<LinuxSystemdNotificationScheduler>()" not in runtime_block:
    print(
        "ERROR: legacy Linux runtime test does not expect the systemd "
        "scheduler."
    )
    sys.exit(1)

if "isA<PlatformNotificationScheduler>()" in runtime_block:
    print(
        "ERROR: legacy Linux runtime test still expects the plugin scheduler."
    )
    sys.exit(1)


print(
    "OK: Task 10.6.6 GREEN provides injectable host detection, lazy branch-only "
    "selection of Linux systemd, native platform, and noop schedulers, separate "
    "Linux executable/filesystem/process/registry/unit-store factories, complete "
    "production Linux scheduler composition, provider identity caching, no "
    "domain Platform.isLinux checks, non-Linux protection from Linux dependency "
    "construction, and compatibility aliases for any legacy provider call sites."
)
