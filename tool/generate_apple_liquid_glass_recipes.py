#!/usr/bin/env python3
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
from typing import Any

FAMILY_SPECS = (
    ("ios", "ios27"),
    ("macos", "macos27"),
)

APPEARANCE_SPECS = (
    ("Dark", "dark", "Liquid Glass - Over Dark Backgrounds"),
    ("Light", "light", "Liquid Glass - Over Light Backgrounds"),
)

DIRECT_ROLE_SUFFIXES = (
    ("smallControl", "Regular - Small"),
    ("tintedSmallControl", "Regular - Small - Tinted"),
    ("mediumSurface", "Regular - Medium"),
    ("largeSurface", "Regular - Large"),
)

REQUIRED_ROLES = (
    "smallControl",
    "tintedSmallControl",
    "mediumSurface",
    "largeSurface",
    "overGlassControl",
)


def fail(message: str) -> "NoReturn":
    raise SystemExit(f"ERROR: {message}")


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def flatten_source_values(
    value: Any,
    path: str = "style",
) -> dict[str, Any]:
    out: dict[str, Any] = {}

    if isinstance(value, dict):
        for key in sorted(value):
            child = f"{path}.{key}" if path else str(key)
            out.update(flatten_source_values(value[key], child))
        return out

    if isinstance(value, list):
        for index, item in enumerate(value):
            child = f"{path}[{index}]"
            out.update(flatten_source_values(item, child))
        return out

    if value is None:
        return out

    if isinstance(value, (str, int, float, bool)):
        out[path] = value
        return out

    fail(f"unsupported source value type at {path}: {type(value).__name__}")


def exact_style_candidates(
    styles: list[dict[str, Any]],
    appearance_title: str,
    suffix: str,
) -> list[dict[str, Any]]:
    expected_name = f"Liquid Glass/{appearance_title}/{suffix}"
    return [
        style
        for style in styles
        if isinstance(style, dict)
        and style.get("name") == expected_name
    ]


def usage_rows_for_style(
    usage: list[dict[str, Any]],
    source_id: str,
    root: str,
) -> list[dict[str, Any]]:
    prefix = root + "/"
    return [
        row
        for row in usage
        if isinstance(row, dict)
        and row.get("sharedStyleId") == source_id
        and isinstance(row.get("layerPath"), str)
        and (
            row["layerPath"] == root
            or row["layerPath"].startswith(prefix)
        )
    ]


def select_direct_style(
    *,
    styles: list[dict[str, Any]],
    usage: list[dict[str, Any]],
    appearance_title: str,
    root: str,
    suffix: str,
) -> tuple[dict[str, Any], list[str]]:
    candidates = exact_style_candidates(styles, appearance_title, suffix)

    if len(candidates) == 1:
        selected = candidates[0]
        rows = usage_rows_for_style(
            usage,
            str(selected.get("sourceId") or ""),
            root,
        )
        evidence = [
            f"exactStyleName={selected['name']}",
            "candidateResolution=singleExactSourceStyle",
        ]
        if rows:
            evidence.append(f"usageRoot={root}")
            evidence.append(f"usageCount={len(rows)}")
        else:
            evidence.append("usageEvidence=notRequiredForUniqueExactStyle")
        return selected, evidence

    if not candidates:
        fail(
            f"no exact source style for "
            f"{appearance_title}/{suffix}"
        )

    used_candidates: list[tuple[dict[str, Any], list[dict[str, Any]]]] = []
    for candidate in candidates:
        source_id = str(candidate.get("sourceId") or "")
        rows = usage_rows_for_style(usage, source_id, root)
        if rows:
            used_candidates.append((candidate, rows))

    if len(used_candidates) != 1:
        details = [
            {
                "sourceId": candidate.get("sourceId"),
                "name": candidate.get("name"),
                "usageCount": len(
                    usage_rows_for_style(
                        usage,
                        str(candidate.get("sourceId") or ""),
                        root,
                    )
                ),
            }
            for candidate in candidates
        ]
        fail(
            "ambiguous exact source styles cannot be resolved by "
            f"real usage provenance: {details}"
        )

    selected, rows = used_candidates[0]
    return selected, [
        f"exactStyleName={selected['name']}",
        f"candidateResolution=uniqueUsageBackedExactStyleOf{len(candidates)}",
        f"usageRoot={root}",
        f"usageCount={len(rows)}",
    ]



# GATE_C_APPLIED_USAGE_GEOMETRY_V1
def attach_small_control_usage_geometry(
    records: list[dict[str, Any]],
) -> None:
    # Preserve applied-layer geometry without rewriting shared-style values.
    #
    # Gate C source goldens are exports of concrete usage layers. Some Apple
    # shared Liquid Glass styles omit the effective corner radius while the
    # applied BG - Small usage layer contains it. Keep those usage values in
    # a separate namespace so provenance is not collapsed into style.*.
    import sys

    input_path = Path(
        "docs/superpowers/references/generated/apple_ui_kit_reference.json"
    )

    if "--input" in sys.argv:
        index = sys.argv.index("--input")
        if index + 1 >= len(sys.argv):
            fail("--input requires a path")
        input_path = Path(sys.argv[index + 1])

    source_reference = json.loads(input_path.read_text())

    family_keys = {
        "ios27": "ios",
        "macos27": "macos",
    }
    appearance_roots = {
        "dark": (
            "Dark",
            "Liquid Glass - Over Dark Backgrounds",
        ),
        "light": (
            "Light",
            "Liquid Glass - Over Light Backgrounds",
        ),
    }

    for record in records:
        if record.get("role") != "smallControl":
            continue

        family = str(record.get("family"))
        appearance = str(record.get("appearance"))

        family_key = family_keys.get(family)
        appearance_spec = appearance_roots.get(appearance)
        if family_key is None or appearance_spec is None:
            fail(
                "unsupported smallControl usage-geometry tuple "
                f"family={family} appearance={appearance}"
            )

        source_ids = record.get("sourceIds") or []
        if len(source_ids) != 1:
            fail(
                "smallControl usage geometry requires exactly one source style "
                f"family={family} appearance={appearance} sourceIds={source_ids}"
            )

        source_id = str(source_ids[0])
        appearance_title, root = appearance_spec

        family_reference = source_reference.get(family_key)
        if not isinstance(family_reference, dict):
            fail(f"missing source family {family_key}")

        usage = family_reference.get("liquidGlassUsageLayers") or []
        branch = f"{appearance_title} - Small UI"

        rows = [
            row
            for row in usage
            if isinstance(row, dict)
            and row.get("name") == "BG - Small"
            and row.get("sharedStyleId") == source_id
            and isinstance(row.get("layerPath"), str)
            and row["layerPath"].startswith(root + "/")
            and f"/{branch}/" in ("/" + row["layerPath"] + "/")
            and "Small UI (Tinted)" not in row["layerPath"]
        ]

        if not rows:
            fail(
                "missing source-backed BG - Small usage geometry "
                f"family={family} appearance={appearance} sourceId={source_id}"
            )

        signatures: dict[
            tuple[object, object, tuple[object, ...], object, object],
            list[dict[str, Any]],
        ] = {}

        for row in rows:
            frame = row.get("frame")
            corners = row.get("corners")

            if not isinstance(frame, dict) or not isinstance(corners, dict):
                fail(
                    "incomplete applied usage geometry "
                    f"family={family} appearance={appearance} "
                    f"layer={row.get('sourceId')}"
                )

            radii = corners.get("radii")
            if not isinstance(radii, list) or not radii:
                fail(
                    "missing applied usage corner radius "
                    f"family={family} appearance={appearance} "
                    f"layer={row.get('sourceId')}"
                )

            signature = (
                frame.get("width"),
                frame.get("height"),
                tuple(radii),
                corners.get("smoothing"),
                corners.get("style"),
            )
            signatures.setdefault(signature, []).append(row)

        if len(signatures) != 1:
            fail(
                "ambiguous applied smallControl geometry "
                f"family={family} appearance={appearance} "
                f"signatures={list(signatures)}"
            )

        signature, agreeing_rows = next(iter(signatures.items()))
        width, height, radii, smoothing, corner_style = signature

        source_values = record.get("sourceValues")
        evidence = record.get("roleMappingEvidence")

        if not isinstance(source_values, dict) or not isinstance(evidence, list):
            fail(
                "malformed generated recipe while attaching usage geometry "
                f"family={family} appearance={appearance}"
            )

        # Deliberately separate applied-layer values from shared-style values.
        source_values["usage.frame.width"] = width
        source_values["usage.frame.height"] = height
        source_values["usage.corners.radii[0]"] = radii[0]
        source_values["usage.corners.smoothing"] = smoothing
        source_values["usage.corners.style"] = corner_style

        evidence.append("usageGeometrySelector=name:BG - Small")
        evidence.append(
            f"usageGeometryAgreementCount={len(agreeing_rows)}"
        )
        evidence.extend(
            "usageGeometryLayerSourceId=" + str(row.get("sourceId"))
            for row in sorted(
                agreeing_rows,
                key=lambda item: str(item.get("sourceId") or ""),
            )
            if row.get("sourceId")
        )

def select_over_glass_style(
    *,
    styles_by_id: dict[str, dict[str, Any]],
    usage: list[dict[str, Any]],
    appearance_title: str,
    root: str,
) -> tuple[dict[str, Any], list[str]]:
    prefix = root + "/"
    rows = [
        row
        for row in usage
        if isinstance(row, dict)
        and row.get("name") == "BG - Small"
        and row.get("sharedStyleId")
        and isinstance(row.get("layerPath"), str)
        and row["layerPath"].startswith(prefix)
        and "Small UI (Tinted)" not in row["layerPath"]
    ]

    if not rows:
        fail(f"no BG - Small usage rows under {root}")

    style_ids = sorted({
        str(row["sharedStyleId"])
        for row in rows
    })

    if len(style_ids) != 1:
        fail(
            f"overGlassControl expected one source style under {root}; "
            f"got {style_ids}"
        )

    source_id = style_ids[0]
    style = styles_by_id.get(source_id)
    if style is None:
        fail(
            f"overGlassControl usage references missing style {source_id}"
        )

    expected_name = (
        f"Liquid Glass/{appearance_title}/Regular - Small"
    )
    if style.get("name") != expected_name:
        fail(
            f"overGlassControl usage style mismatch: "
            f"{style.get('name')!r} != {expected_name!r}"
        )

    source_layer_ids = sorted({
        str(row.get("sourceId"))
        for row in rows
        if row.get("sourceId")
    })
    layer_paths = sorted({
        str(row.get("layerPath"))
        for row in rows
        if row.get("layerPath")
    })

    evidence = [
        f"usageRoot={root}",
        "usageSelector=name:BG - Small",
        "usageSelector=tintedBranchExcluded",
        f"usageCount={len(rows)}",
        f"resolvedSharedStyleId={source_id}",
        f"resolvedExactStyleName={expected_name}",
    ]
    evidence.extend(
        f"usageLayerSourceId={source_id_}"
        for source_id_ in source_layer_ids
    )
    evidence.extend(
        f"usageLayerPath={path}"
        for path in layer_paths
    )

    return style, evidence


def recipe_record(
    *,
    family: str,
    appearance: str,
    role: str,
    style: dict[str, Any],
    evidence: list[str],
) -> dict[str, Any]:
    source_id = style.get("sourceId")
    source_name = style.get("name")
    source_style = style.get("style")

    if not isinstance(source_id, str) or not source_id:
        fail(f"{family}/{appearance}/{role}: missing sourceId")
    if not isinstance(source_name, str) or not source_name:
        fail(f"{family}/{appearance}/{role}: missing sourceName")
    if not isinstance(source_style, dict) or not source_style:
        fail(f"{family}/{appearance}/{role}: missing source style payload")

    values = flatten_source_values(source_style)
    if not values:
        fail(f"{family}/{appearance}/{role}: empty sourceValues")

    for forbidden in (
        "fallback.blurSigma",
        "fallback.opacity",
        "fallback.radius",
    ):
        if forbidden in values:
            fail(f"forbidden guessed fallback found: {forbidden}")

    return {
        "family": family,
        "appearance": appearance,
        "role": role,
        "sourceIds": [source_id],
        "sourceNames": [source_name],
        "sourceValues": values,
        "roleMappingEvidence": evidence,
    }


def build_records(reference: dict[str, Any]) -> list[dict[str, Any]]:
    records: list[dict[str, Any]] = []

    for family_key, family_name in FAMILY_SPECS:
        family = reference.get(family_key)
        if not isinstance(family, dict):
            fail(f"missing reference family {family_key}")

        styles = family.get("layerStyles")
        usage = family.get("liquidGlassUsageLayers")

        if not isinstance(styles, list) or not styles:
            fail(f"{family_key}: missing layerStyles")
        if not isinstance(usage, list) or not usage:
            fail(f"{family_key}: missing liquidGlassUsageLayers")

        styles_by_id = {
            str(style["sourceId"]): style
            for style in styles
            if isinstance(style, dict)
            and style.get("sourceId")
        }

        for appearance_title, appearance, root in APPEARANCE_SPECS:
            for role, suffix in DIRECT_ROLE_SUFFIXES:
                style, evidence = select_direct_style(
                    styles=styles,
                    usage=usage,
                    appearance_title=appearance_title,
                    root=root,
                    suffix=suffix,
                )
                records.append(
                    recipe_record(
                        family=family_name,
                        appearance=appearance,
                        role=role,
                        style=style,
                        evidence=evidence,
                    )
                )

            style, evidence = select_over_glass_style(
                styles_by_id=styles_by_id,
                usage=usage,
                appearance_title=appearance_title,
                root=root,
            )
            records.append(
                recipe_record(
                    family=family_name,
                    appearance=appearance,
                    role="overGlassControl",
                    style=style,
                    evidence=evidence,
                )
            )

    attach_small_control_usage_geometry(records)

    records.sort(
        key=lambda row: (
            row["family"],
            row["appearance"],
            REQUIRED_ROLES.index(row["role"]),
        )
    )

    expected_count = (
        len(FAMILY_SPECS)
        * len(APPEARANCE_SPECS)
        * len(REQUIRED_ROLES)
    )
    if len(records) != expected_count:
        fail(
            f"expected {expected_count} recipe records; "
            f"got {len(records)}"
        )

    for family_name in ("ios27", "macos27"):
        for appearance in ("dark", "light"):
            roles = {
                row["role"]
                for row in records
                if row["family"] == family_name
                and row["appearance"] == appearance
            }
            if roles != set(REQUIRED_ROLES):
                fail(
                    f"{family_name}/{appearance}: incomplete roles "
                    f"{sorted(roles)}"
                )

    return records


def dart_string(value: str) -> str:
    return (
        "'"
        + value
        .replace("\\", "\\\\")
        .replace("'", "\\'")
        .replace("\n", "\\n")
        .replace("\r", "\\r")
        .replace("\t", "\\t")
        + "'"
    )


def dart_value(value: Any, indent: str = "") -> str:
    if value is None:
        return "null"
    if value is True:
        return "true"
    if value is False:
        return "false"
    if isinstance(value, str):
        return dart_string(value)
    if isinstance(value, int):
        return str(value)
    if isinstance(value, float):
        if value != value:
            fail("NaN cannot be emitted to Dart")
        if value == float("inf") or value == float("-inf"):
            fail("infinite value cannot be emitted to Dart")
        text = repr(value)
        if "." not in text and "e" not in text.lower():
            text += ".0"
        return text
    fail(f"unsupported Dart scalar: {type(value).__name__}")


def emit_string_list(values: list[str], indent: str) -> list[str]:
    lines = ["["]
    for value in values:
        lines.append(f"{indent}  {dart_string(value)},")
    lines.append(f"{indent}]")
    return lines


def emit_source_values(
    values: dict[str, Any],
    indent: str,
) -> list[str]:
    lines = ["{"]
    for key in sorted(values):
        lines.append(
            f"{indent}  {dart_string(key)}: "
            f"{dart_value(values[key])},"
        )
    lines.append(f"{indent}}}")
    return lines


def emit_dart(records: list[dict[str, Any]]) -> str:
    lines = [
        "// GENERATED FILE — DO NOT EDIT.",
        "// Source: docs/superpowers/references/generated/"
        "apple_liquid_glass_recipe_reference.json",
        "// Generator: tool/generate_apple_liquid_glass_recipes.py",
        "",
        "final class AppleGeneratedLiquidGlassRecipe {",
        "  const AppleGeneratedLiquidGlassRecipe({",
        "    required this.family,",
        "    required this.appearance,",
        "    required this.role,",
        "    required this.sourceIds,",
        "    required this.sourceNames,",
        "    required this.sourceValues,",
        "    required this.roleMappingEvidence,",
        "  });",
        "",
        "  final String family;",
        "  final String appearance;",
        "  final String role;",
        "  final List<String> sourceIds;",
        "  final List<String> sourceNames;",
        "  final Map<String, Object?> sourceValues;",
        "  final List<String> roleMappingEvidence;",
        "}",
        "",
        "abstract final class AppleSourceLiquidGlassRecipeReference {",
        "  static const List<AppleGeneratedLiquidGlassRecipe> records = [",
    ]

    for record in records:
        lines.extend([
            "    AppleGeneratedLiquidGlassRecipe(",
            f"      family: {dart_string(record['family'])},",
            f"      appearance: {dart_string(record['appearance'])},",
            f"      role: {dart_string(record['role'])},",
            "      sourceIds: [",
        ])
        for value in record["sourceIds"]:
            lines.append(f"        {dart_string(value)},")
        lines.append("      ],")

        lines.append("      sourceNames: [")
        for value in record["sourceNames"]:
            lines.append(f"        {dart_string(value)},")
        lines.append("      ],")

        lines.append("      sourceValues: {")
        for key in sorted(record["sourceValues"]):
            lines.append(
                f"        {dart_string(key)}: "
                f"{dart_value(record['sourceValues'][key])},"
            )
        lines.append("      },")

        lines.append("      roleMappingEvidence: [")
        for value in record["roleMappingEvidence"]:
            lines.append(f"        {dart_string(value)},")
        lines.extend([
            "      ],",
            "    ),",
        ])

    lines.extend([
        "  ];",
        "}",
        "",
    ])
    return "\n".join(lines)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", required=True, type=Path)
    parser.add_argument("--json-output", required=True, type=Path)
    parser.add_argument("--dart-output", required=True, type=Path)
    args = parser.parse_args()

    reference = json.loads(args.input.read_text())
    records = build_records(reference)

    payload = {
        "schemaVersion": 1,
        "sourceReference": args.input.as_posix(),
        "sourceReferenceSha256": sha256(args.input),
        "recordCount": len(records),
        "records": records,
    }

    args.json_output.parent.mkdir(parents=True, exist_ok=True)
    args.dart_output.parent.mkdir(parents=True, exist_ok=True)

    args.json_output.write_text(
        json.dumps(
            payload,
            indent=2,
            sort_keys=True,
            ensure_ascii=False,
        )
        + "\n"
    )
    args.dart_output.write_text(emit_dart(records))

    print("APPLE_LIQUID_GLASS_RECIPE_GENERATION=PASS")
    print(f"RECORD_COUNT={len(records)}")
    print("FAMILIES=ios27,macos27")
    print("APPEARANCES=dark,light")
    print("ROLES=" + ",".join(REQUIRED_ROLES))
    print("GUESSED_DEFAULTS=NONE")


if __name__ == "__main__":
    main()
