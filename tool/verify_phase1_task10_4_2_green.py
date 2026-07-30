#!/usr/bin/env python3
from pathlib import Path
import sys

paths = {
    "decoder": Path(
        "lib/core/notifications/"
        "linux_systemd_registry_json_decoder.dart"
    ),
    "codec": Path(
        "lib/core/notifications/"
        "linux_systemd_schedule_registry_codec.dart"
    ),
    "decoder_test": Path(
        "test/core/notifications/"
        "linux_systemd_registry_json_decoder_test.dart"
    ),
    "codec_test": Path(
        "test/core/notifications/"
        "linux_systemd_schedule_registry_codec_test.dart"
    ),
}

for label, path in paths.items():
    if not path.exists():
        print(f"ERROR: missing Task 10.4.2 {label}: {path}")
        sys.exit(1)

decoder = paths["decoder"].read_text(encoding="utf-8")
codec = paths["codec"].read_text(encoding="utf-8")
tests = "\n".join(
    paths[label].read_text(encoding="utf-8")
    for label in ("decoder_test", "codec_test")
)

decoder_tokens = [
    "final class LinuxSystemdRegistryJsonDecoder",
    "Map<String, Object?> _parseObject()",
    "List<Object?> _parseArray()",
    "String _parseString()",
    "num _parseNumber()",
    "if (!keys.add(key))",
    "_isHighSurrogate",
    "_isLowSurrogate",
    "double.tryParse",
    "int.tryParse",
    "LinuxSystemdScheduleRegistryFailure.malformedJson",
]
codec_tokens = [
    "final class LinuxSystemdScheduleRegistryCodec",
    "static const int maximumFileBytes = 1 << 20",
    "static const int maximumEntries = 10000",
    "utf8.decode(bytes, allowMalformed: false)",
    "_requireExactKeys",
    "LinuxSystemdScheduleRegistry.currentSchemaVersion",
    "NotificationOwnerType.values",
    "parsed.toIso8601String() != value",
    "LinuxSystemdTimerName.parse",
    "utf8.encode('$encoded\\n')",
    "List<int>.unmodifiable",
    "_rethrowAsDecode",
]
test_tokens = [
    "rejects duplicate top-level object keys",
    "rejects duplicate nested object keys",
    "decodes basic Unicode escapes and surrogate pairs",
    "encodes canonical version-one JSON with exact field order",
    "accepts a valid registry padded to exactly one MiB",
    "rejects more than ten thousand entries before entry decoding",
    "allows exactly ten thousand entries past the count guard",
    "safe diagnostics never contain registry content",
]

for label, text, tokens in (
    ("duplicate-aware decoder", decoder, decoder_tokens),
    ("strict registry codec", codec, codec_tokens),
    ("Gate tests", tests, test_tokens),
):
    missing = [token for token in tokens if token not in text]
    if missing:
        print(f"ERROR: incomplete {label}: {missing}")
        sys.exit(1)

combined_production = f"{decoder}\n{codec}"

for forbidden in (
    "jsonDecode(",
    "dart:io",
    "Process.start",
    "Process.run",
    "systemctl",
    "title",
    "body",
    "payload",
):
    if forbidden in combined_production:
        print(
            "ERROR: Task 10.4.2 contains forbidden coupling or "
            f"sensitive field: {forbidden}"
        )
        sys.exit(1)

if "source" in codec and "cause: source" in codec:
    print("ERROR: registry source text is attached to diagnostics.")
    sys.exit(1)

print(
    "OK: Task 10.4.2 GREEN implements a duplicate-aware recursive JSON "
    "decoder and a canonical strict version-one registry codec with UTF-8, "
    "schema, type, owner, timestamp, unit-identity, one-MiB, ten-thousand-"
    "entry, deterministic-ordering, and safe-diagnostic enforcement."
)
