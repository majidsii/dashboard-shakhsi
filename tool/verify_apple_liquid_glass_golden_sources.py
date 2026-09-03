#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import math
import struct
import sys
from pathlib import Path
from typing import Any

RECIPE_REFERENCE = Path(
    "docs/superpowers/references/generated/"
    "apple_liquid_glass_recipe_reference.json"
)

ACCEPTED_PROVENANCE = {
    "apple-source-export",
    "apple-source-derived-raster",
}

REJECTED_PROVENANCE = {
    "app-render",
    "flutter-render",
    "self-reference",
    "manual-redraw",
    "visual-approximation",
}

REQUIRED_MATRIX = (
    ("ios27/light/small-control.png", "ios27", "light", "smallControl"),
    ("ios27/dark/small-control.png", "ios27", "dark", "smallControl"),
    ("ios27/light/medium-surface.png", "ios27", "light", "mediumSurface"),
    ("ios27/dark/medium-surface.png", "ios27", "dark", "mediumSurface"),
    ("macos27/light/small-control.png", "macos27", "light", "smallControl"),
    ("macos27/dark/small-control.png", "macos27", "dark", "smallControl"),
    ("macos27/light/medium-surface.png", "macos27", "light", "mediumSurface"),
    ("macos27/dark/medium-surface.png", "macos27", "dark", "mediumSurface"),
    (
        "macos27/light/over-glass-control.png",
        "macos27",
        "light",
        "overGlassControl",
    ),
    (
        "macos27/dark/over-glass-control.png",
        "macos27",
        "dark",
        "overGlassControl",
    ),
)


def fail(errors: list[str]) -> "NoReturn":
    for error in errors:
        print(f"ERROR: {error}", file=sys.stderr)
    raise SystemExit(1)


def load_json(path: Path) -> Any:
    try:
        return json.loads(path.read_text())
    except FileNotFoundError:
        raise SystemExit(f"ERROR: missing JSON file: {path}") from None
    except json.JSONDecodeError as exc:
        raise SystemExit(f"ERROR: invalid JSON in {path}: {exc}") from None


def validate_manifest_shape(data: Any) -> list[dict[str, Any]]:
    errors: list[str] = []
    if not isinstance(data, dict):
        fail(["manifest root must be an object"])

    if data.get("schemaVersion") != 1:
        errors.append("manifest schemaVersion must equal 1")

    fixtures = data.get("fixtures")
    if not isinstance(fixtures, list):
        errors.append("manifest fixtures must be a list")
        fail(errors)

    expected_paths = [row[0] for row in REQUIRED_MATRIX]
    actual_paths = [
        item.get("path") if isinstance(item, dict) else None
        for item in fixtures
    ]

    if actual_paths != expected_paths:
        errors.append(
            "fixture paths/order must exactly match the locked minimum matrix"
        )

    if len(fixtures) != len(REQUIRED_MATRIX):
        errors.append(
            f"expected {len(REQUIRED_MATRIX)} fixtures; got {len(fixtures)}"
        )

    if errors:
        fail(errors)

    return fixtures


def recipe_index(recipe_data: Any) -> dict[tuple[str, str, str, str], dict[str, Any]]:
    if not isinstance(recipe_data, dict):
        fail(["recipe reference root must be an object"])

    records = recipe_data.get("records")
    if not isinstance(records, list):
        fail(["recipe reference records must be a list"])

    result: dict[tuple[str, str, str, str], dict[str, Any]] = {}
    for record in records:
        if not isinstance(record, dict):
            continue
        key = (
            str(record.get("family")),
            str(record.get("appearance")),
            str(record.get("role")),
            "idle",
        )
        if key in result:
            fail([f"duplicate recipe tuple: {key}"])
        result[key] = record
    return result


def validate_metadata(
    fixtures: list[dict[str, Any]],
    recipes: dict[tuple[str, str, str, str], dict[str, Any]],
) -> None:
    errors: list[str] = []

    for locked, fixture in zip(REQUIRED_MATRIX, fixtures, strict=True):
        path_value, family, brightness, role = locked
        prefix = f"{family}/{brightness}/{role}"

        if not isinstance(fixture, dict):
            errors.append(f"{prefix}: fixture record must be an object")
            continue

        expected_scalar = {
            "path": path_value,
            "family": family,
            "brightness": brightness,
            "role": role,
            "state": "idle",
            "background": "controlled-source-background",
        }
        for field, expected in expected_scalar.items():
            if fixture.get(field) != expected:
                errors.append(
                    f"{prefix}: {field} must be {expected!r}; "
                    f"got {fixture.get(field)!r}"
                )

        logical_size = fixture.get("logicalSize")
        if (
            not isinstance(logical_size, list)
            or len(logical_size) != 2
            or any(
                not isinstance(value, (int, float))
                or isinstance(value, bool)
                or value <= 0
                for value in logical_size
            )
        ):
            errors.append(
                f"{prefix}: logicalSize must contain two positive numbers"
            )

        dpr = fixture.get("devicePixelRatio")
        if (
            not isinstance(dpr, (int, float))
            or isinstance(dpr, bool)
            or not math.isfinite(float(dpr))
            or float(dpr) <= 0
        ):
            errors.append(
                f"{prefix}: devicePixelRatio must be a finite positive number"
            )

        provenance = fixture.get("provenanceKind")
        if provenance in REJECTED_PROVENANCE:
            errors.append(
                f"{prefix}: rejected provenanceKind={provenance}"
            )
        elif provenance not in ACCEPTED_PROVENANCE:
            errors.append(
                f"{prefix}: unsupported provenanceKind={provenance!r}; "
                f"accepted={sorted(ACCEPTED_PROVENANCE)}"
            )

        tuple_key = (family, brightness, role, "idle")
        recipe = recipes.get(tuple_key)
        if recipe is None:
            errors.append(f"{prefix}: recipe tuple is missing")
            continue

        expected_ids = recipe.get("sourceIds")
        actual_ids = fixture.get("sourceIds")
        if actual_ids != expected_ids:
            errors.append(
                f"{prefix}: sourceIds mismatch; "
                f"expected={expected_ids!r} actual={actual_ids!r}"
            )

        expected_names = recipe.get("sourceNames")
        actual_names = fixture.get("sourceNames")
        if actual_names != expected_names:
            errors.append(
                f"{prefix}: sourceNames mismatch; "
                f"expected={expected_names!r} actual={actual_names!r}"
            )

    if errors:
        fail(errors)


def png_dimensions(path: Path) -> tuple[int, int]:
    data = path.read_bytes()
    if len(data) < 24 or data[:8] != b"\x89PNG\r\n\x1a\n":
        raise ValueError("not a PNG")
    if data[12:16] != b"IHDR":
        raise ValueError("PNG IHDR chunk missing")
    width, height = struct.unpack(">II", data[16:24])
    return width, height


def validate_rasters(
    manifest_path: Path,
    fixtures: list[dict[str, Any]],
) -> None:
    errors: list[str] = []
    root = manifest_path.parent.resolve()

    for fixture in fixtures:
        relative = Path(str(fixture["path"]))
        if relative.is_absolute() or ".." in relative.parts:
            errors.append(f"unsafe fixture path: {relative}")
            continue

        fixture_path = (root / relative).resolve()
        try:
            fixture_path.relative_to(root)
        except ValueError:
            errors.append(f"fixture escapes golden root: {relative}")
            continue

        if not fixture_path.is_file():
            errors.append(f"MISSING_FIXTURE={relative.as_posix()}")
            continue

        try:
            width, height = png_dimensions(fixture_path)
        except ValueError as exc:
            errors.append(f"{relative}: invalid PNG: {exc}")
            continue

        logical_width, logical_height = fixture["logicalSize"]
        dpr = float(fixture["devicePixelRatio"])
        expected_width = int(round(float(logical_width) * dpr))
        expected_height = int(round(float(logical_height) * dpr))

        if (width, height) != (expected_width, expected_height):
            errors.append(
                f"{relative}: raster size {(width, height)} does not match "
                f"logicalSize×DPR {(expected_width, expected_height)}"
            )

    if errors:
        fail(errors)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--manifest", required=True, type=Path)
    parser.add_argument(
        "--recipe-reference",
        type=Path,
        default=RECIPE_REFERENCE,
    )
    args = parser.parse_args()

    manifest_data = load_json(args.manifest)
    fixtures = validate_manifest_shape(manifest_data)
    recipes = recipe_index(load_json(args.recipe_reference))

    validate_metadata(fixtures, recipes)
    validate_rasters(args.manifest, fixtures)

    print("APPLE_LIQUID_GLASS_GOLDEN_PROVENANCE=PASS")
    print("SELF_REFERENCE_GOLDENS=NONE")


if __name__ == "__main__":
    main()
