#!/usr/bin/env python3
from __future__ import annotations

import hashlib
import importlib.util
import json
from pathlib import Path
import tempfile
import zipfile

ROOT = Path(__file__).resolve().parents[1]
EXTRACTOR = ROOT / "tool" / "apple_ui_kit_reference_extractor.py"


def need(condition: bool, message: str) -> None:
    if not condition:
        raise SystemExit(message)


def load_extractor():
    spec = importlib.util.spec_from_file_location(
        "apple_ui_kit_reference_extractor",
        EXTRACTOR,
    )
    need(spec is not None and spec.loader is not None, "cannot load extractor")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def main() -> None:
    module = load_extractor()

    document = {
        "_class": "document",
        "foreignSymbols": [],
        "layerStyles": {"objects": []},
        "layerTextStyles": {"objects": []},
        "sharedSwatches": {"objects": []},
        "fontReferences": [],
    }
    meta = {
        "app": "com.bohemiancoding.sketch3",
        "appVersion": "2026",
        "build": "1",
        "version": 1,
        "compatibilityVersion": 1,
        "created": {},
        "variant": "NONAPPSTORE",
    }
    page = {
        "_class": "page",
        "do_objectID": "PAGE-1",
        "name": "Materials",
        "layers": [
            {
                "_class": "group",
                "do_objectID": "GROUP-OVER-DARK",
                "name": "Liquid Glass - Over Dark Backgrounds",
                "frame": {
                    "_class": "rect",
                    "x": 0,
                    "y": 0,
                    "width": 200,
                    "height": 100,
                    "constrainProportions": False,
                },
                "layers": [
                    {
                        "_class": "group",
                        "do_objectID": "GROUP-SMALL",
                        "name": "Dark - Small UI",
                        "frame": {
                            "_class": "rect",
                            "x": 10,
                            "y": 10,
                            "width": 80,
                            "height": 48,
                            "constrainProportions": False,
                        },
                        "layers": [
                            {
                                "_class": "group",
                                "do_objectID": "BG-SMALL-1",
                                "name": "BG - Small",
                                "sharedStyleID": "STYLE-DARK-SMALL",
                                "frame": {
                                    "_class": "rect",
                                    "x": 0,
                                    "y": 0,
                                    "width": 80,
                                    "height": 48,
                                    "constrainProportions": False,
                                },
                                "layers": [],
                                "style": {
                                    "_class": "style",
                                    "do_objectID": "STYLE-INLINE-1",
                                },
                            }
                        ],
                        "style": {
                            "_class": "style",
                            "do_objectID": "STYLE-INLINE-2",
                        },
                    }
                ],
                "style": {
                    "_class": "style",
                    "do_objectID": "STYLE-INLINE-3",
                },
            }
        ],
    }

    with tempfile.TemporaryDirectory() as tmp_dir:
        tmp = Path(tmp_dir)
        sketch = tmp / "fixture.sketch"

        with zipfile.ZipFile(sketch, "w", compression=zipfile.ZIP_DEFLATED) as zf:
            zf.writestr("document.json", json.dumps(document))
            zf.writestr("meta.json", json.dumps(meta))
            zf.writestr("pages/PAGE-1.json", json.dumps(page))

        digest = hashlib.sha256(sketch.read_bytes()).hexdigest()
        source = module.SourceFile(sketch, digest)
        extracted = module.extract_sketch_reference(source)

    component_records = extracted["componentLayers"]
    need(
        len(component_records) == 1,
        "componentLayers semantics changed; nested layers must remain excluded",
    )
    need(
        component_records[0]["sourceId"] == "GROUP-OVER-DARK",
        "componentLayers top-level record changed",
    )

    usage_records = extracted.get("liquidGlassUsageLayers")
    need(
        isinstance(usage_records, list),
        "RED_EXPECTED: liquidGlassUsageLayers missing from extracted reference",
    )

    by_id = {
        record["sourceId"]: record
        for record in usage_records
        if isinstance(record, dict) and record.get("sourceId") is not None
    }

    need(
        "GROUP-OVER-DARK" in by_id,
        "Liquid Glass usage root missing",
    )
    need(
        "GROUP-SMALL" in by_id,
        "nested Liquid Glass usage child missing",
    )
    need(
        "BG-SMALL-1" in by_id,
        "nested styled Liquid Glass usage child missing",
    )

    child = by_id["BG-SMALL-1"]

    need(
        child["pageName"] == "Materials",
        "nested child page provenance missing",
    )
    need(
        child["layerPath"]
        == "Liquid Glass - Over Dark Backgrounds/Dark - Small UI/BG - Small",
        "nested child hierarchy path missing or incorrect",
    )
    need(
        child["sharedStyleId"] == "STYLE-DARK-SMALL",
        "nested child sharedStyleID missing",
    )

    print("APPLE_UI_KIT_LIQUID_GLASS_USAGE_EXTRACTION=PASS")
    print("COMPONENT_LAYERS_BACKWARD_COMPATIBILITY=PASS")
    print("NESTED_COMPONENT_LAYER=PASS")
    print("NESTED_LAYER_PATH=PASS")
    print("NESTED_SHARED_STYLE_ID=PASS")


if __name__ == "__main__":
    main()
