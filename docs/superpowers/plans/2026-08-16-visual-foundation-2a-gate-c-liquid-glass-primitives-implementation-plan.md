# Visual Foundation 2.A — Gate C Liquid Glass Primitives Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build source-locked Liquid Glass and low-level Apple rendering primitives only after proving deterministic semantic-role-to-source recipes and source-derived golden provenance.

**Architecture:** Gate C begins with a strict Gate C.0 source-evidence boundary. A deterministic generator converts locked Apple UI Kit reference data into provenance-preserving Liquid Glass recipes; a resolver maps `AppleVisualThemeData + AppleGlassRole + AppleControlState` to those recipes; widgets consume only resolved recipes. Standard Flutter composition is the first renderer, and a shader is forbidden unless a controlled source comparison records a measured mismatch that standard composition cannot remove.

**Tech Stack:** Flutter 3.44.6 stable, Dart 3.12.2, Flutter widget/golden tests, Python 3 source generators/verifiers, existing Gate B Apple visual tokens, locked Apple iOS 27/macOS 27 Sketch-derived reference JSON.

## Global Constraints

- Repository: `~/projects/personal/dashboard-shakhsi-v2-integration`
- Branch: `feat/v2-complete-dashboard`; do not implement on `main` or `master`.
- Flutter executable: `/home/shabin/develop/flutter/bin/flutter`.
- Never run `flutter upgrade`.
- Source design: `docs/superpowers/specs/2026-08-15-visual-foundation-2a-gate-c-liquid-glass-primitives-design.md`.
- Parent plan: `docs/superpowers/plans/2026-08-09-visual-foundation-2a-apple-liquid-glass-implementation-plan.md`.
- Gate B checkpoint: `docs/superpowers/checkpoints/2026-08-15-visual-foundation-2a-gate-b-complete-checkpoint.md`.
- Gate B completion commit: `d1e101d6635f4590d182d4f2560209674629788c`.
- Gate C design commit: `b33363eb614b957214734998e7a9b9025ac8ee95`.
- Apple iOS 27 and macOS 27 UI Kit sources remain the visual Source of Truth wherever measurable.
- Android and all compact/mobile targets resolve to `AppleVisualFamily.ios27`.
- Windows, Linux, and macOS desktop targets resolve to `AppleVisualFamily.macos27`.
- No Material, Fluent, Windows-native, Linux-native, or unrelated visible fallback is allowed.
- No source-independent visual constant may enter a migrated primitive.
- No app-generated image may approve itself as a reference golden.
- No shader may be added before a measured source-comparison mismatch proves it necessary.
- Production accepted renderer deviations remain zero unless a new explicit deviation decision is approved.
- Exact internal Liquid Glass motion is not claimed.
- No Apple font binaries may be added.
- `Task 2.9` remains blocked throughout Gate C.
- Existing unrelated IPSW files must never be staged, modified, or deleted.
- Generated Dart files are never run through `dart format`; the generator owns their exact bytes.
- Use RED → GREEN. If a source mapping is ambiguous, stop with a blocker instead of choosing the closest-looking value.
- Gate C follows the existing project convention of **no production commit during intermediate tasks**; one explicit-scope Gate C implementation/checkpoint commit is created only after final verification.

## File Structure

### Source-evidence and generated recipe boundary

- Create `tool/generate_apple_liquid_glass_recipes.py`
  - Reads the locked `apple_ui_kit_reference.json`.
  - Extracts exact Liquid Glass style records and usage provenance.
  - Resolves only evidence-backed role mappings.
  - Writes deterministic reference JSON and generated Dart.
  - Supports `--check`.
- Create `docs/superpowers/references/generated/apple_liquid_glass_recipe_reference.json`
  - Human-auditable evidence record.
  - Stores source IDs, names, family, appearance, role, state, source values, and usage evidence.
- Create `lib/app/apple_visual/generated/apple_source_liquid_glass_recipes.g.dart`
  - Generated typed constants only.
- Create `test/app/apple_visual/apple_liquid_glass_recipe_generation_test.dart`
  - Locks role coverage, provenance retention, no guessed defaults, and deterministic mapping.

### Runtime recipe boundary

- Create `lib/app/apple_visual/foundation/apple_visual_state.dart`
  - Defines the minimal semantic state contract required by Gate C.
- Create `lib/app/apple_visual/foundation/apple_liquid_glass_recipe.dart`
  - Defines immutable runtime recipe/provenance types.
- Create `lib/app/apple_visual/foundation/apple_liquid_glass_recipe_resolver.dart`
  - Maps resolved theme + semantic role + supported state to one exact recipe.
- Modify `lib/app/apple_visual/foundation/apple_source_token_mapper.dart`
  - Converts generated recipe records to runtime recipe records.
- Test `test/app/apple_visual/apple_liquid_glass_recipe_resolver_test.dart`.

### Source golden provenance boundary

- Create `tool/verify_apple_liquid_glass_golden_sources.py`
  - Verifies every reference PNG is source-derived and paired with provenance metadata.
- Create `test/goldens/apple/manifest.json`
  - Records fixture path, family, brightness, role, state, logical size, DPR, background, source IDs, and extraction provenance.
- Create the minimum required PNG fixtures under:
  - `test/goldens/apple/ios27/light/`
  - `test/goldens/apple/ios27/dark/`
  - `test/goldens/apple/macos27/light/`
  - `test/goldens/apple/macos27/dark/`
- The verifier must reject fixtures whose provenance says `app-render`, `flutter-render`, or any equivalent self-reference source.

### Rendering primitives

- Create `lib/app/apple_visual/widgets/apple_liquid_glass.dart`
  - Renders only a resolved recipe.
- Create `lib/app/apple_visual/widgets/apple_surface.dart`
  - Non-Material surface wrapper.
- Create `lib/app/apple_visual/widgets/apple_pressable.dart`
  - Interaction plumbing with no visible Material styling.
- Create `lib/app/apple_visual/widgets/apple_text.dart`
  - Gate B typography boundary.
- Create `lib/app/apple_visual/widgets/apple_separator.dart`
  - Source-backed separator only.
- Create `lib/app/apple_visual/foundation/apple_renderer_deviation.dart`
  - Test-visible deviation record; production accepted list is empty.
- Test `test/app/apple_visual/apple_liquid_glass_test.dart`.
- Test `test/app/apple_visual/apple_low_level_primitives_test.dart`.

### Conditional renderer asset

- Potentially create `shaders/apple_liquid_glass.frag`.
- This path is **forbidden** unless Task 8 records a measured mismatch and a new explicit renderer-deviation decision authorizes shader work.

---

### Task 1: Gate C.0 RED — lock source evidence requirements before any renderer

**Files:**
- Create: `test/app/apple_visual/apple_liquid_glass_recipe_generation_test.dart`
- Create: `tool/generate_apple_liquid_glass_recipes.py`
- Create: `docs/superpowers/references/generated/apple_liquid_glass_recipe_reference.json`
- Create: `lib/app/apple_visual/generated/apple_source_liquid_glass_recipes.g.dart`

**Interfaces:**
- Consumes:
  - `docs/superpowers/references/generated/apple_ui_kit_reference.json`
  - Gate B `AppleVisualFamily`
  - exact Liquid Glass source style names and IDs already present in the locked reference.
- Produces:
  - deterministic recipe records keyed by family, brightness, role, and state;
  - a human-auditable provenance JSON;
  - generated Dart constants.
- Does **not** produce a widget or runtime renderer.

- [ ] **Step 1: Write the failing source-contract test**

Create `test/app/apple_visual/apple_liquid_glass_recipe_generation_test.dart` with a first contract that imports the generated recipe file and requires all five semantic roles to be represented by provenance-backed source records.

The first test must have this shape:

```dart
import 'package:dashboard_shakhsi/app/apple_visual/generated/apple_source_liquid_glass_recipes.g.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('required Liquid Glass roles are source-backed for each family', () {
    for (final family in ['ios27', 'macos27']) {
      final records = AppleSourceLiquidGlassRecipeReference.records
          .where((record) => record.family == family)
          .toList();

      expect(records.map((record) => record.role).toSet(), containsAll(<String>{
        'smallControl',
        'tintedSmallControl',
        'mediumSurface',
        'largeSurface',
        'overGlassControl',
      }));

      for (final record in records) {
        expect(record.sourceIds, isNotEmpty);
        expect(record.sourceNames, isNotEmpty);
        expect(record.sourceValues, isNotEmpty);
        expect(record.roleMappingEvidence, isNotEmpty);
      }
    }
  });
}
```

Add a second test that rejects guessed fallback keys:

```dart
test('generated recipes contain no guessed defaults', () {
  for (final record in AppleSourceLiquidGlassRecipeReference.records) {
    expect(record.sourceValues.keys, isNot(contains('fallback.blurSigma')));
    expect(record.sourceValues.keys, isNot(contains('fallback.opacity')));
    expect(record.sourceValues.keys, isNot(contains('fallback.radius')));
  }
});
```

- [ ] **Step 2: Run the RED test**

Run:

```bash
/home/shabin/develop/flutter/bin/flutter test \
  test/app/apple_visual/apple_liquid_glass_recipe_generation_test.dart
```

Expected: FAIL because `apple_source_liquid_glass_recipes.g.dart` and its public reference types do not exist.

Record:

```text
GATE_C_0_SOURCE_RECIPE_RED=PASS
PRODUCTION_RENDERER_CHANGED=NO
COMMIT=NO
```

- [ ] **Step 3: Implement the deterministic generator skeleton and evidence extraction**

`tool/generate_apple_liquid_glass_recipes.py` must expose these pure functions:

```python
def load_reference(path: Path) -> dict: ...
def collect_liquid_glass_styles(reference: dict, family: str) -> list[dict]: ...
def collect_liquid_glass_usage(reference: dict, family: str) -> list[dict]: ...
def resolve_role_records(
    *,
    family: str,
    styles: list[dict],
    usage: list[dict],
) -> list[dict]: ...
def write_reference_json(records: list[dict], output: Path) -> None: ...
def render_dart(records: list[dict]) -> str: ...
```

Evidence rules in `resolve_role_records`:

```python
DIRECT_STYLE_SUFFIXES = {
    "smallControl": "Regular - Small",
    "tintedSmallControl": "Regular - Small - Tinted",
    "mediumSurface": "Regular - Medium",
    "largeSurface": "Regular - Large",
}
```

Direct roles are accepted only when the family + appearance + exact style suffix has exactly one source-backed candidate after deduplication by full source values and provenance.

`overGlassControl` must **not** use `DIRECT_STYLE_SUFFIXES`. It must be derived from usage records whose locked source layer path/name explicitly represents Liquid Glass over a light or dark background. The generator must preserve the exact referenced style/source IDs used by those source layers.

If any required mapping has zero candidates or more than one non-equivalent candidate, raise a deterministic error such as:

```text
UNRESOLVED_LIQUID_GLASS_ROLE family=macos27 brightness=dark role=overGlassControl candidates=2
```

Do not pick the first candidate.

- [ ] **Step 4: Generate the evidence files**

Run the generator with explicit paths:

```bash
python3 tool/generate_apple_liquid_glass_recipes.py \
  --input docs/superpowers/references/generated/apple_ui_kit_reference.json \
  --reference-output docs/superpowers/references/generated/apple_liquid_glass_recipe_reference.json \
  --dart-output lib/app/apple_visual/generated/apple_source_liquid_glass_recipes.g.dart
```

If the generator reports an ambiguous required mapping, **stop Gate C here** and record the exact candidate source IDs/names in a blocker document. Do not proceed to Task 2.

- [ ] **Step 5: Lock deterministic generation**

Run:

```bash
python3 tool/generate_apple_liquid_glass_recipes.py \
  --input docs/superpowers/references/generated/apple_ui_kit_reference.json \
  --reference-output docs/superpowers/references/generated/apple_liquid_glass_recipe_reference.json \
  --dart-output lib/app/apple_visual/generated/apple_source_liquid_glass_recipes.g.dart \
  --check
```

Expected:

```text
GENERATED_LIQUID_GLASS_RECIPE_CHECK=PASS
```

Then generate to two temporary locations and compare SHA-256 hashes. Expected identical bytes.

- [ ] **Step 6: Run the source-contract test GREEN**

Run:

```bash
/home/shabin/develop/flutter/bin/flutter test \
  test/app/apple_visual/apple_liquid_glass_recipe_generation_test.dart
```

Expected: PASS.

- [ ] **Step 7: Verify no renderer was introduced**

Run:

```bash
test ! -e lib/app/apple_visual/widgets/apple_liquid_glass.dart
test ! -e shaders/apple_liquid_glass.frag
git diff --check
```

Expected:

```text
GATE_C_0_SOURCE_RECIPE_GREEN=PASS
ROLE_MAPPING_BY_NAME_GUESS=NO
OVER_GLASS_PROVENANCE=LOCKED
SHADER_PRESENT=NO
COMMIT=NO
```

---

### Task 2: Gate C.0 GREEN — runtime recipe model and exact resolver

**Files:**
- Create: `lib/app/apple_visual/foundation/apple_visual_state.dart`
- Create: `lib/app/apple_visual/foundation/apple_liquid_glass_recipe.dart`
- Create: `lib/app/apple_visual/foundation/apple_liquid_glass_recipe_resolver.dart`
- Modify: `lib/app/apple_visual/foundation/apple_source_token_mapper.dart`
- Test: `test/app/apple_visual/apple_liquid_glass_recipe_resolver_test.dart`

**Interfaces:**
- Consumes:
  - `AppleVisualThemeData`
  - generated `AppleSourceLiquidGlassRecipeReference.records`
  - `AppleVisualFamily`
- Produces:

```dart
enum AppleGlassRole {
  smallControl,
  tintedSmallControl,
  mediumSurface,
  largeSurface,
  overGlassControl,
}

enum AppleControlState {
  idle,
}
```

`AppleControlState` intentionally begins with `idle` only. New visual states may be added only when a later RED test points to exact source evidence.

Runtime recipe types:

```dart
final class AppleLiquidGlassProvenance {
  const AppleLiquidGlassProvenance({
    required this.sourceIds,
    required this.sourceNames,
    required this.roleMappingEvidence,
  });

  final List<String> sourceIds;
  final List<String> sourceNames;
  final List<String> roleMappingEvidence;
}

final class AppleLiquidGlassRecipe {
  const AppleLiquidGlassRecipe({
    required this.family,
    required this.brightness,
    required this.role,
    required this.state,
    required this.sourceValues,
    required this.provenance,
  });

  final AppleVisualFamily family;
  final Brightness brightness;
  final AppleGlassRole role;
  final AppleControlState state;
  final Map<String, double> sourceValues;
  final AppleLiquidGlassProvenance provenance;
}
```

Resolver:

```dart
abstract final class AppleLiquidGlassRecipeResolver {
  static AppleLiquidGlassRecipe resolve({
    required AppleVisualThemeData theme,
    required AppleGlassRole role,
    AppleControlState state = AppleControlState.idle,
  });
}
```

- [ ] **Step 1: Write resolver RED tests**

Test every family × brightness × role combination:

```dart
for (final family in AppleVisualFamily.values) {
  for (final brightness in Brightness.values) {
    for (final role in AppleGlassRole.values) {
      final theme = resolvedThemeFor(
        family: family,
        brightness: brightness,
      );

      final recipe = AppleLiquidGlassRecipeResolver.resolve(
        theme: theme,
        role: role,
      );

      expect(recipe.family, family);
      expect(recipe.brightness, brightness);
      expect(recipe.role, role);
      expect(recipe.state, AppleControlState.idle);
      expect(recipe.sourceValues, isNotEmpty);
      expect(recipe.provenance.sourceIds, isNotEmpty);
    }
  }
}
```

Add unresolved theme rejection:

```dart
expect(
  () => AppleLiquidGlassRecipeResolver.resolve(
    theme: unresolvedTheme,
    role: AppleGlassRole.smallControl,
  ),
  throwsStateError,
);
```

- [ ] **Step 2: Run RED**

Run:

```bash
/home/shabin/develop/flutter/bin/flutter test \
  test/app/apple_visual/apple_liquid_glass_recipe_resolver_test.dart
```

Expected: FAIL because runtime recipe types/resolver do not exist.

- [ ] **Step 3: Implement minimal runtime types**

Create the exact types above. Keep recipe maps and provenance lists unmodifiable when converting generated data.

Do not add convenience visual defaults.

- [ ] **Step 4: Add generated-to-runtime mapping**

Add to `AppleSourceTokenMapper`:

```dart
static List<AppleLiquidGlassRecipe> liquidGlassRecipes() {
  return List<AppleLiquidGlassRecipe>.unmodifiable(
    AppleSourceLiquidGlassRecipeReference.records.map(
      _liquidGlassRecipe,
    ),
  );
}
```

The private converter must parse only generated enum/string values and throw `StateError` for unknown generated values.

- [ ] **Step 5: Implement exact resolver**

`resolve` must:

1. reject `!theme.isResolved`;
2. filter by exact family;
3. filter by exact brightness;
4. filter by exact role;
5. filter by exact state;
6. require exactly one result.

Use:

```dart
if (matches.length != 1) {
  throw StateError(
    'Expected exactly one Apple Liquid Glass recipe for '
    '${theme.family}/${theme.brightness}/$role/$state; '
    'found ${matches.length}.',
  );
}
```

No fallback to another appearance, role, state, or family.

- [ ] **Step 6: Run GREEN and aggregate Gate B regression**

Run:

```bash
/home/shabin/develop/flutter/bin/flutter test \
  test/app/apple_visual/apple_liquid_glass_recipe_generation_test.dart \
  test/app/apple_visual/apple_liquid_glass_recipe_resolver_test.dart \
  test/app/apple_visual/apple_visual_tokens_contract_test.dart \
  test/app/apple_visual/apple_material_source_mapping_test.dart
```

Expected: PASS.

- [ ] **Step 7: Verify source/generator freshness**

Run the new generator `--check`, all six Gate B generator `--check` commands, and:

```bash
git diff --check
```

Record:

```text
GATE_C_0_RUNTIME_RECIPE=PASS
RECIPE_FALLBACKS=NONE
APPLE_CONTROL_STATE=IDLE_ONLY
COMMIT=NO
```

---

### Task 3: Lock unresolved-state behavior and renderer-deviation zero baseline

**Files:**
- Create: `lib/app/apple_visual/foundation/apple_renderer_deviation.dart`
- Modify: `test/app/apple_visual/apple_liquid_glass_recipe_resolver_test.dart`
- Create: `test/app/apple_visual/apple_renderer_deviation_test.dart`

**Interfaces:**
- Produces:

```dart
final class AppleRendererDeviation {
  const AppleRendererDeviation({
    required this.family,
    required this.component,
    required this.platform,
    required this.reason,
    this.measuredDelta,
  });

  final AppleVisualFamily family;
  final String component;
  final String platform;
  final String reason;
  final double? measuredDelta;
}

abstract final class AppleRendererDeviationRegistry {
  static const List<AppleRendererDeviation> accepted = [];
}
```

- [ ] **Step 1: Write RED test for zero accepted deviations**

```dart
test('production renderer starts with zero accepted deviations', () {
  expect(AppleRendererDeviationRegistry.accepted, isEmpty);
});
```

- [ ] **Step 2: Write RED test for unsupported visual state**

Do **not** add another enum value just to test a fallback.

Instead verify the generated recipe set contains only states represented by `AppleControlState` and that the resolver never substitutes a missing tuple.

The test should group generated/runtime recipes by `(family, brightness, role, state)` and require uniqueness.

- [ ] **Step 3: Run RED**

Expected: FAIL because `AppleRendererDeviationRegistry` does not exist.

- [ ] **Step 4: Implement the zero-baseline registry**

Implement exactly the types above. No persistence, telemetry, or runtime mutation API.

- [ ] **Step 5: Run GREEN**

Run:

```bash
/home/shabin/develop/flutter/bin/flutter test \
  test/app/apple_visual/apple_renderer_deviation_test.dart \
  test/app/apple_visual/apple_liquid_glass_recipe_resolver_test.dart
```

Expected: PASS.

Record:

```text
RENDERER_DEVIATION_BASELINE=ZERO
UNRESOLVED_RECIPE_FALLBACK=NONE
COMMIT=NO
```

---

### Task 4: Source-derived golden provenance gate

**Files:**
- Create: `tool/verify_apple_liquid_glass_golden_sources.py`
- Create: `test/goldens/apple/manifest.json`
- Create: minimum required PNG fixtures under `test/goldens/apple/...`
- Modify: `test/app/apple_visual/apple_liquid_glass_test.dart` only after fixture provenance is valid.

**Interfaces:**
- Consumes:
  - locked Apple source assets/exports;
  - recipe-reference source IDs;
  - fixed fixture metadata.
- Produces:
  - provenance-verified reference PNGs;
  - deterministic manifest.

Manifest record shape:

```json
{
  "path": "ios27/light/small-control.png",
  "family": "ios27",
  "brightness": "light",
  "role": "smallControl",
  "state": "idle",
  "logicalSize": [160, 64],
  "devicePixelRatio": 1.0,
  "background": "controlled-source-background",
  "sourceIds": ["..."],
  "sourceNames": ["..."],
  "provenanceKind": "apple-source-export"
}
```

The literal source IDs are taken from the generated recipe reference. They are never manually guessed in this plan.

- [ ] **Step 1: Implement manifest verifier RED-first**

First create a manifest containing the required paths but no PNGs, then run:

```bash
python3 tool/verify_apple_liquid_glass_golden_sources.py \
  --manifest test/goldens/apple/manifest.json
```

Expected: FAIL with missing fixture errors.

The verifier must reject:

```text
provenanceKind=app-render
provenanceKind=flutter-render
provenanceKind=self-reference
```

and must reject a fixture whose `sourceIds` do not exactly match the recipe reference for its tuple.

- [ ] **Step 2: Establish the minimum fixture matrix**

Required:

```text
ios27/light/small-control.png
ios27/dark/small-control.png
ios27/light/medium-surface.png
ios27/dark/medium-surface.png
macos27/light/small-control.png
macos27/dark/small-control.png
macos27/light/medium-surface.png
macos27/dark/medium-surface.png
macos27/light/over-glass-control.png
macos27/dark/over-glass-control.png
```

Use logical size `160×64` and DPR `1.0` for control fixtures unless the exact source export requires a different source-locked size. If source evidence requires a different size, record that exact size in the manifest and update the test harness to match; do not rescale the Apple reference merely to satisfy this example.

- [ ] **Step 3: Export or derive fixtures only from locked Apple source**

Acceptable provenance:

```text
apple-source-export
apple-source-derived-raster
```

Unacceptable provenance:

```text
app-render
flutter-render
manual-redraw
visual-approximation
```

If the Ubuntu environment cannot produce or access a genuine source-derived raster for a required fixture, **stop here** and create:

```text
docs/superpowers/references/YYYY-MM-DD-gate-c-source-golden-export-blocker.md
```

The blocker must list the missing fixture tuple and why no source-derived raster is currently obtainable. Do not proceed to Task 5 with self-generated goldens.

- [ ] **Step 4: Verify golden provenance GREEN**

Run:

```bash
python3 tool/verify_apple_liquid_glass_golden_sources.py \
  --manifest test/goldens/apple/manifest.json
```

Expected:

```text
APPLE_LIQUID_GLASS_GOLDEN_PROVENANCE=PASS
SELF_REFERENCE_GOLDENS=NONE
```

- [ ] **Step 5: Diff check**

Run:

```bash
git diff --check
```

Record:

```text
GATE_C_SOURCE_GOLDENS=PASS
COMMIT=NO
```

---

### Task 5: Renderer RED — prove `AppleLiquidGlass` consumes only resolved source recipes

**Files:**
- Create: `lib/app/apple_visual/widgets/apple_liquid_glass.dart`
- Create/Modify: `test/app/apple_visual/apple_liquid_glass_test.dart`

**Interfaces:**
- Public API:

```dart
final class AppleLiquidGlass extends StatelessWidget {
  const AppleLiquidGlass({
    required this.theme,
    required this.role,
    required this.child,
    this.state = AppleControlState.idle,
    super.key,
  });

  final AppleVisualThemeData theme;
  final AppleGlassRole role;
  final AppleControlState state;
  final Widget child;
}
```

Passing `theme` explicitly is intentional in Gate C so widget tests and later non-Material hosts do not depend on `Theme.of(context)`.

- [ ] **Step 1: Write RED source-consumption tests**

Add a test-only render diagnostics boundary inside the widget file:

```dart
@visibleForTesting
final class AppleLiquidGlassRenderDiagnostics {
  const AppleLiquidGlassRenderDiagnostics({
    required this.recipe,
  });

  final AppleLiquidGlassRecipe recipe;
}
```

The first widget test must prove the widget resolves the exact tuple and does not accept raw blur/radius/opacity parameters.

Also add a compile-level contract check by constructing:

```dart
AppleLiquidGlass(
  theme: theme,
  role: AppleGlassRole.smallControl,
  child: const SizedBox.shrink(),
)
```

No `blurSigma`, `opacity`, `radius`, `borderColor`, or other visual override appears in the constructor.

- [ ] **Step 2: Run RED**

Run:

```bash
/home/shabin/develop/flutter/bin/flutter test \
  test/app/apple_visual/apple_liquid_glass_test.dart
```

Expected: FAIL because the widget does not exist.

- [ ] **Step 3: Implement minimum recipe-only widget skeleton**

Implement:

1. call `AppleLiquidGlassRecipeResolver.resolve(...)`;
2. pass the exact recipe to a private renderer;
3. do not add a shader;
4. do not add visual constants unrelated to recipe/source-backed semantic color tokens.

At this step the private renderer may remain a minimal composition sufficient for source-value contract tests; pixel approval comes in Task 6.

- [ ] **Step 4: Run source-consumption GREEN**

Run the focused test. Expected: PASS for API and source-consumption tests, while golden tests remain RED until the exact composition is implemented.

Record:

```text
APPLE_LIQUID_GLASS_SOURCE_CONSUMPTION=PASS
RAW_VISUAL_OVERRIDE_API=NONE
SHADER_PRESENT=NO
COMMIT=NO
```

---

### Task 6: Renderer GREEN — standard Flutter composition and source goldens

**Files:**
- Modify: `lib/app/apple_visual/widgets/apple_liquid_glass.dart`
- Modify: `test/app/apple_visual/apple_liquid_glass_test.dart`
- Use: `test/goldens/apple/...`

**Interfaces:**
- Consumes only `AppleLiquidGlassRecipe`.
- Produces a clipped, composited Flutter renderer.
- Does not expose source-value override parameters.

- [ ] **Step 1: Add controlled golden harness**

The test harness must set:

```dart
tester.view.devicePixelRatio = 1.0;
tester.view.physicalSize = const Size(160, 64);
```

and restore the view after each test.

Each golden test must construct the exact family/brightness theme and role matching its manifest record.

- [ ] **Step 2: Run golden RED**

Run only one fixture first:

```bash
/home/shabin/develop/flutter/bin/flutter test \
  test/app/apple_visual/apple_liquid_glass_test.dart \
  --plain-name 'ios27 light smallControl matches locked Apple source'
```

Expected: FAIL with image mismatch, not missing provenance or missing recipe.

- [ ] **Step 3: Implement standard Flutter composition from recipe fields**

Use only fields present in the recipe. The renderer may use these Flutter primitives when the corresponding source recipe has data:

```dart
ClipRRect
BackdropFilter
DecoratedBox
Stack
IgnorePointer
```

Map source custom-glass blur radius to the Flutter blur operation only through a named conversion function:

```dart
double sourceBlurRadiusToSigma(double sourceRadius)
```

This conversion must not contain an arbitrary magic multiplier. Before implementing it, add a test documenting the exact conversion semantics used by Flutter/Skia or, if exact equivalence cannot be justified from available renderer semantics, mark this conversion as the first measured renderer-compositor blocker and stop before guessing.

Likewise:

- fill/tint requires source fill/tint data;
- gradient requires source gradient data;
- border/rim requires source border data;
- shadow requires source shadow data;
- highlight requires source highlight data.

When a category is absent, render no layer for that category.

- [ ] **Step 4: Iterate one source-backed layer at a time**

After each layer, rerun the one golden.

Do not compensate for mismatch with unproven constants.

- [ ] **Step 5: Run the full minimum golden matrix**

Run:

```bash
/home/shabin/develop/flutter/bin/flutter test \
  test/app/apple_visual/apple_liquid_glass_test.dart
```

Expected: all source-contract and minimum golden tests PASS.

If they do not pass and the remaining delta cannot be removed with source-backed standard composition, stop and proceed to Task 8's measured-deviation decision before adding any shader.

- [ ] **Step 6: Analyze and diff-check**

Run:

```bash
/home/shabin/develop/flutter/bin/flutter analyze
git diff --check
```

Record:

```text
GATE_C_STANDARD_RENDERER=PASS
SOURCE_GOLDEN_MATRIX=PASS
SHADER_PRESENT=NO
COMMIT=NO
```

---

### Task 7: Low-level companion primitives without Material-visible fallback

**Files:**
- Create: `lib/app/apple_visual/widgets/apple_surface.dart`
- Create: `lib/app/apple_visual/widgets/apple_pressable.dart`
- Create: `lib/app/apple_visual/widgets/apple_text.dart`
- Create: `lib/app/apple_visual/widgets/apple_separator.dart`
- Create: `test/app/apple_visual/apple_low_level_primitives_test.dart`

**Interfaces:**

`AppleSurface`:

```dart
final class AppleSurface extends StatelessWidget {
  const AppleSurface({
    required this.child,
    this.glassRole,
    this.theme,
    super.key,
  });

  final Widget child;
  final AppleGlassRole? glassRole;
  final AppleVisualThemeData? theme;
}
```

Contract: if `glassRole != null`, `theme` is required and the surface delegates to `AppleLiquidGlass`. Otherwise it is a transparent structural surface and must not create ad-hoc glass math.

`ApplePressable`:

```dart
final class ApplePressable extends StatelessWidget {
  const ApplePressable({
    required this.child,
    required this.onPressed,
    this.enabled = true,
    super.key,
  });

  final Widget child;
  final VoidCallback? onPressed;
  final bool enabled;
}
```

Contract: use `GestureDetector`/`Semantics` or equivalent non-visible interaction plumbing; no `InkWell`, `InkResponse`, `ElevatedButton`, `TextButton`, `IconButton`, or Material splash.

`AppleText`:

```dart
final class AppleText extends StatelessWidget {
  const AppleText(
    this.data, {
    required this.tokens,
    required this.role,
    this.textDirection,
    super.key,
  });

  final String data;
  final AppleTypographyTokens tokens;
  final AppleTypographyRole role;
  final TextDirection? textDirection;
}
```

Contract: style derives only from Gate B typography token for the role and the approved runtime family rule. No `Theme.of(context).textTheme`.

`AppleSeparator`:

```dart
final class AppleSeparator extends StatelessWidget {
  const AppleSeparator({
    required this.color,
    required this.thickness,
    super.key,
  });

  final Color color;
  final double thickness;
}
```

This primitive may only be called with source-backed semantic values by later controls. Gate C itself must not invent a default color or thickness.

- [ ] **Step 1: Write RED tests for forbidden Material-visible dependencies**

Tests must inspect widget trees and source semantics so that:

- `ApplePressable` contains no Material button or ink widget;
- `AppleText` requires explicit Apple typography tokens;
- `AppleSeparator` has no default thickness/color;
- `AppleSurface(glassRole: ...)` delegates to `AppleLiquidGlass`.

- [ ] **Step 2: Run RED**

Run:

```bash
/home/shabin/develop/flutter/bin/flutter test \
  test/app/apple_visual/apple_low_level_primitives_test.dart
```

Expected: FAIL because the primitives do not exist.

- [ ] **Step 3: Implement minimal primitives**

Implement only the contracts above. Do not add feature-specific variants.

- [ ] **Step 4: Run GREEN**

Run:

```bash
/home/shabin/develop/flutter/bin/flutter test \
  test/app/apple_visual/apple_low_level_primitives_test.dart \
  test/app/apple_visual/apple_liquid_glass_test.dart
```

Expected: PASS.

- [ ] **Step 5: Semantic fallback grep**

Run:

```bash
rg -n \
  'InkWell|InkResponse|ElevatedButton|TextButton|IconButton|Theme\.of\(context\)\.textTheme' \
  lib/app/apple_visual/widgets
```

Expected: no matches.

Record:

```text
GATE_C_LOW_LEVEL_PRIMITIVES=PASS
VISIBLE_MATERIAL_FALLBACK=NONE
COMMIT=NO
```

---

### Task 8: Measured renderer comparison and conditional shader decision

**Files:**
- Modify only if mismatch exists:
  - `docs/superpowers/references/YYYY-MM-DD-gate-c-renderer-compositor-blocker.md`
  - potentially a new explicit deviation decision/spec before shader work.
- Potentially create only after approval:
  - `shaders/apple_liquid_glass.frag`

**Interfaces:**
- Consumes:
  - locked source goldens;
  - Flutter-rendered test output;
  - zero-baseline `AppleRendererDeviationRegistry`.
- Produces:
  - either `STANDARD_FLUTTER_COMPOSITION_ACCEPTED=YES`;
  - or an explicit blocker with measured delta.
- Does not silently authorize a shader.

- [ ] **Step 1: Measure comparison output**

For each required golden, capture the test framework's image-difference metric or a deterministic project-owned pixel delta computed from the source fixture and Flutter output.

Store only the measurement/result in test logs; do not replace the source fixture.

- [ ] **Step 2: Branch on evidence**

If every required golden passes:

```text
STANDARD_FLUTTER_COMPOSITION_ACCEPTED=YES
SHADER_REQUIRED=NO
PRODUCTION_ACCEPTED_RENDERER_DEVIATIONS=ZERO
```

Proceed to Task 9.

If any required golden fails after all source-backed standard-composition layers are exhausted, write a blocker document containing:

- family;
- brightness;
- role;
- state;
- source fixture;
- exact recipe source IDs;
- measured delta;
- which renderer semantic cannot reproduce the source.

Record:

```text
STANDARD_FLUTTER_COMPOSITION_ACCEPTED=NO
GATE_C_RENDERER_COMPOSITOR_BLOCKED=YES
SHADER_CREATED=NO
```

Stop execution. A shader requires a new explicit design/deviation approval.

- [ ] **Step 3: Verify no unauthorized shader**

Run:

```bash
if [[ -e shaders/apple_liquid_glass.frag ]]; then
  echo "ERROR: shader exists without approved measured-deviation path"
  exit 1
fi
```

This check is skipped only after a separately committed/approved shader decision explicitly authorizes that file.

---

### Task 9: Full Gate C verification, documentation checkpoint, and explicit-scope commit

**Files:**
- Modify: `PROJECT_ROADMAP.md`
- Modify: `docs/superpowers/plans/2026-08-09-visual-foundation-2a-apple-liquid-glass-implementation-plan.md`
- Modify: this implementation plan to record completion
- Create: `docs/superpowers/checkpoints/2026-08-16-visual-foundation-2a-gate-c-complete-checkpoint.md`
- Stage only the exact Gate C production/test/generator/reference/golden/docs files.

**Interfaces:**
- Produces:
  - Gate C checkpoint;
  - Roadmap status `GATE C COMPLETE — NEXT: GATE D`;
  - one Gate C implementation commit.
- Keeps `Task 2.9` blocked.

- [ ] **Step 1: Run generated/source freshness**

Run:

```bash
python3 tool/generate_apple_liquid_glass_recipes.py \
  --input docs/superpowers/references/generated/apple_ui_kit_reference.json \
  --reference-output docs/superpowers/references/generated/apple_liquid_glass_recipe_reference.json \
  --dart-output lib/app/apple_visual/generated/apple_source_liquid_glass_recipes.g.dart \
  --check

python3 tool/verify_apple_liquid_glass_golden_sources.py \
  --manifest test/goldens/apple/manifest.json

python3 tool/verify_visual_foundation_2a_sources.py
```

Then run all six existing Gate B generator `--check` commands.

Expected:

```text
GATE_C_RECIPE_GENERATOR_FRESH=PASS
GATE_C_GOLDEN_PROVENANCE=PASS
GATE_A_SOURCE_VERIFIER=PASS
GATE_B_GENERATORS_FRESH=PASS
```

- [ ] **Step 2: Run focused Gate C tests**

Run:

```bash
/home/shabin/develop/flutter/bin/flutter test \
  test/app/apple_visual/apple_liquid_glass_recipe_generation_test.dart \
  test/app/apple_visual/apple_liquid_glass_recipe_resolver_test.dart \
  test/app/apple_visual/apple_renderer_deviation_test.dart \
  test/app/apple_visual/apple_liquid_glass_test.dart \
  test/app/apple_visual/apple_low_level_primitives_test.dart
```

Expected: PASS.

- [ ] **Step 3: Run Gate B regression tests**

Run the eight Gate B focused tests:

```bash
/home/shabin/develop/flutter/bin/flutter test \
  test/app/apple_visual/apple_visual_platform_resolver_test.dart \
  test/app/apple_visual/apple_visual_tokens_contract_test.dart \
  test/app/apple_visual/apple_source_reference_mapping_test.dart \
  test/app/apple_visual/apple_semantic_color_mapping_test.dart \
  test/app/apple_visual/apple_typography_mapping_test.dart \
  test/app/apple_visual/apple_material_source_mapping_test.dart \
  test/app/apple_visual/apple_metric_variant_mapping_test.dart \
  test/app/apple_visual/apple_motion_mapping_test.dart
```

Expected: PASS.

- [ ] **Step 4: Run full regression suite**

Run:

```bash
/home/shabin/develop/flutter/bin/flutter test
```

Expected: all tests pass.

- [ ] **Step 5: Run analyzer and Linux build**

Run:

```bash
/home/shabin/develop/flutter/bin/flutter analyze
/home/shabin/develop/flutter/bin/flutter build linux --debug
git diff --check
```

Expected:

```text
FLUTTER_ANALYZE=PASS
LINUX_DEBUG_BUILD=PASS
GIT_DIFF_CHECK=PASS
```

- [ ] **Step 6: Write Gate C checkpoint**

Checkpoint must state:

```text
VISUAL_FOUNDATION_2A_GATE_C=PASS
GATE_C_0_SOURCE_RECIPE=PASS
ROLE_MAPPING_BY_NAME_GUESS=NO
OVER_GLASS_PROVENANCE=LOCKED
SOURCE_GOLDEN_PROVENANCE=PASS
SELF_REFERENCE_GOLDENS=NONE
STANDARD_FLUTTER_COMPOSITION_ACCEPTED=YES
SHADER_REQUIRED=NO
PRODUCTION_ACCEPTED_RENDERER_DEVIATIONS=ZERO
VISIBLE_MATERIAL_FALLBACK=NONE
FULL_TEST_SUITE=PASS
FLUTTER_ANALYZE=PASS
LINUX_DEBUG_BUILD=PASS
GIT_DIFF_CHECK=PASS
TASK_2_9=BLOCKED
GATE_C_COMPLETE=YES
NEXT=Gate D — shared Apple controls / no-fallback enforcement
```

If Task 8 took the blocker path, Task 9 must not run and Gate C must not be marked complete.

- [ ] **Step 7: Update Roadmap and parent plan**

Roadmap:

```text
**Status: IMPLEMENTATION ACTIVE — GATE C COMPLETE — NEXT: GATE D**
```

Retain every existing statement that Task 2.9 remains blocked until the whole Visual Foundation 2.A is complete.

Parent plan must record Gate C completion evidence and point to the checkpoint.

- [ ] **Step 8: Stage explicit allowlist only**

Never use `git add .`.

Stage:

```bash
git add -- \
  PROJECT_ROADMAP.md \
  docs/superpowers/plans/2026-08-09-visual-foundation-2a-apple-liquid-glass-implementation-plan.md \
  docs/superpowers/plans/2026-08-16-visual-foundation-2a-gate-c-liquid-glass-primitives-implementation-plan.md \
  docs/superpowers/checkpoints/2026-08-16-visual-foundation-2a-gate-c-complete-checkpoint.md \
  docs/superpowers/references/generated/apple_liquid_glass_recipe_reference.json \
  lib/app/apple_visual/foundation/apple_visual_state.dart \
  lib/app/apple_visual/foundation/apple_liquid_glass_recipe.dart \
  lib/app/apple_visual/foundation/apple_liquid_glass_recipe_resolver.dart \
  lib/app/apple_visual/foundation/apple_renderer_deviation.dart \
  lib/app/apple_visual/foundation/apple_source_token_mapper.dart \
  lib/app/apple_visual/generated/apple_source_liquid_glass_recipes.g.dart \
  lib/app/apple_visual/widgets \
  test/app/apple_visual/apple_liquid_glass_recipe_generation_test.dart \
  test/app/apple_visual/apple_liquid_glass_recipe_resolver_test.dart \
  test/app/apple_visual/apple_renderer_deviation_test.dart \
  test/app/apple_visual/apple_liquid_glass_test.dart \
  test/app/apple_visual/apple_low_level_primitives_test.dart \
  test/goldens/apple \
  tool/generate_apple_liquid_glass_recipes.py \
  tool/verify_apple_liquid_glass_golden_sources.py
```

Do not stage `shaders/` unless Task 8 has a separately approved shader path.

Verify staged scope and ensure neither IPSW file is staged.

- [ ] **Step 9: Commit Gate C**

Run:

```bash
git diff --cached --check
git commit -m "feat: add source-locked apple liquid glass primitives"
```

- [ ] **Step 10: Post-commit verification**

After commit rerun:

```bash
python3 tool/generate_apple_liquid_glass_recipes.py \
  --input docs/superpowers/references/generated/apple_ui_kit_reference.json \
  --reference-output docs/superpowers/references/generated/apple_liquid_glass_recipe_reference.json \
  --dart-output lib/app/apple_visual/generated/apple_source_liquid_glass_recipes.g.dart \
  --check

python3 tool/verify_apple_liquid_glass_golden_sources.py \
  --manifest test/goldens/apple/manifest.json

/home/shabin/develop/flutter/bin/flutter test \
  test/app/apple_visual/apple_liquid_glass_recipe_generation_test.dart \
  test/app/apple_visual/apple_liquid_glass_recipe_resolver_test.dart \
  test/app/apple_visual/apple_renderer_deviation_test.dart \
  test/app/apple_visual/apple_liquid_glass_test.dart \
  test/app/apple_visual/apple_low_level_primitives_test.dart

/home/shabin/develop/flutter/bin/flutter analyze
/home/shabin/develop/flutter/bin/flutter build linux --debug
git diff --check
```

Expected final result:

```text
VISUAL_FOUNDATION_2A_GATE_C=PASS
GATE_C_COMPLETE=YES
TASK_2_9=BLOCKED_UNTIL_VISUAL_FOUNDATION_COMPLETE
NEXT=Gate D — shared Apple controls / no-fallback enforcement
```

## Plan Self-Review Result

### Spec coverage

- Source-recipe completion before renderer: Tasks 1–2.
- Provenance-backed role mapping and special `overGlassControl` handling: Task 1.
- No guessed defaults / deterministic unresolved behavior: Tasks 1–3.
- Zero accepted production deviations: Task 3.
- Source-derived, non-self-referential goldens: Task 4.
- Standard Flutter composition first: Tasks 5–6.
- No preemptive shader: Tasks 6 and 8.
- Low-level primitives: Task 7.
- Measured mismatch before any renderer deviation/shader path: Task 8.
- Full verification, checkpoint, Roadmap transition, Task 2.9 remains blocked: Task 9.

### Type consistency

- `AppleGlassRole` is defined once in Task 2 and consumed by Tasks 5–7.
- `AppleControlState` is defined once in Task 2 with the minimal `idle` state and is consumed by the resolver and renderer.
- `AppleLiquidGlassRecipe` and `AppleLiquidGlassProvenance` are defined in Task 2 and are the only renderer source-value inputs.
- `AppleRendererDeviationRegistry.accepted` remains immutable and empty by default.
- `AppleLiquidGlass` receives `AppleVisualThemeData` explicitly and never reads visible Material theme defaults.

### Scope

Gate C contains one coherent subsystem: source-backed low-level Apple rendering primitives. Dashboard/shell migration, feature migration, OriginalTheme retirement, Task 2.9, and later shared-control families remain outside this plan.
