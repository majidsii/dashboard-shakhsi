# Visual Foundation 2.A — Gate B Complete Checkpoint

**Date:** 2026-08-15
**Branch:** `feat/v2-complete-dashboard`
**Status:** `GATE B COMPLETE — NEXT: GATE C`
**Task 2.9:** remains blocked until the complete Visual Foundation 2.A is implemented and verified.

## Scope completed

Gate B source-token foundation is complete:

1. **B.1 Platform family**
   - Android + iOS compact/mobile → `iOS 27`
   - Windows + Linux + macOS desktop → `macOS 27`
   - Fuchsia remains the exhaustive non-shipping fallback only.

2. **B.2 Token/theme boundary**
   - token groups expose unresolved/resolved state;
   - aggregate `AppleVisualThemeData.isResolved` requires colors, typography,
     metrics, materials, and motion all to be resolved.

3. **B.3 Source reference**
   - deterministic generated Apple source reference;
   - source hashes/provenance remain locked to the extracted UI Kit inputs.

4. **B.4 Semantic colors**
   - source-backed iOS/macOS light/dark mappings for the approved semantic roles.

5. **B.5 Typography**
   - source-backed `body`, `headline`, and `title1` role mappings;
   - resolved `AppleTypographyTokens` group added after the aggregate-boundary
     gap was discovered during B.6C Task 4;
   - group mapper composes existing role mappings and introduces no duplicate
     manual typography values;
   - approved non-Apple Persian/Arabic runtime deviation remains Vazirmatn;
   - no Apple font binaries are shipped.

6. **B.6A Materials**
   - source-backed structured custom-glass material values;
   - extracted `isCustomGlass` integer representation is handled without guessing.

7. **B.6B Variant-aware metrics**
   - source variants are preserved rather than collapsed to a guessed canonical role;
   - explicit size distinctions remain distinct;
   - generic `Switch` false-positive classification is excluded.

8. **B.6C Motion**
   - source is the approved **official SwiftUI runtime reference**;
   - default spring: response `0.55`, damping fraction `1.0`, blend duration `0.0`;
   - interactive spring: response `0.15`, damping fraction `0.86`,
     blend duration `0.25`;
   - Reduce Motion policy is explicit and required;
   - the project does **not** claim exact internal Liquid Glass motion.

## TDD / repair evidence

The discovered B.5 aggregate typography gap was handled with RED/GREEN:

- RED proved `AppleTypographyTokens` could not resolve as a group and
  `AppleSourceTokenMapper.typography(...)` was missing.
- GREEN added only the resolved token-group boundary and composed the existing
  `typographyRole(...)` source mappings.
- No new font measurements, weights, PostScript names, or source values were guessed.

The Task 5 lint repair was behavior-preserving:

- relative test imports were moved to package imports;
- directive ordering was corrected;
- token constructors adopted Dart 3.12 initializing-formal syntax;
- the private named-parameter call-site labels were corrected after a focused
  compile failure exposed the first automatic rewrite mistake;
- semantic values and generated source payloads were unchanged.

## Fresh Gate B verification evidence

The final Task 5 run passed:

- `SOURCE_GENERATORS_FRESH=PASS`
- `SOURCE_GENERATORS_DETERMINISTIC=PASS`
- `GATE_A_VERIFIER=PASS`
- `B_1_THROUGH_B_6C_FOCUSED_TESTS=PASS`
- `FULL_TEST_SUITE=PASS`
- `FLUTTER_ANALYZE=PASS`
- `LINUX_DEBUG_BUILD=PASS`
- `GIT_DIFF_CHECK=PASS`

Motion claim boundary:

- `MOTION_SOURCE=OFFICIAL_SWIFTUI_RUNTIME_REFERENCE`
- `OFFICIAL_SWIFTUI_RUNTIME_REFERENCE=YES`
- `EXACT_INTERNAL_LIQUID_GLASS_MOTION=NO`
- `REDUCE_MOTION_POLICY=REQUIRED`
- `GUESSED_MOTION_VALUES=NONE`

Typography claim boundary:

- `GUESSED_TYPOGRAPHY_VALUES=NONE`
- approved Vazirmatn deviation retained;
- project-owned symbols/glyph artwork are not claimed to be exact SF Symbols.

## Files / architecture recorded at this checkpoint

Foundation lives under:

- `lib/app/apple_visual/foundation/`
- `lib/app/apple_visual/generated/`

Verification and generation live under:

- `test/app/apple_visual/`
- `tool/generate_apple_source_*.py`
- `tool/verify_visual_foundation_2a_sources.py`

Motion reference manifest:

- `docs/superpowers/references/apple_swiftui_motion_runtime_reference.json`

## Guardrails retained

- Apple Sketch/UI Kit sources remain the visual Source of Truth wherever measurable.
- No Material, Fluent, Windows-native, or Linux-native final visual fallback is approved.
- No silent approximation is allowed.
- No Apple font binaries are added.
- Exact SF Symbols are not claimed for project-owned vectors.
- Exact internal Liquid Glass motion is not claimed.
- Task 2.9 remains blocked until all Visual Foundation 2.A gates are complete.

## Next action

**Gate C — Liquid Glass primitives**

Gate C must consume the resolved Gate B source-backed token foundation and continue
under the same no-guessing, no-fallback, source-provenance, TDD, and verification rules.
