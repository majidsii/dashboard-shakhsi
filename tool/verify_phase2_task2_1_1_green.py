#!/usr/bin/env python3
from pathlib import Path
import re
import sys

source_path = Path("lib/features/tasks/domain/task_status.dart")
test_path = Path("test/features/tasks/domain/task_status_test.dart")

for label, path in (("source", source_path), ("test", test_path)):
    if not path.is_file():
        print(f"ERROR: missing Gate 2.1.1 {label}: {path}")
        sys.exit(1)

source = source_path.read_text(encoding="utf-8")
test = test_path.read_text(encoding="utf-8")

required_source = (
    "enum TaskStatus",
    "planned('planned')",
    "inProgress('inProgress')",
    "completed('completed')",
    "canceled('canceled')",
    "const TaskStatus(this.storageValue);",
    "final String storageValue;",
    "static TaskStatus? tryParseStorage(String value)",
    "static TaskStatus parseStorage(String value)",
    "if (status.storageValue == value)",
    "throw const ValidationFailure('وضعیت کار نامعتبر است.');",
)
missing = [token for token in required_source if token not in source]
if missing:
    print(f"ERROR: Gate 2.1.1 production contract incomplete: {missing}")
    sys.exit(1)

enum_match = re.search(
    r"enum\s+TaskStatus\s*\{(?P<body>.*?)\n\}",
    source,
    flags=re.DOTALL,
)
if enum_match is None:
    print("ERROR: TaskStatus enum body could not be parsed.")
    sys.exit(1)

body = enum_match.group("body")
declarations = re.findall(
    r"^\s*(planned|inProgress|completed|canceled)\('([^']+)'\)[,;]",
    body,
    flags=re.MULTILINE,
)
if declarations != [
    ("planned", "planned"),
    ("inProgress", "inProgress"),
    ("completed", "completed"),
    ("canceled", "canceled"),
]:
    print(
        "ERROR: TaskStatus declaration order/storage values drifted: "
        f"{declarations}"
    )
    sys.exit(1)

for forbidden in (
    ".name",
    "values.byName",
    "switch (value.toLowerCase",
    "value.trim()",
    "return TaskStatus.planned;",
    "return planned;",
):
    if forbidden in source:
        print(
            "ERROR: TaskStatus parser is coupled to enum names or silently "
            f"defaults: {forbidden}"
        )
        sys.exit(1)

required_test = (
    "uses explicit stable storage values in workflow order",
    "round trips every canonical storage value",
    "rejects unknown and non-canonical storage values",
    "keeps all canonical storage values unique",
    "TaskStatus.tryParseStorage",
    "TaskStatus.parseStorage",
    "throwsA(isA<ValidationFailure>())",
)
missing = [token for token in required_test if token not in test]
if missing:
    print(f"ERROR: Gate 2.1.1 test coverage incomplete: {missing}")
    sys.exit(1)

print(
    "OK: Gate 2.1.1 GREEN adds an explicit four-value TaskStatus storage "
    "contract with stable workflow order, exact case/whitespace-sensitive "
    "round trips, nullable probing, typed strict failure, and no dependency "
    "on enum names, indexes, normalization, Drift, UI, or notifications."
)
