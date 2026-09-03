# Gate C Source-Golden Export Blocker

**Date:** 2026-08-17  
**Scope:** Visual Foundation 2.A — Gate C — Task 4  
**Status:** RESOLVED — TASK 4 GREEN  
**Next task allowed:** Yes — Task 5 may start after the Task 4 final diff check.

## Blocker summary

Gate C Task 4 requires source-derived reference PNG fixtures for the locked Apple Liquid Glass minimum golden matrix. The current Ubuntu development environment cannot produce or obtain those required source-derived rasters without violating the approved provenance policy.

The approved Gate C plan explicitly forbids using app-rendered, Flutter-rendered, manually redrawn, visually approximated, or self-reference images as reference goldens. Therefore Task 4 cannot be marked GREEN and Task 5 cannot begin.

## Locked source inputs

The source audit is bound to the previously locked Apple source hashes:

- iOS 27 UI Kit Sketch: `5941547509b49a3756667905f18492dfdf4e59a977de1deacccfcf7ff94ac295`
- macOS 27 UI Kit Sketch: `8f83805217d979dc560d008fce66c1c77014f631cccff8978f31baf1d7ef3b28`
- macOS 27 assets ZIP: `4bbbb036ce008f2213803ad05d7591ed4c0ac009f677a2e1d3d3b315ceb1ce31`

All three locked hashes were revalidated before writing this blocker.

## Required missing fixture matrix

All 10 required source-derived PNGs are currently missing:

1. `ios27/light/small-control.png`
2. `ios27/dark/small-control.png`
3. `ios27/light/medium-surface.png`
4. `ios27/dark/medium-surface.png`
5. `macos27/light/small-control.png`
6. `macos27/dark/small-control.png`
7. `macos27/light/medium-surface.png`
8. `macos27/dark/medium-surface.png`
9. `macos27/light/over-glass-control.png`
10. `macos27/dark/over-glass-control.png`

The Task 4 provenance verifier reports all ten as `MISSING_FIXTURE`.

## Feasibility evidence

The read-only source-raster feasibility audit established:

- `NATIVE_SKETCHTOOL_AVAILABLE=NO`
- iOS required Liquid Glass layers with explicit export formats: `0`
- iOS required Liquid Glass direct image references: `0`
- macOS required Liquid Glass layers with explicit export formats: `0`
- macOS required Liquid Glass direct image references: `0`
- locked macOS assets ZIP Liquid Glass filename matches: `0`
- `ARCHIVE_CONTAINS_DIRECT_REQUIRED_EXPORT_EVIDENCE=NO`

The Sketch archives do contain many raster assets and previews, but none are directly tied to the required Liquid Glass fixture tuples by the locked source provenance needed for Gate C Task 4. Generic previews or unrelated image assets are not acceptable substitutes.

## Provenance contract already locked

`test/goldens/apple/manifest.json` and `tool/verify_apple_liquid_glass_golden_sources.py` now lock the minimum fixture matrix and provenance rules.

The verifier already rejects:

- `app-render`
- `flutter-render`
- `self-reference`
- `manual-redraw`
- `visual-approximation`
- any fixture whose `sourceIds` do not exactly match the generated Liquid Glass recipe reference.

Task 4 RED is therefore valid and intentional: the only remaining failure is the absence of genuine source-derived PNG fixtures.

## Why Task 5 is blocked

Task 5 begins renderer RED/golden comparison work. Starting it without genuine source-derived reference goldens would make the implementation capable of approving its own visual output, which is explicitly forbidden by the Gate C design and implementation plan.

No renderer, shader, or feature migration may proceed as a workaround for this blocker.

## Accepted resolution paths

This blocker may be resolved only by one of these evidence-preserving paths:

1. Export the ten required fixtures from the locked Apple Sketch sources using a trusted Sketch-capable environment/tool that preserves the exact source appearance and tuple provenance.
2. Deterministically derive the ten raster fixtures from the locked Apple sources using a method whose output can be tied directly to the required source IDs/usage provenance and independently verified by the Task 4 provenance verifier.
3. Obtain equivalent official source exports that can be cryptographically/source-provenance linked to the same locked Apple UI Kit sources and required fixture tuples.

After genuine fixtures are available, rerun:

```bash
python3 tool/verify_apple_liquid_glass_golden_sources.py \
  --manifest test/goldens/apple/manifest.json
```

Required GREEN result:

```text
APPLE_LIQUID_GLASS_GOLDEN_PROVENANCE=PASS
SELF_REFERENCE_GOLDENS=NONE
```

Only then may Gate C proceed to Task 5.

## Explicit non-resolution paths

The following do **not** resolve this blocker:

- generating the reference PNGs from the app's own renderer;
- recreating the glass effect manually in Flutter, Python, SVG, Canvas, ImageMagick, or another drawing tool;
- cropping a generic Sketch preview without a direct fixture/source tuple provenance link;
- visually approximating the Apple source;
- weakening or bypassing the provenance verifier;
- accepting a renderer deviation to compensate for missing source references.

## Current Gate C state

- Task 1 — deterministic source-backed recipe generation: GREEN
- Task 2 — runtime recipe model and resolver: GREEN
- Task 3 — unresolved-state behavior and zero renderer-deviation baseline: GREEN
- Task 4 — source-derived golden provenance: RED / BLOCKED on genuine source raster acquisition
- Task 5 — renderer RED: NOT STARTED / BLOCKED
- Task 2.9: remains blocked until the entire Visual Foundation 2.A is complete.


---

## Resolution — 2026-08-28

The Gate C source-golden blocker is resolved.

Ten required Apple source-backed fixtures are now present.

Direct fixtures were exported from the official Apple Sketch documents through
Sketch Web using PNG at 1x.

The macOS over-glass fixtures were deterministically derived from the official
1080x1030 Sketch usage-root exports using exact source geometry. They are recorded
as `apple-source-derived-raster`; direct Sketch exports remain
`apple-source-export`.

No app-rendered, Flutter-rendered, manually redrawn, visually approximated, or
self-reference goldens were used.

Final verification:

    APPLE_LIQUID_GLASS_GOLDEN_PROVENANCE=PASS
    SELF_REFERENCE_GOLDENS=NONE

Therefore:

    TASK_4_SOURCE_GOLDEN_PROVENANCE=GREEN
    SOURCE_GOLDEN_BLOCKER=RESOLVED
    TASK_5=UNBLOCKED_AFTER_DIFF_CHECK
