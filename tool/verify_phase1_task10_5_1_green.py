#!/usr/bin/env python3
from pathlib import Path
import sys

paths = {
    "transaction": Path(
        "lib/core/notifications/linux_systemd_unit_transaction.dart"
    ),
    "exception": Path(
        "lib/core/notifications/"
        "linux_systemd_user_unit_store_exception.dart"
    ),
    "test": Path(
        "test/core/notifications/"
        "linux_systemd_unit_transaction_model_test.dart"
    ),
}

for label, path in paths.items():
    if not path.exists():
        print(f"ERROR: missing Task 10.5.1 {label}: {path}")
        sys.exit(1)

transaction = paths["transaction"].read_text(encoding="utf-8")
exception = paths["exception"].read_text(encoding="utf-8")
test = paths["test"].read_text(encoding="utf-8")

required_transaction = [
    "enum LinuxSystemdUnitTransactionState",
    "pending",
    "applied",
    "finalized",
    "rolledBack",
    "abstract interface class LinuxSystemdUnitInstallTransaction",
    "abstract interface class LinuxSystemdUnitRemoveTransaction",
    "abstract interface class LinuxSystemdUnitStore",
    "LinuxSystemdUnitNames get names",
    "LinuxSystemdUnitTransactionState get state",
    "Future<void> apply()",
    "Future<void> finalize()",
    "Future<void> rollback()",
    "Future<LinuxSystemdUnitInstallTransaction> beginInstall(",
    "Future<LinuxSystemdUnitRemoveTransaction> beginRemove(",
    "Future<void> install(LinuxSystemdRenderedUnits units)",
    "Future<void> remove(LinuxSystemdUnitNames names)",
]
required_exception = [
    "install",
    "remove",
    "beginInstall",
    "beginRemove",
    "applyInstall",
    "finalizeInstall",
    "rollbackInstall",
    "applyRemove",
    "finalizeRemove",
    "rollbackRemove",
    "enum LinuxSystemdUserUnitTransactionFailure",
    "invalidState",
    "filesystemFailure",
    "LinuxSystemdUserUnitTransactionFailure? transactionFailure",
    "List<LinuxSystemdRollbackFailure>.unmodifiable",
    "transactionFailure?.name ?? 'none'",
    "rollbackFailures: ${rollbackFailures.length}",
]
required_test = [
    "exposes the exact retained transaction lifecycle",
    "retains legacy wrapper operations and adds transaction phases",
    "apply is idempotent after successful application",
    "rollback is idempotent after successful rollback",
    "begins install and remove transactions with stable names",
    "toString includes safe context but never nested error text",
]

for label, text, required in (
    ("transaction contracts", transaction, required_transaction),
    ("store exception", exception, required_exception),
    ("Gate tests", test, required_test),
):
    missing = [token for token in required if token not in text]
    if missing:
        print(f"ERROR: incomplete {label}: {missing}")
        sys.exit(1)

combined = f"{transaction}\n{exception}"

for forbidden in (
    "dart:io",
    "Process.start",
    "Process.run",
    "systemctl",
    "serviceContents",
    "timerContents",
    "title",
    "body",
    "payload",
    "UnimplementedError",
):
    if forbidden in combined:
        print(
            "ERROR: Task 10.5.1 contains process, sensitive-content, "
            f"or placeholder coupling: {forbidden}"
        )
        sys.exit(1)

to_string_start = exception.find("String toString()")
to_string_body = exception[to_string_start:]
for forbidden in (
    "'cause:",
    "$cause",
    ".error",
    "$error",
    "stackTrace",
):
    if forbidden in to_string_body:
        print(
            "ERROR: store exception diagnostics expose nested failure "
            f"content: {forbidden}"
        )
        sys.exit(1)

if exception.count("enum LinuxSystemdUserUnitStoreOperation") != 1:
    print("ERROR: store operation enum must be defined exactly once.")
    sys.exit(1)

print(
    "OK: Task 10.5.1 GREEN defines retained install/remove transaction "
    "contracts, exact lifecycle states, injectable unit-store methods, "
    "legacy plus transaction operation metadata, safe lifecycle failure "
    "categories, immutable rollback details, and non-sensitive diagnostics."
)
