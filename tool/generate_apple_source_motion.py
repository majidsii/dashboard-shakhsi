#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any, NoReturn

EXPECTED_REFERENCE_CLASS = "officialSwiftUIRuntimeReference"
EXPECTED_VERIFIED_AT = "2026-08-15"
EXPECTED_ACCESSIBILITY_POLICIES = ["standard", "reduceMotion"]

EXPECTED_PRESETS = {
    "defaultSpring": {
        "apiReference": "Animation.default",
        "responseSeconds": 0.55,
        "dampingFraction": 1.0,
        "blendDurationSeconds": 0.0,
        "officialSwiftUIRuntimeReference": True,
        "exactInternalLiquidGlassMotion": False,
    },
    "interactiveSpring": {
        "apiReference": (
            "Animation.interactiveSpring("
            "response:dampingFraction:blendDuration:)"
        ),
        "responseSeconds": 0.15,
        "dampingFraction": 0.86,
        "blendDurationSeconds": 0.25,
        "officialSwiftUIRuntimeReference": True,
        "exactInternalLiquidGlassMotion": False,
    },
}

PRESET_ORDER = ["defaultSpring", "interactiveSpring"]


def fail(message: str) -> NoReturn:
    raise SystemExit(f"ERROR: {message}")


def require_dict(value: Any, label: str) -> dict[str, Any]:
    if not isinstance(value, dict):
        fail(f"{label} must be an object")
    return value


def require_list(value: Any, label: str) -> list[Any]:
    if not isinstance(value, list):
        fail(f"{label} must be an array")
    return value


def validate_manifest(data: dict[str, Any]) -> dict[str, dict[str, Any]]:
    if data.get("referenceClass") != EXPECTED_REFERENCE_CLASS:
        fail(
            "referenceClass mismatch: "
            f"expected={EXPECTED_REFERENCE_CLASS!r} "
            f"actual={data.get('referenceClass')!r}"
        )

    if data.get("verifiedAt") != EXPECTED_VERIFIED_AT:
        fail(
            "verifiedAt mismatch: "
            f"expected={EXPECTED_VERIFIED_AT!r} "
            f"actual={data.get('verifiedAt')!r}"
        )

    policies = require_list(
        data.get("accessibilityPolicies"),
        "accessibilityPolicies",
    )
    if policies != EXPECTED_ACCESSIBILITY_POLICIES:
        fail(
            "accessibilityPolicies mismatch: "
            f"expected={EXPECTED_ACCESSIBILITY_POLICIES!r} "
            f"actual={policies!r}"
        )

    raw_presets = require_list(data.get("presets"), "presets")

    by_id: dict[str, dict[str, Any]] = {}
    for index, raw in enumerate(raw_presets):
        preset = require_dict(raw, f"presets[{index}]")
        preset_id = preset.get("id")

        if not isinstance(preset_id, str) or not preset_id:
            fail(f"presets[{index}].id must be a non-empty string")

        if preset_id in by_id:
            fail(f"duplicate motion preset id: {preset_id}")

        by_id[preset_id] = preset

    if list(by_id.keys()) != PRESET_ORDER:
        fail(
            "preset order or membership mismatch: "
            f"expected={PRESET_ORDER!r} "
            f"actual={list(by_id.keys())!r}"
        )

    for preset_id in PRESET_ORDER:
        actual = by_id[preset_id]
        expected = EXPECTED_PRESETS[preset_id]

        allowed_keys = {"id", *expected.keys()}
        extra_keys = set(actual) - allowed_keys
        if extra_keys:
            fail(
                f"{preset_id} has unapproved keys: {sorted(extra_keys)!r}"
            )

        for key, expected_value in expected.items():
            actual_value = actual.get(key)

            if isinstance(expected_value, bool):
                if actual_value is not expected_value:
                    fail(
                        f"{preset_id}.{key} mismatch: "
                        f"expected={expected_value!r} "
                        f"actual={actual_value!r}"
                    )
                continue

            if isinstance(expected_value, float):
                if (
                    not isinstance(actual_value, (int, float))
                    or isinstance(actual_value, bool)
                    or float(actual_value) != expected_value
                ):
                    fail(
                        f"{preset_id}.{key} mismatch: "
                        f"expected={expected_value!r} "
                        f"actual={actual_value!r}"
                    )
                continue

            if actual_value != expected_value:
                fail(
                    f"{preset_id}.{key} mismatch: "
                    f"expected={expected_value!r} "
                    f"actual={actual_value!r}"
                )

    return by_id


def dart_string(value: str) -> str:
    return (
        "'"
        + value.replace("\\", "\\\\")
        .replace("'", "\\'")
        .replace("$", "\\$")
        .replace("\r", "\\r")
        .replace("\n", "\\n")
        .replace("\t", "\\t")
        + "'"
    )


def dart_bool(value: bool) -> str:
    return "true" if value else "false"


def dart_number(value: float) -> str:
    return repr(float(value))


def render(data: dict[str, Any]) -> str:
    by_id = validate_manifest(data)

    lines = [
        "// GENERATED FILE — DO NOT EDIT.",
        "// Source: docs/superpowers/references/apple_swiftui_motion_runtime_reference.json",
        "// Generator: tool/generate_apple_source_motion.py",
        "",
        "class AppleGeneratedMotionProvenance {",
        "  const AppleGeneratedMotionProvenance({",
        "    required this.apiReference,",
        "    required this.officialSwiftUIRuntimeReference,",
        "    required this.exactInternalLiquidGlassMotion,",
        "  });",
        "",
        "  final String apiReference;",
        "  final bool officialSwiftUIRuntimeReference;",
        "  final bool exactInternalLiquidGlassMotion;",
        "}",
        "",
        "class AppleGeneratedSpringMotion {",
        "  const AppleGeneratedSpringMotion({",
        "    required this.id,",
        "    required this.responseSeconds,",
        "    required this.dampingFraction,",
        "    required this.blendDurationSeconds,",
        "    required this.provenance,",
        "  });",
        "",
        "  final String id;",
        "  final double responseSeconds;",
        "  final double dampingFraction;",
        "  final double blendDurationSeconds;",
        "  final AppleGeneratedMotionProvenance provenance;",
        "}",
        "",
        "abstract final class AppleSourceMotionReference {",
    ]

    for preset_id in PRESET_ORDER:
        preset = by_id[preset_id]

        lines.extend(
            [
                f"  static const AppleGeneratedSpringMotion {preset_id} =",
                "      AppleGeneratedSpringMotion(",
                f"        id: {dart_string(preset_id)},",
                "        responseSeconds: "
                f"{dart_number(float(preset['responseSeconds']))},",
                "        dampingFraction: "
                f"{dart_number(float(preset['dampingFraction']))},",
                "        blendDurationSeconds: "
                f"{dart_number(float(preset['blendDurationSeconds']))},",
                "        provenance: AppleGeneratedMotionProvenance(",
                "          apiReference: "
                f"{dart_string(preset['apiReference'])},",
                "          officialSwiftUIRuntimeReference: "
                f"{dart_bool(preset['officialSwiftUIRuntimeReference'])},",
                "          exactInternalLiquidGlassMotion: "
                f"{dart_bool(preset['exactInternalLiquidGlassMotion'])},",
                "        ),",
                "      );",
                "",
            ]
        )

    lines.extend(
        [
            "  static const List<String> accessibilityPolicies = [",
        ]
    )

    for policy in data["accessibilityPolicies"]:
        lines.append(f"    {dart_string(policy)},")

    lines.extend(
        [
            "  ];",
            "}",
            "",
        ]
    )

    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--check", action="store_true")
    args = parser.parse_args()

    data = json.loads(args.input.read_text())
    if not isinstance(data, dict):
        fail("manifest root must be an object")

    rendered = render(data)

    if args.check:
        if not args.output.is_file():
            print(
                f"ERROR: generated motion reference missing: {args.output}",
                file=sys.stderr,
            )
            return 1

        if args.output.read_text() != rendered:
            print(
                "ERROR: generated motion reference is stale",
                file=sys.stderr,
            )
            return 1

        print("GENERATED_MOTION_CHECK=PASS")
        return 0

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(rendered)
    print(f"GENERATED_MOTION_DART={args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
