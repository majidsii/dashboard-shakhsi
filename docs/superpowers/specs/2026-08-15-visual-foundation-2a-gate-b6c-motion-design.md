# Visual Foundation 2.A — Gate B.6C Motion Design

**Date:** 2026-08-15  
**Status:** APPROVED DESIGN — IMPLEMENTATION NOT STARTED  
**Scope:** Gate B.6C only  
**Decision:** `docs/superpowers/decisions/2026-08-15-b6c-swiftui-motion-runtime-reference-deviation.md`

## 1. Goal

Resolve the Visual Foundation motion token boundary using exact documented SwiftUI spring defaults while preserving a truthful distinction between:

1. official SwiftUI runtime reference values; and
2. undocumented internal Liquid Glass component motion.

No internal Liquid Glass timing is guessed.

## 2. Runtime Motion Presets

Gate B.6C SHALL expose exactly two initial source-referenced spring presets.

### `defaultSpring`

Exact reference values:

- `responseSeconds = 0.55`
- `dampingFraction = 1.0`
- `blendDurationSeconds = 0.0`

Reference semantics: Apple `Animation.default`.

### `interactiveSpring`

Exact reference values:

- `responseSeconds = 0.15`
- `dampingFraction = 0.86`
- `blendDurationSeconds = 0.25`

Reference semantics: Apple `Animation.interactiveSpring(response:dampingFraction:blendDuration:)`.

No additional duration, easing, stiffness, mass, velocity, bounce, bezier, or interpolation constants may be introduced in Gate B.6C without a source and a new approved contract.

## 3. Public Foundation Model

The intended foundation boundary is:

### `AppleMotionPreset`

```text
defaultSpring
interactiveSpring
```

### `AppleSpringMotion`

Each spring record SHALL contain:

- `preset`
- `responseSeconds`
- `dampingFraction`
- `blendDurationSeconds`
- provenance describing the official Apple API reference
- `isExactInternalLiquidGlassMotion = false`

### `AppleMotionAccessibilityPolicy`

The foundation SHALL explicitly represent at least:

```text
standard
reduceMotion
```

This is a semantic policy boundary. Gate B.6C does not need to implement platform accessibility listeners if those belong to a later host/renderer gate.

### `AppleMotionTokens`

A resolved token set SHALL provide:

- `defaultSpring`
- `interactiveSpring`
- explicit accessibility policy semantics
- provenance/claim metadata

`AppleMotionTokens.empty` SHALL remain available as the unresolved state established by Gate B.2.

## 4. Provenance Contract

The numeric values are not extracted from the Sketch reference.

They come from the approved official SwiftUI runtime deviation.

Every resolved motion preset SHALL preserve provenance sufficient to distinguish this source class from Sketch-derived values.

The foundation must make these truths machine-visible:

```text
officialSwiftUIRuntimeReference = true
exactInternalLiquidGlassMotion = false
```

No consumer should need to infer the deviation from a comment.

## 5. Platform Contract

The two approved spring presets are shared Apple-runtime references.

Visual platform-family routing remains:

- Android -> iOS 27 family
- iOS -> iOS 27 family
- Windows -> macOS 27 family
- Linux -> macOS 27 family
- macOS -> macOS 27 family

Gate B.6C does not create separate guessed numeric spring presets per platform family.

If a later renderer proves unable to reproduce the contract, that is a new renderer/compositor blocker and must not be silently compensated by changing the source values.

## 6. Accessibility / Reduce Motion

Apple guidance establishes that motion can adapt to accessibility settings and Liquid Glass can modify effects when Reduce Motion is enabled.

Gate B.6C SHALL therefore model reduced-motion behavior explicitly.

The foundation-level reduced-motion policy SHALL mean:

- consumers must be able to request a reduced-motion behavior;
- full spring animation must not be mandatory under that policy;
- no new guessed animation timing values are introduced merely to implement reduced motion.

The exact rendering strategy for `reduceMotion` must be decided where motion is consumed. Acceptable later strategies may include removing nonessential motion or using an immediate state change, but Gate B.6C SHALL NOT invent a replacement duration.

## 7. Theme Resolution Boundary

After B.6C becomes GREEN, `AppleMotionTokens` may become resolved.

`AppleVisualThemeData.isResolved` may become true only when:

- colors are resolved;
- typography is resolved;
- metrics are resolved;
- materials are resolved;
- motion is resolved;
- every other existing B.2 required group is resolved.

The B.6C implementation must not bypass this aggregate contract.

## 8. TDD Contract

Implementation SHALL follow RED -> GREEN.

The RED contract must prove the absence of the approved API before implementation.

The GREEN contract must prove:

1. `defaultSpring` exact values are `0.55 / 1.0 / 0.0`;
2. `interactiveSpring` exact values are `0.15 / 0.86 / 0.25`;
3. provenance identifies official SwiftUI runtime reference;
4. `exactInternalLiquidGlassMotion` is false;
5. both iOS 27 and macOS 27 visual families resolve to the same approved numeric spring reference values;
6. Reduce Motion policy exists explicitly;
7. no additional guessed timing/easing/spring constants are introduced;
8. B.1 through B.6B regressions remain GREEN.

## 9. No-Guessing Guard

Gate B.6C SHALL reject:

- arbitrary `Duration(milliseconds: ...)` values in the semantic motion source mapper;
- cubic-bezier constants with no approved source;
- manually tuned damping/stiffness values beyond the approved presets;
- video-derived timing;
- platform-specific “close enough” replacements.

Any additional motion constant requires a source-backed or separately approved deviation.

## 10. Non-Goals

Gate B.6C does not:

- implement animation widgets;
- implement Liquid Glass rendering;
- attach MediaQuery/platform Reduce Motion listeners;
- migrate dashboard controls;
- start Gate C;
- retire OriginalTheme;
- start Task 2.9;
- claim exact internal Liquid Glass motion.

## 11. Success Boundary

B.6C is GREEN only after:

- RED has failed for the missing approved motion API;
- minimal production implementation passes RED;
- exact documented values are verified;
- claim/provenance metadata is verified;
- Reduce Motion policy boundary is verified;
- no guessed motion values are present;
- B.1-B.6B focused regressions pass;
- `git diff --check` passes;
- final theme-resolution behavior is verified rather than assumed.

Gate B completion remains a separate final verification decision after B.6C GREEN.

## 12. Approved Fidelity Statement

```text
MOTION_SOURCE=OFFICIAL_SWIFTUI_RUNTIME_REFERENCE
DEFAULT_SPRING=0.55/1.0/0.0
INTERACTIVE_SPRING=0.15/0.86/0.25
OFFICIAL_SWIFTUI_RUNTIME_REFERENCE=YES
EXACT_INTERNAL_LIQUID_GLASS_MOTION=NO
REDUCE_MOTION_POLICY=REQUIRED
GUESSED_MOTION_VALUES=NONE
```
