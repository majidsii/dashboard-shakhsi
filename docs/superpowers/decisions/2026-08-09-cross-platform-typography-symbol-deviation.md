# Visual Foundation 2.A — Approved Cross-Platform Typography and Symbol Deviations

Date: 2026-08-09
Status: **APPROVED**
Source extraction commit: `5783cefbcf15f4a003b7b2a3d112bf1c727f313b`

## Scope

The user explicitly approved exactly two non-Apple visual deviations:

1. Typography glyph artwork.
2. Symbol/icon glyph artwork.

No other deviation is approved.

## Typography

- iOS/macOS: use the native Apple system typography when available.
- Android/Windows/Linux Persian/Arabic UI: use **Vazirmatn**.
- Keep Apple-source semantic roles, nominal sizes, weight mapping, line-height
  intent, alignment, spacing, color and opacity as the calibration target.
- Do not claim Vazirmatn glyph shapes are exact San Francisco glyphs.
- Do not add restricted Apple font binaries to the public repository.

## Symbols / icons

- Do not use Material Icons or Cupertino Icons as final visible migrated icons.
- Create only the small set of icons the app actually needs.
- Icons must be project-owned vectors calibrated to the Apple references for:
  bounding box, optical size, stroke weight, corners, joins/caps, centering,
  baseline/alignment and filled/outlined state.
- Do not claim the project-owned artwork is an exact copy of SF Symbols.

## Liquid Glass relationship

The icon glyph itself is not made blurry/glassy merely for style.
Liquid Glass belongs to the containing control/surface and its state treatment:
material, tint, rim, highlight, shadow, hover, pressed, selected, disabled and
focus where applicable.

## Still source-locked

No deviation is approved for:

- Liquid Glass recipes
- materials
- colors
- opacity
- geometry
- spacing
- radii
- borders/rims
- shadows/highlights
- control dimensions
- interaction states
- light/dark variants
- iOS 27 mobile mapping
- macOS 27 desktop mapping
- application/domain behavior

If Flutter rendering later cannot reproduce a source-defined compositor effect,
that is a new blocker and requires a separate measured decision.

## Gate result

Gate A is complete after this decision.

Next gate:
**Gate B — Platform Family, Source Tokens, Typography and Metrics**

Task 2.9 remains blocked until Visual Foundation 2.A is fully complete.
