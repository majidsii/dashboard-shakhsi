# Visual Foundation 2.A — Gate B.6B Variant-Aware Apple Source Metrics Design

**Date:** 2026-08-15  
**Status:** APPROVED DESIGN — IMPLEMENTATION NOT STARTED  
**Scope:** Gate B.6B only  
**Parent:** Visual Foundation 2.A  
**Source of truth:** Extracted Apple iOS 27 / macOS 27 Sketch references committed by Gate A

## 1. Problem

The original Gate B.6B concept assumed one semantic geometry token per control family, for example:

- `button`
- `searchField`
- `textField`
- `segmentedControl`
- `toggle`

The source audit disproved that model.

Apple's source references contain multiple legitimate geometry variants for the same control family. These variants differ by platform family, size, context, and sometimes state. Selecting a single record as the canonical metric would be arbitrary and would violate the project's exact-source fidelity contract.

Examples already observed in the extracted source:

- iOS Segmented Controls include distinct `Small` and `Large` variants with different heights.
- macOS Search Fields expose multiple named size classes.
- macOS Toggle controls expose multiple state records that may share identical geometry.
- Button records exist across many contexts and must not be collapsed into one arbitrary width/height.

Therefore, Gate B.6B must be variant-aware.

## 2. Decision

Gate B.6B SHALL expose source-backed metric variants rather than one metric value per control family.

The final semantic boundary is:

- control family identifies the Apple control category;
- source variant identifies the exact Apple variation;
- size/state/context metadata is preserved when it can be derived from source naming or structure without guessing;
- geometry values remain exact values extracted from the source;
- provenance is retained for every metric variant.

There SHALL NOT be a global API equivalent to:

`AppleMetricRole.button -> one width/height`

because such an API cannot truthfully represent the Apple source.

## 3. Public Domain Model

The foundation API SHALL use these conceptual types:

### `AppleMetricComponent`

Initial Gate B.6B component families:

- `button`
- `searchField`
- `textField`
- `segmentedControl`
- `toggle`

This list is intentionally limited to the controls needed by later Visual Foundation control migration.

### `AppleMetricVariant`

Each variant SHALL carry:

- `component`
- `sourceId`
- `sourceName`
- exact source geometry values
- normalized source variant metadata when derivable without guessing

Variant metadata MAY include:

- Apple size label such as `Mn`, `Sm`, `Rg`, `Lg`, `XL`
- Apple explicit labels such as `Small` / `Large`
- state labels such as `Idle`, `Clicked`, `Disabled`, `On`, `Off`
- appearance labels such as `Light` / `Dark`

The exact field shape may be refined during the RED contract, but it must remain source-derived and deterministic.

## 4. Geometry Contract

Gate B.6B SHALL accept only actual geometry values.

Allowed categories include values structurally representing:

- width
- height
- corner radius
- fixed radius
- padding
- spacing
- insets

The following SHALL NOT be treated as metric geometry:

- blur radius
- shadow radius
- saturation
- brightness
- distortion
- glass depth
- opacity
- color/fill/stroke values

Those belong to material/effect concerns and are outside Gate B.6B.

## 5. Variant Normalization Rules

Normalization must never invent Apple semantics.

### 5.1 Exact source naming first

Size/state/context labels are derived only when the extracted source explicitly contains them.

Examples:

- `1 Mn`
- `2 Sm`
- `3 Rg`
- `4 Lg`
- `5 XL`
- `Small`
- `Large`
- `Idle`
- `Clicked`
- `Disabled`
- `On`
- `Off`
- `Light`
- `Dark`

### 5.2 No heuristic canonical winner

When multiple source records are valid members of the same component family, the generator must preserve them unless an exact deduplication rule applies.

No "first", "largest", "smallest", "most common", or score-based candidate may become the canonical Apple metric.

### 5.3 Exact geometry deduplication

Multiple source records MAY collapse into one geometry variant only when:

1. they belong to the same platform family and component family;
2. their complete accepted geometry payload is byte-for-byte/numerically identical;
3. collapsing them does not erase a source size distinction;
4. all contributing provenance/source identities remain recoverable.

This is intended for cases such as multiple control states whose geometry is exactly unchanged.

### 5.4 Light/Dark behavior

Light and Dark variants MAY share one geometry variant only when their accepted geometry payloads are exactly equal.

Appearance differences must not be assumed irrelevant; equality must be proven from extracted source values.

## 6. Generated Source Boundary

Gate B.6B SHALL add a deterministic generated metric reference derived from:

`docs/superpowers/references/generated/apple_ui_kit_reference.json`

The generated artifact must:

- lock the known Apple source hashes;
- preserve exact source IDs and names;
- preserve exact accepted geometry values;
- emit deterministic output;
- support `--check`;
- fail if the frozen source hashes differ;
- contain no hand-authored geometry constants.

Generated Dart must not be post-formatted unless the generator itself emits that exact formatting, because generated files are checked byte-for-byte.

## 7. Mapper Boundary

`AppleSourceTokenMapper` SHALL map generated metric records into the foundation domain API.

The mapper SHALL NOT:

- contain manual geometry constants;
- select one arbitrary variant;
- average values;
- infer undocumented sizes;
- silently fall back to guessed defaults.

If a requested semantic variant cannot be resolved exactly, the mapper must fail explicitly rather than approximate.

## 8. Relationship to Existing Gate B Work

This design does not change completed Gate B slices:

- B.1 platform family resolver
- B.2 unresolved token/theme boundary
- B.3 deterministic source reference
- B.4 semantic colors
- B.5 typography and approved Vazirmatn deviation
- B.6A source-backed Liquid Glass material records

B.6A remains complete.

`AppleVisualThemeData` SHALL remain unresolved after B.6B until the remaining Gate B requirements are legitimately resolved.

## 9. Motion Blocker

Motion remains a separate blocker.

The current extracted Apple source does not expose explicit source-backed motion duration/easing/spring values that can be safely mapped.

Gate B.6B SHALL NOT invent motion values and SHALL NOT use geometry data as a substitute.

Resolving motion requires either:

- an explicit source-backed record discovered later; or
- a separate documented and approved deviation.

Until then:

`AppleMotionTokens` remains unresolved.

## 10. TDD Boundary

Implementation SHALL follow RED -> GREEN.

The next RED test must prove:

1. each supported platform family exposes multiple source-backed metric variants where the source contains multiple variants;
2. exact source IDs/names are retained;
3. exact geometry values are retained;
4. size/state metadata is source-derived;
5. exact geometry duplicates may be grouped only under the rules in this design;
6. no single canonical metric is selected for an inherently multi-variant component;
7. effect values such as blur/shadow are excluded from metric geometry.

No production implementation may be added before this RED test fails for the expected missing variant-aware API.

## 11. Non-Goals

Gate B.6B does not:

- render controls;
- render Liquid Glass;
- modify app root/theme host;
- replace OriginalTheme;
- implement Gate C;
- implement Gate D controls;
- change Task 2.8 behavior;
- start Task 2.9;
- solve the motion blocker.

## 12. Success Criteria

Gate B.6B is GREEN only when:

- metric variants are generated deterministically from the frozen Apple source;
- all exposed geometry is exact source geometry;
- provenance is preserved;
- variant distinctions are retained;
- only exact geometry duplicates are collapsed;
- no effect values are misclassified as metrics;
- no geometry values are guessed;
- B.1 through B.6A regressions remain green;
- generated-reference checks pass;
- `git diff --check` passes.

## 13. Approved Architecture Decision

**Approved:** Variant-aware Apple source metrics.

**Rejected:** One canonical metric per control family.

**Reason:** The extracted Apple UI Kit contains multiple legitimate variants for the same control family. Exact fidelity requires preserving those variants instead of selecting an arbitrary representative.
