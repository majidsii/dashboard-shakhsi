# Visual Foundation 2.A Gate B.6B Variant-Aware Metrics Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build deterministic, source-backed, variant-aware Apple geometry metrics for iOS 27 and macOS 27 without selecting a false canonical metric or introducing guessed geometry.

**Architecture:** A Python generator reads the frozen Gate A Apple reference JSON, classifies only explicitly named Apple control families, extracts geometry-only values, normalizes only source-explicit variant metadata, and deterministically deduplicates exact geometry while retaining complete provenance. Flutter foundation types expose all variants through `AppleMetricTokens`; `AppleSourceTokenMapper.metrics(...)` maps generated records into immutable runtime tokens. Motion and resolved theme remain out of scope and unresolved.

**Tech Stack:** Flutter 3.44.6, Dart 3.12.2, Python 3, Flutter test, deterministic generated Dart, frozen Apple Sketch-derived JSON.

## Global Constraints

- Source of truth: `docs/superpowers/references/generated/apple_ui_kit_reference.json`.
- Approved design: `docs/superpowers/specs/2026-08-15-visual-foundation-2a-gate-b6b-variant-aware-metrics-design.md`.
- Android and iOS use the iOS 27 visual family; Windows, Linux, and macOS use the macOS 27 visual family.
- No single canonical metric may represent an inherently multi-variant Apple control family.
- Geometry values must come directly from the frozen Apple source reference.
- Blur, shadow, saturation, brightness, distortion, glass depth, opacity, fill, color, border, and stroke data are not metrics.
- Variant metadata may be normalized only from explicit source labels.
- Exact geometry duplicates may collapse only within the same platform family and component family, while preserving all contributing provenance and all explicit size distinctions.
- Light/Dark and state variants may share geometry only when accepted geometry values are exactly equal.
- No averaging, interpolation, guessed defaults, score-based canonical winner, or fallback geometry.
- B.6A Liquid Glass materials remain complete and unchanged.
- `AppleMotionTokens` remains unresolved because no explicit source-backed motion values are currently available.
- `AppleVisualThemeData` remains unresolved after B.6B.
- Do not modify the app root, OriginalTheme, dashboard UI, Task 2.8 behavior, or Task 2.9.
- Never run `flutter upgrade`.
- Do not modify, stage, or delete unrelated IPSW files in the repository root.
- Generated Dart is byte-for-byte owned by its generator; do not post-format generated output unless the generator emits that exact formatting.
- Gate B production changes remain uncommitted during this plan. Use explicit staging only at the eventual approved Gate B checkpoint; never use `git add .`.

---

## File Structure

### Create

- `tool/generate_apple_source_metrics.py`
  - Deterministically classifies source component records, extracts accepted geometry, normalizes explicit metadata, deduplicates exact geometry, preserves provenance, locks source hashes, generates Dart, and implements `--check`.

- `lib/app/apple_visual/generated/apple_source_metrics.g.dart`
  - Generated-only raw metric variant records for iOS 27 and macOS 27.

- `test/app/apple_visual/apple_metric_variant_mapping_test.dart`
  - RED/GREEN contract for variant multiplicity, exact geometry, provenance retention, deduplication, explicit metadata normalization, and false-positive exclusion.

### Modify

- `lib/app/apple_visual/foundation/apple_visual_metrics.dart`
  - Replace the unresolved-only metric shell with the variant-aware metric domain model while preserving `AppleMetricTokens.empty`.

- `lib/app/apple_visual/foundation/apple_source_token_mapper.dart`
  - Add `metrics({required AppleVisualFamily family})` mapping generated records into immutable runtime tokens.

### Read-only inputs

- `docs/superpowers/references/generated/apple_ui_kit_reference.json`
- `docs/superpowers/specs/2026-08-15-visual-foundation-2a-gate-b6b-variant-aware-metrics-design.md`
- existing B.1-B.6A generated files, tests, and foundation types.

---

### Task 1: Lock the Variant-Aware RED Contract

**Files:**
- Create: `test/app/apple_visual/apple_metric_variant_mapping_test.dart`
- Read: `docs/superpowers/references/generated/apple_ui_kit_reference.json`
- Read: `lib/app/apple_visual/foundation/apple_visual_metrics.dart`
- Read: `lib/app/apple_visual/foundation/apple_source_token_mapper.dart`

**Interfaces:**
- Consumes: `AppleVisualFamily.ios27`, `AppleVisualFamily.macos27`.
- Produces the required public contract:
  - `enum AppleMetricComponent { button, searchField, textField, segmentedControl, toggle }`
  - `class AppleMetricProvenance`
  - `class AppleMetricVariant`
  - `class AppleMetricTokens`
  - `AppleMetricTokens AppleSourceTokenMapper.metrics({required AppleVisualFamily family})`
  - `List<AppleMetricVariant> AppleMetricTokens.variantsFor(AppleMetricComponent component)`

- [ ] **Step 1: Write the failing Flutter test for multi-variant behavior**

Create a test with these public-API expectations:

```dart
final ios = AppleSourceTokenMapper.metrics(
  family: AppleVisualFamily.ios27,
);

final segmented = ios.variantsFor(
  AppleMetricComponent.segmentedControl,
);

expect(ios.isResolved, isTrue);
expect(segmented.length, greaterThan(1));
expect(
  segmented.map((variant) => variant.geometry['frame.height']).toSet(),
  containsAll(<double>{32.0, 48.0}),
);
```

This locks the already-audited iOS Segmented Control fact that Small and Large source variants are distinct and must not collapse into one canonical metric.

- [ ] **Step 2: Add exact provenance/geometry examples**

Lock representative audited source records:

```dart
final large = segmented.singleWhere(
  (variant) => variant.provenance.any(
    (source) => source.sourceId == 'FE073914-A7E7-4E4E-9F4D-374AE7330AA9',
  ),
);

expect(large.geometry['frame.width'], 370.0);
expect(large.geometry['frame.height'], 48.0);
expect(large.sizeLabel, 'Large');

final small = segmented.singleWhere(
  (variant) => variant.provenance.any(
    (source) => source.sourceId == '6DA75111-744B-47C1-8769-4254E1C3374A',
  ),
);

expect(small.geometry['frame.width'], 370.0);
expect(small.geometry['frame.height'], 32.0);
expect(small.sizeLabel, 'Small');
```

- [ ] **Step 3: Lock macOS explicit-size parsing**

Use the audited macOS Search Field source:

```dart
final macos = AppleSourceTokenMapper.metrics(
  family: AppleVisualFamily.macos27,
);

final search = macos.variantsFor(AppleMetricComponent.searchField);

final miniature = search.singleWhere(
  (variant) => variant.provenance.any(
    (source) => source.sourceId == '178C3D20-136B-4799-89C1-C1813A46A495',
  ),
);

expect(miniature.sizeLabel, 'Mn');
expect(miniature.geometry['frame.width'], 120.0);
expect(miniature.geometry['frame.height'], 16.0);
```

- [ ] **Step 4: Lock exact-geometry state deduplication with provenance retention**

Use the audited macOS Toggle state records that share `63 x 16` geometry:

```dart
final toggles = macos.variantsFor(AppleMetricComponent.toggle);

final compactToggle = toggles.singleWhere(
  (variant) =>
      variant.sizeLabel == 'Mn' &&
      variant.geometry['frame.width'] == 63.0 &&
      variant.geometry['frame.height'] == 16.0,
);

expect(
  compactToggle.provenance.map((source) => source.sourceId),
  containsAll(<String>[
    'BC9FF280-BDD8-4AA5-B2CD-ED6CBE8F797F',
    'E64ABC9F-439D-4299-A8D6-4EBCF7815DC7',
    '1EEBE37B-CD9A-4ED5-90EE-5CC65BBF2CF7',
  ]),
);
```

The variant may contain additional provenance with exactly identical geometry; the test must not require the provenance list to contain only these three IDs.

- [ ] **Step 5: Lock false-positive exclusion**

The previous audit incorrectly treated Keyboard Switch keys as Toggle candidates. Prevent regression:

```dart
expect(
  toggles.expand((variant) => variant.provenance).any(
    (source) => source.sourceId == '753D239D-FACC-4173-A42B-4073094687A3',
  ),
  isFalse,
);
```

Classification must require an explicit `Toggle` path segment; generic `Switch` text is insufficient.

- [ ] **Step 6: Lock effect exclusion**

```dart
for (final variant in <AppleMetricVariant>[
  ...segmented,
  ...search,
  ...toggles,
]) {
  for (final key in variant.geometry.keys) {
    expect(
      RegExp(
        r'blur|shadow|saturat|bright|distort|depth|opacity|glass|fill|color|border|stroke',
        caseSensitive: false,
      ).hasMatch(key),
      isFalse,
      reason: 'effect value leaked into metric geometry: $key',
    );
  }
}
```

- [ ] **Step 7: Run RED and verify the failure is the missing variant-aware API**

Run:

```bash
/home/shabin/develop/flutter/bin/flutter test \
  test/app/apple_visual/apple_metric_variant_mapping_test.dart
```

Expected: compilation/test failure because `AppleMetricComponent`, `AppleMetricVariant`, `variantsFor`, and/or `AppleSourceTokenMapper.metrics` do not exist yet.

Reject RED if it fails because of malformed Dart, bad imports, missing fixture files, or unrelated B.1-B.6A regression.

- [ ] **Step 8: Re-run B.1-B.6A regression tests**

Run:

```bash
/home/shabin/develop/flutter/bin/flutter test \
  test/app/apple_visual/apple_visual_platform_resolver_test.dart \
  test/app/apple_visual/apple_visual_tokens_contract_test.dart \
  test/app/apple_visual/apple_source_reference_mapping_test.dart \
  test/app/apple_visual/apple_semantic_color_mapping_test.dart \
  test/app/apple_visual/apple_typography_mapping_test.dart \
  test/app/apple_visual/apple_material_source_mapping_test.dart
```

Expected: all pass.

**Task boundary:** RED only. No production implementation and no production commit.

---

### Task 2: Implement the Deterministic Metric Generator

**Files:**
- Create: `tool/generate_apple_source_metrics.py`
- Create: `lib/app/apple_visual/generated/apple_source_metrics.g.dart`
- Test: `test/app/apple_visual/apple_metric_variant_mapping_test.dart`
- Read: `docs/superpowers/references/generated/apple_ui_kit_reference.json`

**Interfaces:**
- Consumes frozen source hashes:
  - iOS: `5941547509b49a3756667905f18492dfdf4e59a977de1deacccfcf7ff94ac295`
  - macOS: `8f83805217d979dc560d008fce66c1c77014f631cccff8978f31baf1d7ef3b28`
- Produces generated Dart:
  - `AppleGeneratedMetricProvenance`
  - `AppleGeneratedMetricVariant`
  - `AppleSourceMetricReference.iosVariants`
  - `AppleSourceMetricReference.macosVariants`

- [ ] **Step 1: Implement exact control-family classification**

In `tool/generate_apple_source_metrics.py`, split every source name on `/` and classify only explicit source path segments:

```python
def classify_component(source_name: str) -> str | None:
    segments = [segment.strip() for segment in source_name.split("/")]

    if "Segmented Controls" in segments or "Segmented Control" in segments:
        return "segmentedControl"

    if "Search Fields" in segments or "Search Field" in segments:
        return "searchField"

    if (
        "Text Fields" in segments
        or "Text Field" in segments
        or any(segment.startswith("Input Field") for segment in segments)
    ):
        return "textField"

    if "Toggle" in segments:
        return "toggle"

    if "Buttons" in segments:
        return "button"

    return None
```

Do not classify by a generic substring such as `button`, `field`, `search`, or `switch`.

- [ ] **Step 2: Implement geometry-only extraction**

Only accept keys structurally representing geometry:

```python
GEOMETRY_KEYS = {
    "width",
    "height",
    "cornerRadius",
    "fixedRadius",
    "spacing",
    "padding",
    "inset",
    "horizontalInset",
    "verticalInset",
    "topInset",
    "bottomInset",
    "leftInset",
    "rightInset",
}
```

Reject any path matching:

```python
EFFECT_RE = re.compile(
    r"(blur|shadow|saturat|bright|distort|depth|opacity|glass|"
    r"fill|color|border|stroke)",
    re.I,
)
```

Normalize the top-level component frame keys to stable geometry names:

```python
{
    "frame.width": 370.0,
    "frame.height": 48.0,
}
```

Do not emit `x` or `y` as semantic metric geometry in Gate B.6B.

- [ ] **Step 3: Parse only explicit variant metadata**

Implement exact-source label parsing:

```python
SIZE_CODE_RE = re.compile(r"^\d+\s+(Mn|Sm|Rg|Lg|XL)(?:\b|$)")
EXPLICIT_SIZE_LABELS = {"Small", "Large"}
APPEARANCES = {"Light", "Dark"}
STATE_LABELS = {
    "Idle",
    "Clicked",
    "Disabled",
    "Enabled",
    "On",
    "Off",
    "Active",
    "Inactive",
    "Empty",
    "Value",
    "Typing",
}
```

Rules:

```python
def parse_size_label(segments: list[str]) -> str | None:
    for segment in segments:
        match = SIZE_CODE_RE.match(segment)
        if match:
            return match.group(1)
        if segment in EXPLICIT_SIZE_LABELS:
            return segment
    return None
```

Appearance/state labels are metadata only. They must not alter geometry unless the actual geometry differs.

- [ ] **Step 4: Preserve exact provenance before deduplication**

Each source record entering deduplication must carry:

```python
{
    "sourceId": source_id,
    "sourceName": source_name,
    "appearance": appearance,
    "stateLabels": sorted(state_labels),
}
```

No source identity may be discarded.

- [ ] **Step 5: Deduplicate only exact geometry within component and size**

Use a canonical grouping key equivalent to:

```python
(
    component,
    size_label,
    tuple(sorted(geometry.items())),
)
```

This intentionally ignores state and Light/Dark only after geometry equality has already been proven by the grouping key.

Different explicit size labels must never collapse even if the numeric geometry happens to match.

Every group retains all provenance records sorted deterministically by `(sourceName.casefold(), sourceId)`.

- [ ] **Step 6: Emit deterministic generated Dart**

Generated records must have an API equivalent to:

```dart
class AppleGeneratedMetricProvenance {
  const AppleGeneratedMetricProvenance({
    required this.sourceId,
    required this.sourceName,
    required this.appearance,
    required this.stateLabels,
  });

  final String sourceId;
  final String sourceName;
  final String? appearance;
  final List<String> stateLabels;
}

class AppleGeneratedMetricVariant {
  const AppleGeneratedMetricVariant({
    required this.component,
    required this.sizeLabel,
    required this.geometry,
    required this.provenance,
  });

  final String component;
  final String? sizeLabel;
  final Map<String, double> geometry;
  final List<AppleGeneratedMetricProvenance> provenance;
}
```

`AppleSourceMetricReference` must expose separate iOS and macOS lists.

- [ ] **Step 7: Lock source hashes and implement `--check`**

The generator must fail if either frozen source hash differs.

Commands:

```bash
python3 tool/generate_apple_source_metrics.py \
  --input docs/superpowers/references/generated/apple_ui_kit_reference.json \
  --output lib/app/apple_visual/generated/apple_source_metrics.g.dart

python3 tool/generate_apple_source_metrics.py \
  --input docs/superpowers/references/generated/apple_ui_kit_reference.json \
  --output lib/app/apple_visual/generated/apple_source_metrics.g.dart \
  --check
```

Expected: generation succeeds and `--check` reports PASS.

- [ ] **Step 8: Verify byte-for-byte determinism**

Run generation twice and compare SHA-256:

```bash
before="$(sha256sum lib/app/apple_visual/generated/apple_source_metrics.g.dart | awk '{print $1}')"

python3 tool/generate_apple_source_metrics.py \
  --input docs/superpowers/references/generated/apple_ui_kit_reference.json \
  --output lib/app/apple_visual/generated/apple_source_metrics.g.dart

after="$(sha256sum lib/app/apple_visual/generated/apple_source_metrics.g.dart | awk '{print $1}')"

test "$before" = "$after"
```

Expected: equal hashes.

Do not run `dart format` on `apple_source_metrics.g.dart`.

**Task boundary:** generator and generated records exist, but runtime foundation mapping is not implemented yet. No production commit.

---

### Task 3: Implement the Variant-Aware Metric Domain Model and Mapper

**Files:**
- Modify: `lib/app/apple_visual/foundation/apple_visual_metrics.dart`
- Modify: `lib/app/apple_visual/foundation/apple_source_token_mapper.dart`
- Consume: `lib/app/apple_visual/generated/apple_source_metrics.g.dart`
- Test: `test/app/apple_visual/apple_metric_variant_mapping_test.dart`

**Interfaces:**
- Consumes:
  - `AppleSourceMetricReference.iosVariants`
  - `AppleSourceMetricReference.macosVariants`
- Produces:

```dart
enum AppleMetricComponent {
  button,
  searchField,
  textField,
  segmentedControl,
  toggle,
}
```

```dart
class AppleMetricProvenance {
  const AppleMetricProvenance({
    required this.sourceId,
    required this.sourceName,
    required this.appearance,
    required this.stateLabels,
  });

  final String sourceId;
  final String sourceName;
  final String? appearance;
  final List<String> stateLabels;
}
```

```dart
class AppleMetricVariant {
  const AppleMetricVariant({
    required this.component,
    required this.sizeLabel,
    required this.geometry,
    required this.provenance,
  });

  final AppleMetricComponent component;
  final String? sizeLabel;
  final Map<String, double> geometry;
  final List<AppleMetricProvenance> provenance;
}
```

```dart
class AppleMetricTokens {
  const AppleMetricTokens._({
    required this.isResolved,
    List<AppleMetricVariant>? variants,
  });

  static const empty = AppleMetricTokens._(isResolved: false);

  const AppleMetricTokens.resolved({
    required List<AppleMetricVariant> variants,
  });

  final bool isResolved;

  List<AppleMetricVariant> variantsFor(
    AppleMetricComponent component,
  );
}
```

- [ ] **Step 1: Implement immutable domain types**

`AppleMetricTokens.empty` must preserve the B.2 unresolved contract.

Accessing variants from unresolved tokens must fail explicitly:

```dart
List<AppleMetricVariant> get variants {
  final value = _variants;
  if (value == null) {
    throw StateError('Apple metric tokens are unresolved.');
  }
  return value;
}
```

`variantsFor(...)` filters the immutable resolved list without selecting a canonical record.

- [ ] **Step 2: Add generated metric imports to the mapper**

Add:

```dart
import '../generated/apple_source_metrics.g.dart';
import 'apple_visual_metrics.dart';
```

Do not remove existing color, typography, or material imports/mappers.

- [ ] **Step 3: Implement exact generated-component conversion**

Use an exhaustive conversion function:

```dart
static AppleMetricComponent _metricComponent(String value) {
  return switch (value) {
    'button' => AppleMetricComponent.button,
    'searchField' => AppleMetricComponent.searchField,
    'textField' => AppleMetricComponent.textField,
    'segmentedControl' => AppleMetricComponent.segmentedControl,
    'toggle' => AppleMetricComponent.toggle,
    _ => throw StateError('Unsupported generated Apple metric component: $value'),
  };
}
```

Never silently map an unknown generated component.

- [ ] **Step 4: Implement `AppleSourceTokenMapper.metrics(...)`**

Use the generated list selected strictly by visual family:

```dart
static AppleMetricTokens metrics({
  required AppleVisualFamily family,
}) {
  final sourceVariants = switch (family) {
    AppleVisualFamily.ios27 => AppleSourceMetricReference.iosVariants,
    AppleVisualFamily.macos27 => AppleSourceMetricReference.macosVariants,
  };

  return AppleMetricTokens.resolved(
    variants: List<AppleMetricVariant>.unmodifiable(
      sourceVariants.map(
        (source) => AppleMetricVariant(
          component: _metricComponent(source.component),
          sizeLabel: source.sizeLabel,
          geometry: Map<String, double>.unmodifiable(source.geometry),
          provenance: List<AppleMetricProvenance>.unmodifiable(
            source.provenance.map(
              (entry) => AppleMetricProvenance(
                sourceId: entry.sourceId,
                sourceName: entry.sourceName,
                appearance: entry.appearance,
                stateLabels: List<String>.unmodifiable(entry.stateLabels),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
```

There must be no numeric geometry literal in this mapper.

- [ ] **Step 5: Run the B.6B test and verify GREEN**

Run:

```bash
/home/shabin/develop/flutter/bin/flutter test \
  test/app/apple_visual/apple_metric_variant_mapping_test.dart
```

Expected: all B.6B tests pass.

If a representative source ID cannot be found, fix generator classification/normalization using the frozen source. Do not weaken the test by choosing a different arbitrary source record.

- [ ] **Step 6: Add a manual-geometry guard**

Run a script/check equivalent to:

```python
from pathlib import Path
import re

text = Path(
    "lib/app/apple_visual/foundation/apple_source_token_mapper.dart"
).read_text()

for pattern in (
    r"\bwidth\s*:\s*[0-9]",
    r"\bheight\s*:\s*[0-9]",
    r"\bcornerRadius\s*:\s*[0-9]",
    r"\bpadding\s*:\s*[0-9]",
    r"\bspacing\s*:\s*[0-9]",
):
    assert re.search(pattern, text) is None
```

Expected: PASS.

**Task boundary:** B.6B functional GREEN. Motion and theme remain unresolved. No production commit.

---

### Task 4: Verify Variant Semantics and Generator Integrity

**Files:**
- Test: `test/app/apple_visual/apple_metric_variant_mapping_test.dart`
- Verify: `tool/generate_apple_source_metrics.py`
- Verify existing source generators and tests.

**Interfaces:**
- Consumes the completed B.6B generated/runtime API.
- Produces a verified B.6B slice ready to remain in the uncommitted Gate B working set.

- [ ] **Step 1: Verify every supported component family has source-backed variants for each family where the frozen source exposes that family**

Add/retain assertions equivalent to:

```dart
for (final component in AppleMetricComponent.values) {
  expect(
    ios.variantsFor(component),
    isNotEmpty,
    reason: 'missing iOS source metrics for $component',
  );

  expect(
    macos.variantsFor(component),
    isNotEmpty,
    reason: 'missing macOS source metrics for $component',
  );
}
```

If the exact classifier demonstrates that a component family is genuinely absent from one frozen source family, stop as a source blocker rather than fabricating a record.

- [ ] **Step 2: Verify explicit size distinctions survive deduplication**

Assert:

```dart
final iOSSegmentedSizes = ios
    .variantsFor(AppleMetricComponent.segmentedControl)
    .map((variant) => variant.sizeLabel)
    .whereType<String>()
    .toSet();

expect(iOSSegmentedSizes, containsAll(<String>{'Small', 'Large'}));

final macSearchSizes = macos
    .variantsFor(AppleMetricComponent.searchField)
    .map((variant) => variant.sizeLabel)
    .whereType<String>()
    .toSet();

expect(macSearchSizes, containsAll(<String>{'Mn'}));
```

Do not require undocumented size labels.

- [ ] **Step 3: Verify deduplicated variants retain all source identities**

For every variant:

```dart
expect(variant.provenance, isNotEmpty);
expect(
  variant.provenance.map((entry) => entry.sourceId).toSet().length,
  variant.provenance.length,
);
```

No source ID may be duplicated or lost inside a deduplicated variant.

- [ ] **Step 4: Verify no forbidden effect geometry exists anywhere**

Run over every generated/runtime variant, not just representative examples, and reject geometry keys matching the forbidden effect pattern.

- [ ] **Step 5: Verify generator freshness and determinism**

Run:

```bash
python3 tool/generate_apple_source_metrics.py \
  --input docs/superpowers/references/generated/apple_ui_kit_reference.json \
  --output lib/app/apple_visual/generated/apple_source_metrics.g.dart \
  --check
```

Then regenerate once and run `--check` again.

Expected: PASS both times with identical output SHA.

- [ ] **Step 6: Verify existing generated references remain fresh**

Run:

```bash
python3 tool/generate_apple_source_materials.py \
  --input docs/superpowers/references/generated/apple_ui_kit_reference.json \
  --output lib/app/apple_visual/generated/apple_source_materials.g.dart \
  --check

python3 tool/generate_apple_source_typography.py \
  --input docs/superpowers/references/generated/apple_ui_kit_reference.json \
  --output lib/app/apple_visual/generated/apple_source_typography.g.dart \
  --check

python3 tool/generate_apple_source_colors.py \
  --input docs/superpowers/references/generated/apple_ui_kit_reference.json \
  --output lib/app/apple_visual/generated/apple_source_colors.g.dart \
  --check

python3 tool/generate_apple_source_reference.py \
  --input docs/superpowers/references/generated/apple_ui_kit_reference.json \
  --output lib/app/apple_visual/generated/apple_source_reference.g.dart \
  --check
```

Expected: all PASS.

- [ ] **Step 7: Verify Gate A extraction integrity**

Run:

```bash
python3 tool/verify_visual_foundation_2a_sources.py --self-test
python3 tool/verify_visual_foundation_2a_sources.py
```

Expected: both PASS.

- [ ] **Step 8: Run B.1-B.6B focused regression**

Run:

```bash
/home/shabin/develop/flutter/bin/flutter test \
  test/app/apple_visual/apple_visual_platform_resolver_test.dart \
  test/app/apple_visual/apple_visual_tokens_contract_test.dart \
  test/app/apple_visual/apple_source_reference_mapping_test.dart \
  test/app/apple_visual/apple_semantic_color_mapping_test.dart \
  test/app/apple_visual/apple_typography_mapping_test.dart \
  test/app/apple_visual/apple_material_source_mapping_test.dart \
  test/app/apple_visual/apple_metric_variant_mapping_test.dart
```

Expected: all pass.

- [ ] **Step 9: Run `git diff --check`**

```bash
git diff --check
```

Expected: no output and exit code 0.

**Task boundary:** B.6B verified GREEN. Do not mark Gate B complete.

---

### Task 5: Record the B.6B Boundary Without Advancing Gate B

**Files:**
- Modify only if the active Visual Foundation implementation plan/checkpoint requires progress tracking:
  - `docs/superpowers/plans/2026-08-09-visual-foundation-2a-apple-liquid-glass-implementation-plan.md`
- Do not change Task 2.9 status.
- Do not mark Gate B complete.

**Interfaces:**
- Consumes verified B.6B status.
- Produces an explicit next-state marker:
  - B.6A materials: GREEN
  - B.6B variant-aware metrics: GREEN
  - B.6C motion: BLOCKED — no explicit source-backed motion values
  - theme: unresolved

- [ ] **Step 1: Record the exact B.6B verification result**

The progress note must state:

```text
B.6B variant-aware source metrics: GREEN
canonical-single-metric model: rejected
geometry: source-backed only
effect values as metrics: rejected
motion: unresolved / blocked
theme: unresolved
Gate B complete: NO
```

- [ ] **Step 2: Do not create a production checkpoint commit**

Gate B production files from B.1 onward remain part of the existing uncommitted Gate B working set until the approved Gate B boundary is legitimately reached.

The existing B.6B design commit remains valid documentation history.

- [ ] **Step 3: Stop at the motion decision boundary**

Do not begin Gate C, app-host migration, OriginalTheme retirement, or Task 2.9.

The next architectural action is to resolve B.6C motion through one of only two acceptable paths:

1. discover explicit source-backed motion records; or
2. create and approve a separate motion deviation.

No motion implementation is permitted before that decision.

---

## Final B.6B Verification Checklist

Before reporting B.6B complete, all items below must be true:

```text
[ ] B.6B RED was observed failing for the missing variant-aware API.
[ ] Generator source hashes match the frozen iOS/macOS Sketch references.
[ ] Generator output is deterministic.
[ ] Generated metric Dart passes --check.
[ ] No generated Dart was post-formatted.
[ ] All metric geometry is source-backed.
[ ] No effect data is classified as geometry.
[ ] iOS Small/Large Segmented Control variants remain distinct.
[ ] macOS explicit size labels remain source-derived.
[ ] Exact state/light-dark geometry duplicates preserve all provenance.
[ ] Keyboard Switch false positive is excluded from Toggle metrics.
[ ] No canonical winner is selected for multi-variant controls.
[ ] B.1-B.6A regressions pass.
[ ] B.6B test passes.
[ ] Existing generated color/typography/material/reference checks pass.
[ ] Gate A source verification passes.
[ ] git diff --check passes.
[ ] AppleMotionTokens remains unresolved.
[ ] AppleVisualThemeData remains unresolved.
[ ] Gate B is NOT marked complete.
[ ] No Gate B production commit was created.
```

## Expected B.6B Completion Marker

```text
VISUAL_FOUNDATION_2A_GATE_B_6B_GREEN=PASS
ARCHITECTURE=VARIANT_AWARE_SOURCE_METRICS
CANONICAL_SINGLE_METRIC=REJECTED
METRIC_GEOMETRY=SOURCE_BACKED_ONLY
EXACT_DEDUPLICATION=PASS
PROVENANCE_RETENTION=PASS
FALSE_POSITIVE_KEYBOARD_SWITCH=REJECTED
GUESSED_METRICS=NONE
B_1_THROUGH_B_6A_REGRESSION=PASS
MOTION_STATUS=BLOCKED_NO_EXPLICIT_SOURCE
THEME_RESOLVED=NO
GATE_B_COMPLETE=NO
COMMIT=NO
NEXT=Gate B.6C motion source/deviation decision
```
