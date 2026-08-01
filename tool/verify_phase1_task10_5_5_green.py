#!/usr/bin/env python3
from pathlib import Path
import sys

paths = {
    "scheduler": Path(
        "lib/core/notifications/"
        "linux_systemd_notification_scheduler.dart"
    ),
    "unit_store_fake": Path(
        "test/support/fake_linux_systemd_unit_store.dart"
    ),
    "registry_fake": Path(
        "test/support/"
        "fake_linux_systemd_schedule_registry_store.dart"
    ),
    "gateway_fake": Path(
        "test/support/"
        "recording_native_notification_gateway.dart"
    ),
    "process_runner": Path(
        "test/support/controlled_linux_process_runner.dart"
    ),
    "test": Path(
        "test/core/notifications/"
        "linux_systemd_notification_scheduler_schedule_test.dart"
    ),
}

for label, path in paths.items():
    if not path.exists():
        print(f"ERROR: missing Task 10.5.5 {label}: {path}")
        sys.exit(1)

scheduler = paths["scheduler"].read_text(encoding="utf-8")
unit_store = paths["unit_store_fake"].read_text(encoding="utf-8")
registry = paths["registry_fake"].read_text(encoding="utf-8")
gateway = paths["gateway_fake"].read_text(encoding="utf-8")
runner = paths["process_runner"].read_text(encoding="utf-8")
test = paths["test"].read_text(encoding="utf-8")

required_scheduler = [
    "final class LinuxSystemdNotificationScheduler",
    "implements NotificationScheduler",
    "required AppClock clock",
    "required NativeNotificationGateway gateway",
    "required LinuxNotificationDeliveryCommandFactory commandFactory",
    "required LinuxSystemdUnitRenderer renderer",
    "required LinuxSystemdUnitStore unitStore",
    "required LinuxSystemdUserDriver driver",
    "required LinuxSystemdScheduleRegistryStore registryStore",
    "required LinuxNotificationRequestFingerprint fingerprint",
    "_globalLock.runRead",
    "_scheduleMutex.synchronized",
    "if (!request.scheduledAtUtc.isAfter(nowUtc))",
    "await _cancelUnlocked(",
    "NotificationDeliveryPolicy.contentFor(request)",
    "NotificationPayloadCodec.encode(request)",
    "_fingerprint.compute(request)",
    "LinuxSystemdUnitNames.forScheduleKey(",
    "_registryStore.load",
    "previous.requestFingerprint == requestFingerprint",
    "_driver.status(timerName)",
    "if (status.isHealthy)",
    "_commandFactory.create(request)",
    "_renderer.render(unit)",
    "_unitStore.beginInstall(rendered)",
    "transaction.apply",
    "_driver.reloadDaemon",
    "_driver.enableAndStart(timerName)",
    "if (!confirmedStatus.isHealthy)",
    "_registryStore.replace(nextRegistry)",
    "transaction.finalize",
    "generation: registry.generation + 1",
    "partialOwnerCancellation",
    "LinuxSystemdNotificationSchedulerFailure",
    ".partialReconciliation",
]
required_unit_store = [
    "implements LinuxSystemdUnitStore",
    "unitStore.beginInstall",
    "install.apply",
    "install.finalize",
    "unitStore.beginRemove",
    "remove.apply",
    "remove.finalize",
]
required_registry = [
    "implements LinuxSystemdScheduleRegistryStore",
    "registry.load",
    "registry.replace",
    "LinuxSystemdScheduleRegistry current",
    "final List<LinuxSystemdScheduleRegistry> replacements",
]
required_gateway = [
    "implements NativeNotificationGateway",
    "gateway.showNow",
    "RecordingNativeNotificationCall",
]
required_runner = [
    "implements LinuxProcessRunner",
    "driver.reload",
    "driver.status",
    "driver.enable",
    "driver.disable",
    "enqueueStatus(",
    "LinuxProcessResult(",
]
required_test = [
    "uses the exact successful component-operation order",
    "same fingerprint plus healthy status performs no mutation",
    "same fingerprint plus unhealthy status repairs",
    "changed fingerprint replaces without a preliminary status check",
    "first future schedule creates generation one",
    "successful entry contains exact owner time names and fingerprint",
    "removes stale registered state completely before showNow",
    "uses privacy content and the canonical encoded payload",
    "cancelByOwner is a no-op only when no registered entry matches",
    "reconcile accepts empty input and rejects non-empty input typed",
]

for label, text, required in (
    ("scheduler", scheduler, required_scheduler),
    ("unit-store fake", unit_store, required_unit_store),
    ("registry fake", registry, required_registry),
    ("gateway fake", gateway, required_gateway),
    ("controlled runner", runner, required_runner),
    ("Gate tests", test, required_test),
):
    missing = [token for token in required if token not in text]
    if missing:
        print(f"ERROR: incomplete {label}: {missing}")
        sys.exit(1)

combined = "\n".join(
    (scheduler, unit_store, registry, gateway, runner)
)

for forbidden in (
    "dart:io",
    "Process.start",
    "Process.run",
    "Directory.systemTemp",
    "UnimplementedError",
    "TODO",
    "FIXME",
):
    if forbidden in combined:
        print(
            "ERROR: Task 10.5.5 contains direct IO, process execution, "
            f"or placeholder behavior: {forbidden}"
        )
        sys.exit(1)

if "'0' * 64" in test or "'1' * 64" in test:
    print("ERROR: Gate test contains non-Dart string multiplication.")
    sys.exit(1)

due_index = scheduler.find(
    "if (!request.scheduledAtUtc.isAfter(nowUtc))"
)
cancel_index = scheduler.find(
    "await _cancelUnlocked(",
    due_index,
)
show_index = scheduler.find(
    "_gateway.showNow(",
    due_index,
)
if not (-1 < due_index < cancel_index < show_index):
    print("ERROR: due flow does not cancel before showNow.")
    sys.exit(1)

fingerprint_index = scheduler.find("_fingerprint.compute(request)")
names_index = scheduler.find(
    "final names = LinuxSystemdUnitNames.forScheduleKey(",
    fingerprint_index,
)
load_index = scheduler.find(
    "action: _registryStore.load",
    names_index,
)
factory_index = scheduler.find(
    "_commandFactory.create(request)",
    load_index,
)
render_index = scheduler.find("_renderer.render(unit)", factory_index)
begin_index = scheduler.find(
    "_unitStore.beginInstall(rendered)",
    render_index,
)
apply_index = scheduler.find("action: transaction.apply", begin_index)
reload_index = scheduler.find(
    "action: _driver.reloadDaemon",
    apply_index,
)
enable_index = scheduler.find(
    "_driver.enableAndStart(timerName)",
    reload_index,
)
replace_index = scheduler.find(
    "_registryStore.replace(nextRegistry)",
    enable_index,
)
finalize_index = scheduler.find(
    "action: transaction.finalize",
    replace_index,
)

if not (
    -1
    < fingerprint_index
    < names_index
    < load_index
    < factory_index
    < render_index
    < begin_index
    < apply_index
    < reload_index
    < enable_index
    < replace_index
    < finalize_index
):
    print("ERROR: future schedule operation order is incorrect.")
    sys.exit(1)

same_fingerprint_index = scheduler.find(
    "previous.requestFingerprint == requestFingerprint"
)
status_index = scheduler.find(
    "_driver.status(timerName)",
    same_fingerprint_index,
)
healthy_return_index = scheduler.find(
    "if (status.isHealthy)",
    status_index,
)
if not (
    -1
    < same_fingerprint_index
    < status_index
    < healthy_return_index
    < factory_index
):
    print(
        "ERROR: healthy same-fingerprint status check is not before "
        "render/install."
    )
    sys.exit(1)

cancel_begin_index = scheduler.find(
    "_unitStore.beginRemove(names)"
)
cancel_disable_index = scheduler.find(
    "_driver.disableAndStop(timerName)",
    cancel_begin_index,
)
cancel_apply_index = scheduler.find(
    "action: transaction.apply",
    cancel_disable_index,
)
cancel_reload_index = scheduler.find(
    "action: _driver.reloadDaemon",
    cancel_apply_index,
)
cancel_replace_index = scheduler.find(
    "_registryStore.replace(nextRegistry)",
    cancel_reload_index,
)
cancel_finalize_index = scheduler.find(
    "action: transaction.finalize",
    cancel_replace_index,
)

if not (
    -1
    < cancel_begin_index
    < cancel_disable_index
    < cancel_apply_index
    < cancel_reload_index
    < cancel_replace_index
    < cancel_finalize_index
):
    print("ERROR: private cancel operation order is incorrect.")
    sys.exit(1)

print(
    "OK: Task 10.5.5 GREEN implements locked due and future scheduling, "
    "stale-state cleanup before immediate delivery, privacy-aware payload "
    "delivery, fingerprint/status idempotence, unhealthy and changed repair, "
    "retained install ordering, healthy postcondition enforcement, generation "
    "updates with exact registry metadata, typed temporary batch behavior, "
    "and deterministic fakes without real filesystem or systemd access."
)
