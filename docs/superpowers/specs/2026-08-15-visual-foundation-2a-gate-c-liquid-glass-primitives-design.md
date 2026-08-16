# Visual Foundation 2.A — Gate C Liquid Glass Primitives Design

**Date:** 2026-08-15
**Status:** APPROVED DESIGN — IMPLEMENTATION PLAN NOT YET WRITTEN
**Boundary:** Visual Foundation 2.A — Gate C
**Previous checkpoint:** Gate B complete at `d1e101d6635f4590d182d4f2560209674629788c`
**Next workflow step:** write a dedicated Gate C implementation plan after user review of this spec.

## 1. Goal

Gate C introduces the lowest-level Apple visual rendering primitives required by the
approved Visual Foundation 2.A migration without guessing any visual value that is not
source-backed.

The primary primitive is source-locked Liquid Glass rendering. Gate C also establishes
the low-level Apple surface, pressable, text, and separator boundaries that later gates
will consume.

Gate C does **not** migrate dashboard features yet. It creates the rendering foundation
that later controls and screens will use.

## 2. Frozen constraints

The following remain mandatory:

- Apple iOS 27 and macOS 27 Sketch/UI Kit sources are the visual Source of Truth wherever
  values are measurable.
- Android and all compact/mobile rendering use the iOS 27 visual family.
- Windows, Linux, and macOS desktop rendering use the macOS 27 visual family.
- Material, Fluent, Windows-native, Linux-native, and unrelated platform-native visible
  fallbacks are not approved.
- No silent approximation is allowed.
- No Apple font binaries may be added.
- Project-owned vector glyphs must not be claimed to be exact SF Symbols.
- Motion continues to use the separately approved SwiftUI runtime-reference deviation.
- Exact internal Liquid Glass motion is not claimed.
- Task 2.9 remains blocked until the whole Visual Foundation 2.A is complete.

## 3. Why Gate C begins with source-recipe completion

Gate B intentionally exposed the extracted material source records without inventing a
renderer recipe.

Current source-backed material records include structured Liquid Glass fields such as:

- blur radius;
- saturation;
- brightness;
- distortion;
- depth;
- layering type;
- other extracted custom-glass metadata.

The Gate C implementation plan requires more than blur. The renderer contract includes,
where represented by the source:

- clipped backdrop treatment;
- source blur;
- source fill or tint;
- source gradients;
- source border or rim;
- source shadow;
- source highlight;
- source state overlays.

Therefore Gate C must not begin by mapping a widget directly to a convenient blur value
or by guessing a Flutter decoration.

Before the renderer is implemented, Gate C must complete a deterministic,
provenance-preserving **render recipe** for each required role and supported state.

## 4. Required public roles

The public Liquid Glass role contract is:

```dart
enum AppleGlassRole {
  smallControl,
  tintedSmallControl,
  mediumSurface,
  largeSurface,
  overGlassControl,
}
```

The renderer boundary is:

```dart
final class AppleLiquidGlass extends StatelessWidget {
  const AppleLiquidGlass({
    required this.role,
    required this.child,
    this.state = AppleControlState.idle,
    super.key,
  });
}
```

These role names are semantic application contracts.

They are **not** permission to map by source-name similarity alone.

For example, `smallControl` may correspond to a `Regular - Small` source style only
after exact provenance and usage evidence proves that mapping. Likewise,
`overGlassControl` must be established from source usage/layer provenance and must not be
invented from naming intuition.

## 5. Gate C.0 — source recipe completion

Gate C begins with a source-audit sub-boundary named **Gate C.0**.

For every supported combination of:

- visual family;
- brightness/appearance;
- `AppleGlassRole`;
- supported `AppleControlState`;

the project must resolve a deterministic recipe whose values come only from locked
source data or an explicitly approved deviation document.

A recipe must preserve provenance for every consumed visual field.

At minimum the recipe model must be capable of representing source-backed values for:

- material/source style identity;
- blur/custom-glass values;
- geometry/radius when source-backed by the relevant usage;
- fill/tint;
- gradients;
- border/rim;
- shadow;
- highlight;
- state overlay/treatment.

If a category is not present for a given source recipe, it is represented as absent.
Absence does not authorize a guessed default.

### 5.1 Role mapping evidence

A role mapping is accepted only when it can point to concrete source evidence such as:

- exact layer-style identity;
- exact layer/component usage;
- exact appearance/state usage;
- exact extracted geometry or style reference;
- source ID and source name.

Name similarity alone is insufficient.

### 5.2 Over-glass control

`overGlassControl` receives special treatment because its semantic meaning cannot be
safely inferred from `Regular - Small`.

The source contains dedicated Liquid Glass usage over light/dark backgrounds. Gate C.0
must use those source usage layers or equivalent explicit provenance to establish the
correct recipe.

If the source does not contain enough information for an exact mapping, Gate C must stop
with an explicit blocker rather than substitute an approximation.

## 6. Recipe architecture

Gate C should introduce a narrow source-to-render boundary rather than let widgets scan
raw style lists.

The design requires a resolver with a conceptual shape equivalent to:

```dart
AppleLiquidGlassRecipe resolveLiquidGlassRecipe({
  required AppleVisualThemeData theme,
  required AppleGlassRole role,
  required AppleControlState state,
});
```

The exact implementation names may be refined in the implementation plan, but the
architecture is fixed:

1. generated/source-backed data remains the bottom layer;
2. one deterministic resolver maps source evidence to semantic glass roles;
3. the renderer consumes only the resolved recipe;
4. feature widgets never inspect raw generated style tables directly.

The recipe must retain provenance rather than flatten it away.

## 7. Rendering strategy

The first renderer implementation must use standard Flutter composition **only if**
controlled source comparison shows that Flutter composition can reproduce the source
within the accepted fidelity boundary.

The expected composition may include, only when source-backed:

- `ClipPath` / rounded clipping;
- `BackdropFilter`;
- layered fills;
- gradients;
- borders/rims;
- shadows;
- highlights;
- state overlays.

No source-independent constants such as an arbitrary `blurSigma = 28` are permitted.

### 7.1 Shader rule

A fragment shader is an implementation detail, not an architectural default.

`shaders/apple_liquid_glass.frag` may be added only after:

1. the source recipe has been completed;
2. standard Flutter composition has been implemented faithfully;
3. controlled comparison proves a material mismatch that cannot be removed using
   source-backed Flutter composition;
4. the mismatch and measured delta are recorded.

No shader may be introduced preemptively.

## 8. Renderer deviation reporting

Gate C introduces a test-visible renderer deviation structure:

```dart
final class AppleRendererDeviation {
  final AppleVisualFamily family;
  final String component;
  final String platform;
  final String reason;
  final double? measuredDelta;
}
```

Production default is **zero accepted deviations**.

A deviation record is not a shortcut to accept a weak renderer. It exists so a genuine
renderer/compositor limitation can be made explicit, measured, and separately approved.

Gate C cannot silently add accepted deviations.

## 9. Golden reference policy

Gate C golden tests are source-comparison tests, not self-approval tests.

Reference goldens must be exported or deterministically derived from the locked Apple
source at controlled dimensions.

A golden generated from the app's own current renderer cannot be used as the reference
for approving that same renderer.

At minimum Gate C must cover:

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

Every golden fixture must define:

- fixed render size;
- fixed device pixel ratio;
- controlled background;
- exact family;
- exact brightness;
- exact role;
- exact state;
- source provenance for the reference image.

## 10. Control state contract

Gate C may add the low-level `AppleControlState` contract required by the approved public
renderer interface.

State handling must remain semantic and source-backed.

No hover, pressed, selected, inactive, disabled, focus, highlight, or similar visual
delta may be invented because Flutter exposes such a state.

Only states required by the current plan and supported by source evidence are rendered.

If the renderer receives a state for which the source recipe is unresolved, the
implementation must fail deterministically in debug/test rather than silently use idle
styling.

## 11. Low-level companion primitives

The Gate C file boundary remains:

- `apple_liquid_glass.dart`
- `apple_surface.dart`
- `apple_pressable.dart`
- `apple_text.dart`
- `apple_separator.dart`

Their responsibilities are intentionally narrow.

### 11.1 `AppleLiquidGlass`

Owns Liquid Glass visual rendering from an already resolved source recipe.

It does not own feature-specific layout or business state.

### 11.2 `AppleSurface`

Provides a non-Material Apple surface boundary for later controls and screens.

It may compose Liquid Glass where the caller selects a glass role, but it must not
create hidden ad-hoc glass math.

### 11.3 `ApplePressable`

Provides interaction plumbing and semantic control state without inheriting visible
Material button styling.

It delegates visible treatment to Apple visual primitives.

### 11.4 `AppleText`

Provides the Apple visual typography boundary using Gate B typography tokens and the
approved Vazirmatn runtime deviation where required.

It must not use Material `TextTheme` as a visible styling source.

### 11.5 `AppleSeparator`

Provides source-backed separator rendering only from Apple visual tokens/source values.

It must not invent a generic Material divider appearance.

## 12. Error and unresolved-source behavior

The no-guessing rule applies at runtime boundaries too.

An unresolved theme, unresolved recipe, missing required source mapping, or unsupported
semantic state must not silently degrade to:

- generic blur;
- transparent card;
- Material styling;
- default Flutter colors;
- generic `Divider`;
- generic `InkWell`;
- guessed radius;
- guessed opacity.

Tests must be able to observe deterministic failure for unresolved contracts.

## 13. TDD order

The Gate C implementation plan must preserve this order:

1. **Gate C.0 RED**
   - tests prove the semantic role → source recipe mappings do not yet exist;
   - tests lock the exact required source provenance and recipe fields.

2. **Gate C.0 GREEN**
   - implement the deterministic resolver/generator changes required to expose the
     complete source recipe;
   - no renderer yet.

3. **Renderer RED**
   - source-value consumption contract tests;
   - light/dark, iOS/macOS golden tests from locked source exports.

4. **Renderer GREEN**
   - minimum standard Flutter implementation that consumes only the resolved recipe.

5. **Deviation/shader decision**
   - compare output to source;
   - only if a measured renderer limitation remains may a shader design be introduced.

6. **Companion primitive tests/implementation**
   - `AppleSurface`;
   - `ApplePressable`;
   - `AppleText`;
   - `AppleSeparator`.

7. **Gate C verification**
   - focused Gate C tests;
   - generator/source freshness;
   - `flutter analyze`;
   - `git diff --check`;
   - relevant Linux debug build verification when renderer assets/shaders are involved.

## 14. Files expected from Gate C

Expected production boundary:

```text
lib/app/apple_visual/widgets/apple_liquid_glass.dart
lib/app/apple_visual/widgets/apple_surface.dart
lib/app/apple_visual/widgets/apple_pressable.dart
lib/app/apple_visual/widgets/apple_text.dart
lib/app/apple_visual/widgets/apple_separator.dart
```

Gate C.0 may additionally require narrowly scoped foundation/generated files for the
source-recipe resolver and generated recipe data.

Expected verification boundary:

```text
test/app/apple_visual/apple_liquid_glass_test.dart
test/goldens/apple/...
```

Additional narrowly scoped recipe-mapping tests are allowed and expected if needed.

Potential renderer-only asset:

```text
shaders/apple_liquid_glass.frag
```

This shader file remains forbidden until the measured-mismatch rule in this spec is met.

## 15. Explicit non-goals

Gate C does not:

- migrate dashboard shell;
- migrate feature panels;
- implement Task 2.9;
- retire OriginalTheme;
- add final shared Apple buttons/fields/navigation from later gates;
- change Riverpod, Drift, routing, notification, localization, or domain behavior;
- invent source-independent visual constants;
- claim exact internal Liquid Glass motion;
- introduce a shader without measured evidence;
- accept app-generated self-reference goldens.

## 16. Acceptance criteria

Gate C is acceptable only when all of the following are true:

1. every required semantic glass role has deterministic source provenance;
2. role mappings are evidence-backed, not name-guess mappings;
3. every renderer value is source-backed or covered by an existing explicit approved
   deviation;
4. missing source data remains missing rather than becoming a guessed default;
5. source-derived reference goldens exist for the minimum required matrix;
6. the renderer consumes only resolved recipes;
7. production renderer deviations remain zero unless a new deviation is explicitly
   approved;
8. no Material/Fluent/native visible fallback is used;
9. shader use, if any, is justified by measured mismatch after standard composition;
10. focused tests, analyze, source/generator freshness, and diff checks pass;
11. Task 2.9 remains blocked;
12. the next roadmap boundary remains Gate D after Gate C is checkpointed.

## 17. Approved design decision

The approved approach is:

**Approach A — source-recipe completion before renderer implementation.**

Gate C must complete and lock the semantic role → source recipe boundary before
implementing `AppleLiquidGlass`.

This decision prevents the renderer from converting incomplete source records into
silent visual guesses and preserves the exact-source contract established by Gate A and
Gate B.
